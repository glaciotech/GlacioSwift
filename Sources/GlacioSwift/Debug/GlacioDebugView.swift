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
    
    @State var peerNodes = [(String, String)]()
    
    public init() { }
    
    var nodeInfo: some View {
        HStack {
            if #available(macOS 11.0, iOS 14.0, *) {
                VStack(alignment: .leading) {
                    Label("Node", systemImage: "circle.square")
                    Text("Id: \(debugModel.nodeId)")
                    Text("Port: \(debugModel.myPort)")
                }
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
                let blockInfo = debugModel.newestBlockInfo
                Text("Last Block: ( \(blockInfo.index), \(blockInfo.hashFirst4)...\(blockInfo.hashLast8) )")
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

            List(peerNodes, id: \.0) { peer in
                let backColor = peer.1 == "direct" ? Color.green : Color.blue
                HStack {
                    Text("\(peer.0)")
                    Text("\(peer.1)".capitalized)
                        .padding(2)
                        .background(RoundedRectangle(cornerRadius: 3).fill(backColor))
                }
                
            }
            
            Divider()
            
            HStack {
                if #available(macOS 11.0, iOS 14.0, *) {
                    Label("Chains", systemImage: "square.and.line.vertical.and.square")
                } else {
                    Text("Chains")
                }
                Spacer().frame(width: 10)
                Button("Refresh") {
                    guard let chainId = debugModel.chains.first else { return}
                    debugModel.refreshChainInfo(chainId: chainId)
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
                }
            }
        }.onAppear(perform: {
            Task {
                peerNodes = await debugModel.peerNodes
            }
        })
    }
}

struct GlacioDebugView_Previews: PreviewProvider {
    static var previews: some View {
        GlacioDebugView()
    }
}
