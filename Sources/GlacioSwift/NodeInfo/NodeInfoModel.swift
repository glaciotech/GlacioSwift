//
//  ChainInfoModel.swift
//  Glacio
//
//  Created by Peter Liddle on 3/5/23.
//

import Foundation
import GlacioCore

public class NodeInfoModel: ObservableObject {
    
    @Published public var chainStatus: ChainStatus = .unsynced(.initializing)
    
    private let node: GlacioCore.Node
    
    public init(node: GlacioCore.Node) {
        self.node = node
        
        node.eventCenter.register(eventForType: ChainStatusUpdated.self, object: self) { eventUpdate in
            DispatchQueue.main.async {
                self.chainStatus = eventUpdate.status
            }
        }
    }
}
