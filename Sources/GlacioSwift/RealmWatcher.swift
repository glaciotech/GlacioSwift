//
//  RealmWatcher.swift
//  Glacio
//
//  Created by Peter Liddle on 2/7/23.
//

import Foundation
import RealmSwift
import Realm
import GlacioCore

public protocol RealmWatcher {
    
    func createAndStartObservers()
    
    func realmChangeSetToGlacioChangeSet<V>(changes: RealmCollectionChange<Results<V>>) -> [ChangeItem<V>] where V: GlacioRealmObject
}

public extension RealmWatcher {
    func realmChangeSetToGlacioChangeSet<V>(changes: RealmCollectionChange<Results<V>>) -> [ChangeItem<V>] where V: GlacioRealmObject {
        
        guard case let RealmCollectionChange.update(items, deletions, insertions, modifications) = changes, items.count > 0 else {
            return []
        }
        
        let newChangeItem: (ChangeType, Int) -> ChangeItem<V> = { type, index in
            // We need to create a detached version so we don't run into threading issues
            let detachedItem = V()
            RLMInitializeWithValue(detachedItem, items[index], .partialPrivateShared())
            
            return ChangeItem<V>(typeId: type, changeObj: detachedItem)
        }

        let insData = insertions.map({ newChangeItem(.create, $0) })
        let delData = deletions.map({ newChangeItem(.delete, $0) })
        let modData = modifications.map({ newChangeItem(.update, $0) })

        let allChanges = insData + delData + modData

        return allChanges
    }
}

