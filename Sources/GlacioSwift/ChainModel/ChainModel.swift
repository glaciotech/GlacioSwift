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
    
    let statusUpdateStream: AsyncThrowingStream<Event.ChainStatusUpdated, Error>
    
    var node: GlacioCore.Node {
        return nodeManager.node
    }
    
    @Published public var chainId: String
    
    public init(glacioCoordinator: GlacioRealmCoordinator, nodeManager: NodeManager) {
        self.chainId = glacioCoordinator.chainId
        self.glacioCoordinator = glacioCoordinator
        self.nodeManager = nodeManager
        
        self.statusUpdateStream = nodeManager.node.eventCenter.stream(for: Event.ChainStatusUpdated.self)
        
        handleStatusUpdates()
    }
    
    internal func handleStatusUpdates() {
        Task {
            for try await statusUpdate in statusUpdateStream.filter({ $0.chainId == self.chainId }) {
                await self.updateStatus(statusUpdate.status)
            }
        }
    }
    
    @MainActor
    public func updateStatus(_ status: ChainSyncStatus) {
        self.chainStatus = status
    
        if case ChainSyncStatus.synced(_) = status {
            self.synced = true
        }
        else {
            self.synced = false
        }
    }
    
    @MainActor
    public func reloadData() {
        Task {
            await glacioCoordinator.rebuildDBFromChain()
            objectWillChange.send()
        }
    }
    
    public func addChain(chainId: String) async throws {
        try await glacioCoordinator.node.addChain(chainId: chainId)
    }
}
