//
//  TriangleRenderer.swift
//  MetalWithSwiftUI
//
//  Created by Donggyu Lee on 26/6/2025.
//

import simd
import Metal

// Vertex data definition
fileprivate struct Vertex {
    let position: simd_float2
    let color: simd_float3
}

final class TriangleRenderer {
    private let pipelineState: MTLRenderPipelineState   // Render Pipeline
    private let vertexBuffer: MTLBuffer                 // Vertex Buffer
    
    init(_ device: MTLDevice, _ library: MTLLibrary) {
        
        // 1. Loading Shader Functions
        let vertexFunction = library.makeFunction(name: "hello_triangle::vertex_function")!         // compile
        let fragmentFunction = library.makeFunction(name: "hello_triangle::fragment_function")!     // compile
        
        // 2. Build raw vertex array
        let angles: [Float] = [0, 0.33, 0.67].map { (2.0 * $0 + 0.5) * .pi }
        
        let vertexData: [Vertex] = angles.enumerated().map { (i, a) in
            let radius: Float = 0.67
            let position = radius * simd_float2(cos(a), sin(a)) // coordinate of the vertex (x, y)
            
            let color: simd_float3 = {                          // color per each position
                switch i % 3 {
                case 0: return [1,0,0]      // return red
                case 1: return [0,1,0]      // return blue
                default: return [0,0,1]     // return green
                }
            }()
            
            return Vertex(position: position, color: color)     // raw vertex data (position, color)
        }
        
        // 3. Creating GPU Vertex Buffer
        let vertexSize = MemoryLayout<Vertex>.stride
        let bufferLength = vertexSize * vertexData.count
        
        let vertexBuffer = device.makeBuffer(
            bytes: vertexData,
            length: bufferLength
        )!
        
        // 4. Describing Vertex Layout
        let vertexDescriptor = MTLVertexDescriptor()
        
        // 4a. Position -> attribute(0)                         // Which buffer holds the position data
        vertexDescriptor.attributes[0].format = .float2         // vertex coordinate = (x, y)
        vertexDescriptor.attributes[0].offset = MemoryLayout<Vertex>.offset(of: \.position)! // position data starts from here
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // 4b. Color -> attribute(1)                            // Which buffer holds the color data
        vertexDescriptor.attributes[1].format = .float3         // color = [0,0,1] or [0,1,0] or [1,0,0]
        vertexDescriptor.attributes[1].offset = MemoryLayout<Vertex>.offset(of: \.color)! // color data starts from here
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        // 4c. Buffer layout: one vertex per step (vertex 시작점 - 다음 vertex 시작점 사이 간격)
        vertexDescriptor.layouts[0].stride = vertexSize         // size of each Vertex (4*2 + 4*3 = 20bytes)
        vertexDescriptor.layouts[0].stepFunction = .perVertex   // every time you need a new vertex, read the next 'stride' bytes
        vertexDescriptor.layouts[0].stepRate = 1                // use each entry once, in order
        
        // 5. Building the Render Pipeline
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.rasterSampleCount = 1
        
        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)    // compile
        self.vertexBuffer = vertexBuffer
    }
    
    var transform: simd_float4x4 = .init(1.0)   // Identity Matrix
    var brightness: Float = 1.0
    
    // Encoder -> telling GPU what to do
    func draw(_ encoder: MTLRenderCommandEncoder) {
        
        // 1) Select Pipeline
        encoder.setRenderPipelineState(self.pipelineState)
        
        // 2) Bind vertex buffer (position & color)
        encoder.setVertexBuffer(self.vertexBuffer,
                                offset: 0,
                                index: 0)
        
        // 3) Upload transform matrix to vertex shader
        encoder.setVertexBytes(&self.transform,
                               length: MemoryLayout<simd_float4x4>.stride,
                               index: 1)
        
        // 4) Upload brightness float to fragment shader
        encoder.setFragmentBytes(&self.brightness,
                                 length: MemoryLayout<Float>.stride,
                                 index: 1)
        
        // 5) Draw 3 vertices as one triangle
        encoder.drawPrimitives(type: .triangle,
                               vertexStart: 0,
                               vertexCount: 3)
    }
}

/*
 
 What is happening here?
 define my data layout (#4) -> compile my shaders -> build a pipeline (#5) -> upload per-frame uniforms -> issue draw calls
 
 */
