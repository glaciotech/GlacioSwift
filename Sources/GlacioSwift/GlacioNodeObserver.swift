//
//  GlacioNodeObserver.swift
//  GlacioLists
//
//  Created by Peter Liddle on 2/21/23.
//

import Foundation
import GlacioCore
import RealmSwift

enum DBUpdateError: Error {
    case databaseUnsynced
    case unknownRealmObject
}

class GlacioNodeObserver: NodeWatcher, ObservableObject {
 
    var node: GlacioCore.Node
    let realm: Realm
    var dApp: RealmChangeDApp
    
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
    
    func createNodeObservers() throws {
        
        node.eventCenter.register(eventForType: ChainSynced.self, object: self) { [weak self] result in
            self?.initialDBBuild(forChain: result.chainId)
        }
        
        node.eventCenter.register(eventForType: ChainLoadedFromDisk.self, object: self) { event in
            self.initialDBBuild(forChain: event.chainId)
        }
        
        node.eventCenter.register(eventForType: NewBlockAdded.self, object: self) { [weak self] result in
            self?.newBlockAdded(index: result.index)
        }
        
        node.eventCenter.register(eventForType: PeerNodeAdded.self, object: self) { [weak self] eventUpdate in
            // Resync chains on peer update
            do {
                guard let chainId = self?.chainId else { return }
                try self?.node.sync(full: false, chainId: chainId)
            }
            catch {
               print("Sync on peer update failed with error \(error)")
            }
            
        }
    }
    
    func initialDBBuild(forChain syncedChainId: String) {
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else { return }
            
            // Clear realm db
            do {
                try self.realm.write { [weak self] in
                    self?.realm.deleteAll()
                }
            }
            catch {
                print("realm clear issue")
            }
                
            do {
                guard self.chainId == syncedChainId else { return } // Ignore sync on other chains
                
                try self.loadDBData(fromIndex: 0, oType: self.oType)
                
                self.lastBlockUpdate = (try? self.node.getChainLength(chainId: self.chainId)) ?? 0 - 1 // Last block is always one less then length. TODO: - Add last block method to chain
            }
            catch {
                print("Error during sync callback: \(error)")
            }
        }
    }
    
    func loadDBData<T>(fromIndex index: Int, oType: T.Type) throws where T: GlacioRealmObject {
        
        // Disable db observing before
        toggleDBObservingCallback(true)
        
        try dApp.buildDB(fromBlock: index, chainId: chainId, forType: ChangeItem<T>.self) { tx in
            
            do {
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
            catch {
                print(error)
                return
            }
        }
        
        toggleDBObservingCallback(false)
    }
    
    private func newBlockAdded(index: Int) {
        
        DispatchQueue.main.async { [self] in
            
            defer {
                lastBlockUpdate = index
            }
            
            do {
                guard (index == lastBlockUpdate || index == lastBlockUpdate + 1) else { // We should only reload for a changed block i.e. index == or a new block index == +1
                    // Error db has become unsynced rebuild the database
                    throw DBUpdateError.databaseUnsynced
                }
                
                try loadDBData(fromIndex: index, oType: oType)
            }
            catch {
                print(error)
            }
        }
    }
}
