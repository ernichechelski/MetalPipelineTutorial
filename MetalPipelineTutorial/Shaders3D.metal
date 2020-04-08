//
//  Shaders3D.metal
//  MetalPipelineTutorial
//
//  Created by Ernest Chechelski on 08/04/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

#include <metal_stdlib>
#import "Common.h"

using namespace metal;

struct VertexIn {
    float4 position [[ attribute(0) ]];
};

vertex float4 vertex_uniforms(const VertexIn vertexIn [[stage_in]],
                              constant Uniforms &uniforms [[buffer(1)]])
{
  float4 position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * vertexIn.position;
  return position;
}
