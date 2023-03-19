//
//  RealmChangeObserver.swift
//  GlacioLists
//
//  Created by Peter Liddle on 2/21/23.
//

import Foundation
import RealmSwift
import GlacioCore

class RealmChangeObserver: RealmWatcher {
    
    var observers = [String : NotificationToken]()
    
    let realm: Realm
    
    let realmDApp: RealmChangeDApp
    
    let chainId: String
    
    let oType: any GlacioRealmObject.Type
    
    let logger: Logger
    
    init(realm: Realm, realmDApp: RealmChangeDApp, chainId: String, oType: any GlacioRealmObject.Type, logger: Logger = ConsoleLog()) {
        self.logger = logger
        self.realm = realm
        self.realmDApp = realmDApp
        self.chainId = chainId
        self.oType = oType
    }
    
    func createAndStartObservers() {
        let watcher = createAndStartObserver(oType: oType)
        self.observers["\(oType.self)"] = watcher
    }
    
    func createAndStartObserver<T>(oType: T.Type) -> NotificationToken where T: GlacioRealmObject {
        let watcher = realm.objects(T.self).observe() { [weak self] changes in

            // Make sure we only watch updates. RealmCollectionChange.initial will give us the whole contents of the table on every start
            guard let self = self else { return }
            
            if case .update(_, deletions: _, insertions: _, modifications: _) = changes {
                let gChanges = self.realmChangeSetToGlacioChangeSet(changes: changes)
                self.logger.debug("Realm Observed Changes: \(gChanges)")
                do {
                    try self.realmDApp.commit(changes: gChanges, chainId: self.chainId)
                }
                catch {
                    self.logger.error("Failed to commit changes: \(gChanges) on \(self.chainId)")
                }
            }
        }
        
        return watcher
    }
    
    func stopObserving() {
        self.observers.forEach { (key: String, value: NotificationToken) in
            value.invalidate()
        }
    }
}
