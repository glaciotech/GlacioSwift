//
//  GlacioDebugView.swift
//  GlacioLists
//
//  Created by Peter Liddle on 3/1/23.
//

import SwiftUI
import GlacioCore

public struct GlacioDebugView: View {
    
    @EnvironmentObject var debugModel: DebugModel
    
    @State var selectedChains: Set<String> = Set([])
    
    public init() { }
    
    var nodeInfo: some View {
        HStack {
            if #available(macOS 11.0, iOS 14.0, *) {
                    Label("My Port: \(debugModel.myPort)", systemImage: "circle.square")
            } else {
                Text("My Port: \(debugModel.myPort)")
            }
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            
            nodeInfo
            Divider()
            
            Spacer(minLength: 10)
            
            if #available(macOS 11.0, iOS 14.0, *) {
                Label("Peer nodes", systemImage: "person.3")
            } else {
                Text("Peer nodes")
            }

            List(debugModel.peerNodes, id: \.self) { peer in
                Text("\(peer)")
            }
            Divider()
            
            HStack {
                if #available(macOS 11.0, iOS 14.0, *) {
                    Label("Chains", systemImage: "square.and.line.vertical.and.square")
                } else {
                    Text("Chains")
                }
                Spacer()
            }
            
            HStack(alignment: .top) {
                List(debugModel.chains, id: \.self, selection: $selectedChains) { chain in
                    Text("\(chain): \(debugModel.chainStatus(chain: chain))")
                }
                
                Spacer(minLength: 15)
                
                VStack {
                    Text("Chain Operations")
                    Button("Force Sync") {
                        debugModel.forceSync(chains: Array(selectedChains))
                    }
                }
            }
        }
    }
}

struct GlacioDebugView_Previews: PreviewProvider {
    static var previews: some View {
        GlacioDebugView()
    }
}
