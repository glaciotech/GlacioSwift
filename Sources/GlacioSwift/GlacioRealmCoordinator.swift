//
//  File.swift
//  
//
//  Created by Peter Liddle on 3/9/23.
//

import Foundation
import RealmSwift
import GlacioCore

public struct GlacioConfiguration {
    
    public var chainId: String
    public var chainDirPath: String
    public var port: UInt16
    public var seedNodes: [String]
    public var discoverabilityServiceAddress: String
    
    public init(chainId: String, chainDirPath: String, port: UInt16, seedNodes: [String], discoverabilityServiceAddress: String) {
        self.chainId = chainId
        self.chainDirPath = chainDirPath
        self.port = port
        self.seedNodes = seedNodes
        self.discoverabilityServiceAddress = discoverabilityServiceAddress
    }
}

enum GlacioError: Error {
    case noDApp
    case initFailed
}
    
    
/// Object that coordinates communication between Glacio and Realm. Listening for events from either Realm or Glacio and then transforming and transferring data between them
open class GlacioRealmCoordinator {

    let logger: Logger
    
    let realm: Realm
    let objectsToMonitor: [any GlacioRealmObject.Type]

    let nodeManager: NodeManager
    let glacioObserver: GlacioNodeObserver
    let realmChangeObserver: RealmChangeObserver
    
    public let chainId: String
    
    public var node: Node {
        return nodeManager.node
    }

    public init(realm: Realm, nodeManager: NodeManager, chainId: String = GlacioConstants.defaultChain, objectsToMonitor: [any GlacioRealmObject.Type], logger: Logger = ConsoleLog()) throws {
        
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
