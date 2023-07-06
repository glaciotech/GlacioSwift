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
    
    @Published var newestBlockInfo: DisplayableBlockInfo = .empty
    
    public init(node: Node) {
        self.node = node
        
        func updateBlockInfo(chainId: String) {
            Task {
                let newestBlockInfo = (try? await lastBlockInfo(chainId: chainId)) ?? .empty
                await MainActor.run {
                    self.newestBlockInfo = newestBlockInfo
                }
            }
        }
        
        self.node.eventCenter.register(eventForType: NewBlockAdded.self, object: self) { [weak self] update in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
                updateBlockInfo(chainId: update.chainId)
            }
        }

        self.node.eventCenter.register(eventForType: PeerNodeRegistrationChange.self, object: self) { [weak self] register in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }

        self.node.eventCenter.register(eventForType: NewBlockMined.self, object: self) { [weak self] update in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
                updateBlockInfo(chainId: update.chainId)
            }
        }

        node.eventCenter.register(eventForType: ChainSynced.self, object: self) { [weak self] result in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
                updateBlockInfo(chainId: result.chainId)
            }
        }
    }
    
    var myPort: String {
        guard let netNode = self.node as? NetworkedNode else {
            return "N/A - local node"
        }
        return "\(String(describing: netNode.port))"
    }

    var peerNodes: [(String, String)] {
        get async {
            await node.peers.map({ ("\($0.0.endpoint.description) \($0.0.id)", "\($0.1)") })
        }
    }
    
    var chains: [String] {
        node.chains.keys.map({ $0 })
    }
 
    func forceSync(chains: [String]) {
        chains.forEach({ try? node.sync(full: true, chainId: $0) })
    }
    
    func chainStatus(chain: String) -> String {
        "\(node.chains[chain]?.status.description ?? "-")"
    }
    
    private func lastBlockInfo(chainId: String) async throws -> DisplayableBlockInfo {
        let blockchain = try node.getChainManager(chainId: chainId).blockchain
        let info = await blockchain.lastBlockInfo ?? .noInfo
        return DisplayableBlockInfo(hash: info.hash, index: info.index)
    }
    
    func refreshChainInfo(chainId: String) {
        Task {
            let newestBlockInfo = (try? await lastBlockInfo(chainId: chainId)) ?? .empty
            await MainActor.run {
                self.newestBlockInfo = newestBlockInfo
            }
        }
    }
}
