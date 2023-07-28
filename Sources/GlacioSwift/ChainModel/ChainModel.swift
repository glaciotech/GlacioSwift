//
//  ChainModel.swift
//  Glacio
//
//  Created by Peter Liddle on 3/5/23.
//

import Foundation
import GlacioCore

public class ChainModel: ObservableObject {
    
    @Published public var chainStatus: ChainSyncStatus = .initializing
    
    @Published public var synced: Bool = false
    
    var glacioCoordinator: GlacioRealmCoordinator
    var nodeManager: NodeManager
    var node: GlacioCore.Node {
        return nodeManager.node
    }
    
    public init(glacioCoordinator: GlacioRealmCoordinator, nodeManager: NodeManager) {
        self.glacioCoordinator = glacioCoordinator
        self.nodeManager = nodeManager
        registerChainStatusObserver()
    }
    
    internal func registerChainStatusObserver() {
        
        node.eventCenter.register(eventForType: ChainStatusUpdated.self, object: self) { eventUpdate in
            DispatchQueue.main.async {
                self.chainStatus = eventUpdate.status
            
                if case ChainSyncStatus.synced(_) = eventUpdate.status {
                    self.synced = true
                }
                else {
                    self.synced = false
                }
            }
        }
    }
    
    @MainActor
    public func reloadData() {
        Task {
            await glacioCoordinator.rebuildDBFromChain()
            objectWillChange.send()
        }
    }
}
