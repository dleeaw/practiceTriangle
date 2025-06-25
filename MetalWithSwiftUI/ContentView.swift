//
//  ContentView.swift
//  MetalWithSwiftUI
//
//  Created by CurvSurf-SGKim on 6/23/25.
//

import Metal
import MetalKit
import SwiftUI

@Observable
final class ContentModel {
    
    let device: MTLDevice
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
    }
    
    func onViewResized(_ view: MTKView, _ size: CGSize) {
        
    }
    
    func onDraw(_ view: MTKView) {
        
    }
}

struct ContentView: View {
    
    @State private var content = ContentModel()
    
    var body: some View {
        MetalView(content.device,
                  onViewResized: content.onViewResized(_:_:),
                  onDraw: content.onDraw(_:))
    }
}

#Preview {
    ContentView()
}
