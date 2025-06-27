//
//  ContentView.swift
//  MetalWithSwiftUI
//
//  Created by CurvSurf-SGKim on 6/23/25.
//

// Metal API: Define MTLDevice -> Vertex Buffer (TriangleRenderer.swift) ->
//            Vertex Shader (shader.metal) -> Fragment Shader (shader.metal) ->
//            Render Pipeline (TriangleRenderer) -> Command Queue ->
//            Encoder (TriangleRenderer)

import Metal
import MetalKit
import SwiftUI

@Observable
final class ContentModel {
    
    let device: MTLDevice                               // Device
    private let commandQueue: MTLCommandQueue           // Command Queue
    private let triangleRenderer: TriangleRenderer      // Triangle Renderer
    
    private var startTime = CACurrentMediaTime()        // This is for changeTriangle
    var rotationPerSecond: Float = 0.33                 // Rotation part
    var rotation: Float = 0.0
    var brightness: Float = 1.0                         // Brightness part
    
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
    
    func changeTriangle(_ timeElapsed: Float) {
        // rotation
        let angle = rotationPerSecond * timeElapsed * 2.0 * .pi
        rotation += angle
        self.triangleRenderer.transform = .rotate(angle: rotation, along: .init(0,0,1))
        
        // brightness
        self.triangleRenderer.brightness = self.brightness
    }
    
    func onDraw(_ view: MTKView) {
        // Rendering: Render Pass Descriptor -> Command Buffer ->
        //            Encoder (Triangle Renderer) -> Commit Command Buffer
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),   // Command Buffer
            let drawable = view.currentDrawable,
            let passDescriptor = view.currentRenderPassDescriptor,  // Render Pass Descriptor
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else { return }
        
        // 0) Rotating Triangle
        let currentTime = CACurrentMediaTime()
        let timeElapsed = Float(currentTime - startTime)
        changeTriangle(timeElapsed)
        startTime = currentTime
        
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
        ZStack {
            // Metal API
            MetalView(content.device,
                      onViewResized: content.onViewResized(_:_:),
                      onDraw: content.onDraw(_:))
            .ignoresSafeArea()
            
            VStack(spacing: 10) {
                // Brightness Control
                VStack {
                    Spacer()
                    Text("Brightness: \(content.brightness, format: .percent.precision(.fractionLength(2)))")
                    Slider(value: $content.brightness, in: 0.0...1.0)
                }
                
                // Rotation speed control
                VStack {
                    Text("Rotation speed: \(content.rotationPerSecond, format: .number.precision(.fractionLength(2)))")
                    Slider(value: $content.rotationPerSecond, in: 0.0...2.0)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
