//
//  NodeManager.swift
//  Glacio
//
//  Created by Peter Liddle on 1/27/23.
//

import Foundation
import GlacioCore
import Network

/// Class that creates a Glacio Node with the given directory to store chains, listening for commands on the given IP and Port
open class NodeManager {
    
    public var node: Node
    let log: Logger
    
    public let chaindir: String

    public var seedNodesRegisteredCallback: () -> Void = {}
    private let ibc: NodeInboundConnectionManager

    var discoverabilityService: DiscoverabilityService?

    public init(chaindir: String = GlacioConstants.defaultChainDir, port: UInt16 = GlacioConstants.defaultPort,
                seedNodes: [String], disableDiscoverability: Bool = false, discoverabilityServiceAddress: String, log: Logger = ConsoleLog()) throws {
        
        self.log = log
        
        let netNode = try NetworkedNode(port: port, chaindir: chaindir)

        self.chaindir = chaindir

        ibc = NodeInboundConnectionManager(port: port, node: netNode, logger: log)
        
        self.node = netNode

        if !disableDiscoverability {
            self.discoverabilityService = DiscoverabilityService(nodePort: port, discoverabilityServiceAddress: discoverabilityServiceAddress)
            self.addChainRegistrationObservers()
        }
        
        do {
            try ibc.startListening()
        }
        catch(let error) {
            log.error("Can't start node listening \(error)")
        }
        
        installDApps()
        
        connectToSeeds(seedNodes: seedNodes)
    }
    
    func addChainRegistrationObservers() {
        
        // Don't register for discoverability if there's no discoverability service
        guard let discoverabilityService = self.discoverabilityService else { return }
        
        node.eventCenter.register(eventForType: ChainAdded.self, object: self) { [weak self] eventUpdate in
            
            let log = self?.log
            
            // If we're not a netNode, i.e. we're running a local node for testing we can't use discoverability as we're not connected to anything!
            guard let netNode = self?.node as? NetworkedNode else { return }
            
            // Lookup seed nodes
            Task { [weak self] in
                let log = self?.log
                
                let registeredNodes = try await discoverabilityService.lookup(chainId: eventUpdate.chainId)
            
                _ = await withTaskGroup(of: Void.self, body: { taskGroup in
                    
                    registeredNodes.forEach({ endpoint in
                        taskGroup.addTask {
                            do {
                                _ = try await netNode.register(endpoint: endpoint)
                            }
                            catch {
                                log?.error("Failed to connect to \(endpoint)")
                            }
                        }
                    })
                })
            }
            
            do {
                try discoverabilityService.register(chainId: eventUpdate.chainId)
            }
            catch {
                log?.error("Failed to register this node for chain: \(eventUpdate.chainId): \(error)")
            }
        }
    }
    
    func connectToSeeds(seedNodes: [String]) {
        
        Task {
           _ = await withTaskGroup(of: Void.self, body: { taskGroup in
                seedNodes.forEach { urlString in
                    
                    // Validate url string, we only want {host}:{port} protocol will be added

                    let comps = urlString.split(separator: ":")
                    guard comps.count == 2, let _ = Int(comps[1]) else {
                        log.error("Invalid URL: \(urlString) should just be {host}:{port}, e.g. localhost:9999. Will skip and not register")
                        return
                    }
                    
                    guard let endpoint = NetworkEndpoint(urlString: urlString) else {
                        log.error("Invalid address \(urlString). Will skip registering")
                        return
                    }
                    
                    taskGroup.addTask {
                        do {
                            _ = try await self.node.register(endpoint: endpoint)
                        }
                        catch {
                            self.log.error("Failed to register node \(urlString) with error: \(error)")
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

