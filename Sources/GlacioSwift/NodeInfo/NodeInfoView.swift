//
//  SwiftUIView.swift
//  
//
//  Created by Peter Liddle on 3/5/23.
//

import SwiftUI
import GlacioCore

public struct NodeInfoView: View {
    
    @EnvironmentObject var chainInfo: NodeInfoModel
    
    public init() {}
    
    public var body: some View {
        HStack {
            
            let imageName: () -> String = {
                if chainInfo.chainStatus ^== .synced(nil) {
                    return "square.fill.and.line.vertical.square.fill"
                }
                else {
                    return "square.and.line.vertical.and.square"
                }
            }
            
            if #available(macOS 11.0, iOS 14.0, *) {
                Label("\(chainInfo.chainStatus.description)", systemImage: imageName())
            } else {
                Text("\(chainInfo.chainStatus.description)")
            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        NodeInfoView().environmentObject(NodeInfoModel(node: try! LocalNode()))
    }
}
