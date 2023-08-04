//
//  DebugModel.swift
//  Glacio
//
//  Created by Peter Liddle on 3/3/23.
//

import Foundation
import GlacioCore

public class DebugModel: ObservableObject {
    
    struct DisplayableBlockInfo {
        var hash: String
        var index: Int
        var hashFirst4: String { String(hash.prefix(4)) }
        var hashLast8: String { String(hash.suffix(8)) }
        
        static let empty = DisplayableBlockInfo(hash: "XXX", index: -999)
    }
    
    var node: Node
    
    @Published var newestBlockInfo: [String: DisplayableBlockInfo] = [:]
    @Published var peerNodes: [(String, String)] = []
    
    @Published var chains: [String: String] = [:]
    
    public init(node: Node) {
        self.node = node
        _ = registerEvents
        
        Task {
            await self.updateData()
        }
    }

    @MainActor
    @Sendable private func updateBlockInfo(chainId: String) async {
        let newestBlockInfo = (try? await lastBlockInfo(chainId: chainId)) ?? .empty
        self.newestBlockInfo[chainId] = newestBlockInfo
    }
    
    lazy var registerEvents = {
        
        let eventCenter = self.node.eventCenter
        
        let taskA = Task {
            for try await event in eventCenter.stream(for: Event.NewBlockAdded.self) {
                await self.updateBlockInfo(chainId: event.chainId)
            }
        }
         
        let taskB = Task {
            for try await _ in eventCenter.stream(for: Event.PeerNodeRegistrationChange.self) {
                await self.updatePeerNodesDisplay()
            }
        }
        
        let taskC = Task {
            for try await event in eventCenter.stream(for: Event.ChainSynced.self) {
                await self.updateBlockInfo(chainId: event.chainId)
                objectWillChange.send()
            }
        }
        
//        await (taskA, taskB, taskC)
        print("Never here")
    }()
    
    @MainActor
    public func updateData() {
        Task {
            await updatePeerNodesDisplay()
            
            for chainId in node.chains.keys {
                chains[chainId] = chainStatus(chain: chainId)
            }
        }
    }
    
    @MainActor
    private func updatePeerNodesDisplay() async {
        self.peerNodes = await node.peers.map({ ("\($0.0.endpoint.description) \($0.0.id)", "\($0.1)") })
    }
    
    @MainActor
    var nodeId: String {
        guard let netNode = self.node as? NetworkedNode else {
            return "N/A - local node"
        }
        return netNode.id.uuidString
    }
    
    @MainActor
    var myPort: String {
        guard let netNode = self.node as? NetworkedNode else {
            return "N/A - local node"
        }
        return "\(String(describing: netNode.port))"
    }
    
    @MainActor
    func chainStatus(chain: String) -> String {
        return "\(node.chains[chain]?.status.description ?? "-")"
    }
    
    private func lastBlockInfo(chainId: String) async throws -> DisplayableBlockInfo {
        let blockchain = try node.getChainManager(chainId: chainId).blockchain
        let info = await blockchain.lastBlockInfo ?? .noInfo
        return DisplayableBlockInfo(hash: info.hash, index: info.index)
    }
    
    @MainActor
    func refreshChainInfo(chainId: String) async {
        let newestBlockInfo = (try? await lastBlockInfo(chainId: chainId)) ?? .empty
        self.newestBlockInfo[chainId] = newestBlockInfo
    }
}
