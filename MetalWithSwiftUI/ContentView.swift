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
    
    let device: MTLDevice                               // Device
    private let commandQueue: MTLCommandQueue           // Command Queue
    private let triangleRenderer: TriangleRenderer      // Triangle Renderer
    
    init() {
        let device = MTLCreateSystemDefaultDevice()!                // grab the GPU
        let commandQueue = device.makeCommandQueue()!               // make a work queue
        let library = device.makeDefaultLibrary()!                  // load my vertex shader and fragment shader
        let triangleRenderer = TriangleRenderer(device, library)    // build my render pipeline and vertex data
        
        self.device = device
        self.commandQueue = commandQueue
        self.triangleRenderer = triangleRenderer
    }
    
    func onViewResized(_ view: MTKView, _ size: CGSize) {
        
        // adjust the aspect ratio of the triangle
        self.triangleRenderer.aspectRatio = Float(size.width / size.height)
    }
    
    func onDraw(_ view: MTKView) {
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),   // Command Buffer
            let drawable = view.currentDrawable,
            let passDescriptor = view.currentRenderPassDescriptor,  // Render Pass Descriptor
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else { return }
        
        // 1) Encode my triangle's draw call
        triangleRenderer.draw(encoder)
        
        // 2) Finish encoding
        encoder.endEncoding()
        
        // 3) Show the rendered triangle to screen
        commandBuffer.present(drawable)
        
        // 4) Commit the work to the GPU
        commandBuffer.commit()
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
