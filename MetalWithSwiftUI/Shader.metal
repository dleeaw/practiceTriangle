//
//  Shader.metal
//  MetalWithSwiftUI
//
//  Created by Donggyu Lee on 26/6/2025.
//

#include <metal_stdlib>
using namespace metal;

namespace hello_triangle {
    // 1. Input of vertex shader
    struct Vertex {
        float2 position [[ attribute(0) ]]; // slot 0: vertex coordinates (x, y)
        float3 color [[ attribute(1) ]];    // slot 1: RGB color
    };
    
    // 2. Output of vertex shader as well as Input of fragment shader
    struct VertexOut {
        float4 position [[ position ]];     // clip-space position (x, y, z, w)
        float3 color;                       // varying color (will be interpolated)
    };
    
    // 3. Vertex Shader
    vertex VertexOut vertex_function(Vertex input [[ stage_in ]], constant float4x4 &transform [[ buffer(1) ]]) {
        // input1 datatype: Vertex,     input1 variable name: input (input.position, input.color)
        // input2 datatype: float3x3,   input2 variable name: transform
        
        // 1) Build the output struct
        // 2) Transform 2D (x, y) to 4D (x, y, 0, 1)
        VertexOut output;
        output.position = transform * float4(input.position, 0, 1); // z = 0, w = 1 for clip space
        output.color = input.color;                                 // pass through the color
        return output;
    }
    
    // 4. Fragment Shader
    fragment float4 fragment_function(VertexOut input [[ stage_in ]], constant float &brightness [[ buffer(1) ]]) {
        // input1 datatype: VertexOut,  input1 variable name: input (input.position, input.color)
        // input2 datatype: float,      input2 variable name: brightness
        
        // 1) Adjust the color by a brightness factor
        auto final_color = input.color * brightness;
        
        // 2) Return RGBA
        return float4(final_color, 1);               // alpha = 1
    }
};

/* What is happening here?
 1) CPU -> GPU: Supplying a vertex buffer of (position, color) and constant "transform" matrix and "brightness" factor
 2) Vertex Stage: Transforming each 2D vertex to 3x3 matrix, emitting clip-space position + color
 3) Rasterization: Filling in all fragment positions inside the triangle, interpolating "color"
 4) Fragment Stage: Applying brightness to the interpolated color, writing final pixel RGBA
*/
