#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[ attribute(0) ]];
};

/// Returns position of the vertex modified by offests array
vertex float4 vertex_advanced(const VertexIn vertexIn [[ stage_in ]],
                              constant float2 &offsets [[ buffer(1) ]]) {
    float4 position = vertexIn.position;
    position.y += offsets[0];
    position.x += offsets[1];
    return position;
}

/// Returns color of the fragment
fragment float4 fragment_color(constant float4 &color [[ buffer(0) ]]) {
    return color;
}
