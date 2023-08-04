//
//  ChainInfoView.swift
//  
//
//  Created by Peter Liddle on 3/5/23.
//

import SwiftUI
import GlacioCore

public struct ChainInfoView: View {
    
    @EnvironmentObject var chainModel: ChainModel
    
    public init() {}
    
    public var body: some View {
        HStack {
            
            let imageName: () -> String = {
                if chainModel.chainStatus ^== .synced(nil) {
                    return "square.fill.and.line.vertical.square.fill"
                }
                else {
                    return "square.and.line.vertical.and.square"
                }
            }
            
            if #available(macOS 11.0, iOS 14.0, *) {
                Label("\(chainModel.chainStatus.description)", systemImage: imageName()).font(.caption)
            } else {
                Text("\(chainModel.chainStatus.description)").font(.caption)
            }
        }
    }
}

//struct SwiftUIView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChainInfoView()
//    }
//}
