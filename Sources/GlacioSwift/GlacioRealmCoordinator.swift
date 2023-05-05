//
//  File.swift
//  
//
//  Created by Peter Liddle on 3/9/23.
//

import Foundation
import RealmSwift
import GlacioCore

enum GlacioError: Error {
    case noDApp
    case initFailed
}
    
    
/// Object that coordinates communication between Glacio and Realm. Listening for events from either Realm or Glacio and then transforming and transferring data between them
open class GlacioRealmCoordinator {

    let logger: GlacioCore.Logger
    
    let realm: Realm
    let objectsToMonitor: [any GlacioRealmObject.Type]

    let nodeManager: NodeManager
    let glacioObserver: GlacioNodeObserver
    let realmChangeObserver: RealmChangeObserver
    
    public let chainId: String
    
    public var node: Node {
        return nodeManager.node
    }

    public init(realm: Realm, nodeManager: NodeManager, chainId: String = GlacioConstants.defaultChain, objectsToMonitor: [any GlacioRealmObject.Type], logger: GlacioCore.Logger = ConsoleLog()) throws {
        
        self.logger = logger
        
        self.chainId = chainId
        
        self.realm = realm
        self.objectsToMonitor = objectsToMonitor
        self.nodeManager = nodeManager
        
        let node = nodeManager.node
        
        do {
            
            self.glacioObserver = GlacioNodeObserver(node: node, realm: realm, chainId: chainId, object: objectsToMonitor[0])
            
            guard let realmDApp = node.app(appType: RealmChangeDApp.self) else {
                throw GlacioError.noDApp
            }
            
            self.realmChangeObserver = RealmChangeObserver(realm: realm, realmDApp: realmDApp, chainId: chainId, oType: objectsToMonitor[0])
            
            try glacioObserver.createNodeObservers()
            
            nodeManager.connect() 
            
            try nodeManager.node.addChain(chainId: chainId)
            
            realmChangeObserver.createAndStartObservers()
            
            glacioObserver.toggleDBObservingCallback = { [self] suspend in
                suspend ? realmChangeObserver.stopObserving() : realmChangeObserver.createAndStartObservers()
            }

        }
        catch {
            throw GlacioError.initFailed
        }
    }
}
