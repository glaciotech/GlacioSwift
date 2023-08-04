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
    
    func chainDetail(chainId: String, status: String) -> some View {
        HStack {
            Text("\(chainId): \(status)")
            Spacer()
            HStack {
                if let blockInfo = debugModel.newestBlockInfo[chainId] {
                    Text("Last Block: ( \(blockInfo.index), \(blockInfo.hashFirst4)...\(blockInfo.hashLast8) )")
                }
            }
        }
    }

    public var body: some View {
        VStack(alignment: .leading) {
            
            HStack {
                nodeInfo
                VStack {
                    Button {
                        debugModel.updateData()
                    } label: {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                }
            }
            
            Divider()
            
            Spacer(minLength: 10)
            
            if #available(macOS 11.0, iOS 14.0, *) {
                Label("Peer nodes", systemImage: "person.3")
            } else {
                Text("Peer nodes")
            }

            List(debugModel.peerNodes, id: \.0) { peer in
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
//                    guard let chainId = debugModel.chains.first else { return }
//                    Task {
//                        await debugModel.refreshChainInfo(chainId: chainId)
//                    }
                }
                Spacer()
            }
            
            HStack(alignment: .top) {
                List(Array(debugModel.chains), id: \.key, selection: $selectedChains) { (chainId, status) in
                    chainDetail(chainId: chainId, status: status)
                }
                
                Spacer(minLength: 15)
                
                VStack {
                    Text("Chain Operations")
                }
            }
        }
        .onAppear {
            debugModel.updateData()
        }
    }
}

struct GlacioDebugView_Previews: PreviewProvider {
    static var previews: some View {
        GlacioDebugView()
    }
}
