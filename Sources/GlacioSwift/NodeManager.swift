//
//  NodeManager.swift
//  Glacio
//
//  Created by Peter Liddle on 1/27/23.
//

import Foundation
import GlacioCore

/// Class that creates a Glacio Node with the given directory to store chains, listening for commands on the given IP and Port
open class NodeManager {
    
    public var node: Node
    let cLog = ConsoleLog()
    
    public let chaindir: String
    
    public var newBlockHandler: (Int) -> Void = { _ in } {
        didSet {
            node.succesfullyAddedNewBlock = newBlockHandler
        }
    }
    
    public var seedNodesRegisteredCallback: () -> Void = {}
    
    public init(chaindir: String =  GlacioConstants.defaultChainDir, port: UInt16 = GlacioConstants.defaultPort, seedNodes: [String]) throws {
        
        let netNode = try NetworkedNode(port: port, succesfullyAddedNewBlockCallback: newBlockHandler, chaindir: chaindir)

        self.chaindir = chaindir
        
        let ibc = NodeInboundConnectionManager(port: port, node: netNode, logger: cLog)
        
        do {
            try ibc.startListening()
        }
        catch(let error) {
            cLog.error("Can't start node listening \(error)")
        }
        
        self.node = netNode
        
        installDApps()
        
        postInit(seedNodes: seedNodes)
    }
    
    func postInit(seedNodes: [String]) {
        
        Task {
           _ = await withTaskGroup(of: Void.self, body: { taskGroup in
                seedNodes.forEach { urlString in
                    
                    // Validate url string, we only want {host}:{port} protocol will be added

                    let comps = urlString.split(separator: ":")
                    guard comps.count == 2, let _ = Int(comps[1]) else {
                        cLog.error("Invalid URL: \(urlString) should just be {host}:{port}, e.g. localhost:9999. Will skip and not register")
                        return
                    }
                    
                    taskGroup.addTask {
                        do {
                            _ = try await self.node.register(nodeAddress: urlString)
                        }
                        catch {
                            self.cLog.error("Failed to register node \(urlString) with error: \(error)")
                        }
                    }
                }
            })
            
            seedNodesRegisteredCallback()
        }
    }
    
    open func installDApps() {
        node.install(appType: RealmChangeDApp.self)
    }
    
    public func loadNode(atIP: String = "localhost", atPort: Int) throws {
        self.node = try NetworkedNode(ip: atIP, port: UInt16(atPort))
        self.node.install(appType: RealmChangeDApp.self)
    }
}

