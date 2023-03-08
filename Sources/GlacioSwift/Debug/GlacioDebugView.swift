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
    
    func chainDetail(chainId: String) -> some View {
        HStack {
            Text("\(chainId): \(debugModel.chainStatus(chain: chainId))")
            Spacer()
            HStack {
                let lastBlockInfo = debugModel.lastBlockInfo(chainId: chainId)
                let hashFirst4 = String(lastBlockInfo.1.prefix(4))
                let hashLast8 = String(lastBlockInfo.1.suffix(8))
                
                Text("Last Block: ( \(lastBlockInfo.0), \(hashFirst4)...\(hashLast8) )")
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
                List(debugModel.chains, id: \.self, selection: $selectedChains) { chainId in
                    chainDetail(chainId: chainId)
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
