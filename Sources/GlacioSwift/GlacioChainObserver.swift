//
//  GlacioNodeObserver.swift
//  GlacioLists
//
//  Created by Peter Liddle on 2/21/23.
//

import Foundation
import GlacioCore
import RealmSwift
import Logging

enum DBUpdateError: Error {
    case databaseUnsynced
    case unknownRealmObject
}

class GlacioChainObserver: NodeWatcher, ObservableObject {
 
    var node: GlacioCore.Node
    let realm: Realm
    var dApp: RealmChangeDApp
    
    let logger = Logger(label: "GlacioNodeObserver")
    
    var lastBlockUpdate: Int = -1
    
    let chainId: String
    
    var toggleDBObservingCallback: (_ suspend: Bool) -> Void = { _ in }
    
    let oType: any GlacioRealmObject.Type
    
    init(node: GlacioCore.Node, realm: Realm, chainId: String, object: any GlacioRealmObject.Type) {
        self.node = node
        self.realm = realm
        self.chainId = chainId
        self.dApp = node.app(appType: RealmChangeDApp.self)!
        self.oType = object
    }
    
    @Sendable private func byChain(_ chainId: String) -> Bool { chainId == self.chainId }
    
    func createNodeObservers() throws {
        
        Task {
            for try await chainSyncedEvent in self.node.eventCenter.stream(for: Event.ChainSynced.self).filter({ self.byChain($0.chainId) }) {
            
                // We fully rebuild db at the moment to account for fork situations. This should be smarter and we should be able to just sync from changed block
                await self.buildDB()
//                try await self.loadDBData(fromIndex: chainSyncedEvent.fromBlockIndex, oType: self.oType)
            }
        }
        
        Task {
            for try await chainLoadedEvent in self.node.eventCenter.stream(for: Event.ChainLoadedFromDisk.self).filter({ self.byChain($0.chainId) }) {
                await self.buildDB()
            }
        }
        
        Task {
            for try await newBlockAddedEvent in self.node.eventCenter.stream(for: Event.NewBlockAdded.self).filter({ self.byChain($0.chainId) }) {
                self.newBlockAdded(index: newBlockAddedEvent.index)
            }
        }
    }
    
    @MainActor
    func buildDB() async {
        do {
            try self.realm.write { [weak self] in
                self?.realm.deleteAll()
            }
        }
        catch {
            logger.warning("Failed to wipe RealmDB for \(chainId)")
        }

        do {
            try await self.loadDBData(fromIndex: 0, oType: self.oType)

            self.lastBlockUpdate = (try? await self.node.getChainManager(chainId: chainId).blockchain.lastBlockInfo?.index) ?? 0 //.getChainLength(chainId: self.chainId)) ?? 0 - 1 // Last block is always one less then length. TODO: - Add last block method to chain
        }
        catch {
            logger.error("Sync callback for \(chainId) threw: \(error)")
        }
    }
    
    @MainActor
    func loadDBData<T>(fromIndex index: Int, oType: T.Type) async throws where T: GlacioRealmObject {
        
        // Disable db observing before
        toggleDBObservingCallback(true)
        
        defer {
            // Make sure we re-enable monitoring when we exit
            toggleDBObservingCallback(false)
        }
        
        do {
            try await dApp.buildDB(fromBlock: index, chainId: chainId, forType: ChangeItem<T>.self) { tx in
                
                // Update database with the latest block
                guard let realmOb = tx.changeObj as? T else { throw DBUpdateError.unknownRealmObject }
                try realm.write {
                    switch(tx.typeId) {
                    case .create:
                        guard realm.object(ofType: T.self, forPrimaryKey: realmOb.id) == nil else { return } //Don't add if the record already exists
                        self.realm.add(realmOb)
                    case .update:
                        realm.add(realmOb, update: .modified)
                    case .delete:
                        guard let existingObj = realm.object(ofType: T.self, forPrimaryKey: realmOb.id) else { return }
                        self.realm.delete(existingObj)
                    }
                }
            }
        }
        catch BlockchainError.noChain {
            logger.info("Chain is empty so nothing to load")
        }
        catch {
            logger.error("Building DB from chain failed with error: \(error)")
            throw error
        }
    }
    
    private func newBlockAdded(index: Int) {
        
        Task { [self] in
            
            defer {
                lastBlockUpdate = index
            }
            
            do {
                guard (index == lastBlockUpdate || index == lastBlockUpdate + 1) else { // We should only reload for a changed block i.e. index == or a new block index == +1
                    // Error db has become unsynced rebuild the database
                    throw DBUpdateError.databaseUnsynced
                }
                
                _ = await MainActor.run {
                    Task {
                        try await self.loadDBData(fromIndex: index, oType: oType)
                    }
                }
            }
            catch {
                print(error)
            }
        }
    }
}
