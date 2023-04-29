//
//  DebugModel.swift
//  Glacio
//
//  Created by Peter Liddle on 3/3/23.
//

import Foundation
import GlacioCore

public class DebugModel: ObservableObject {
    
    var node: Node
    
    @Published var newestBlock: (Int, String) = (-1, "")
    
    public init(node: Node) {
        self.node = node
        
        self.node.eventCenter.register(eventForType: NewBlockAdded.self, object: self) { [weak self] update in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }

        self.node.eventCenter.register(eventForType: DirectRegister.self, object: self) { [weak self] register in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }

        self.node.eventCenter.register(eventForType: NewBlockMined.self, object: self) { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }

        node.eventCenter.register(eventForType: ChainSynced.self, object: self) { [weak self] result in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
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
        node.peers.map({ ($0.0.absoluteString, "\($0.1)") })
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
    
    func lastBlockInfo(chainId: String) -> (Int, String) {
        return (try? node.getChainManager(chainId: chainId).blockchain.lastBlockInfo) ?? (-1, "")
    }
}
