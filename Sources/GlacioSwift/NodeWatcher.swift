//
//  NodeWatcher.swift
//  Glacio
//
//  Created by Peter Liddle on 2/14/23.
//

import Foundation
import GlacioCore

public protocol NodeWatcher {
    var node: Node { get }
    
    func createNodeObservers() throws
}
