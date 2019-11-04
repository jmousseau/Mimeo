//
//  ViewDissolverShaders.metal
//  Mimeo
//
//  Created by Jack Mousseau on 11/3/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

#include <metal_stdlib>

#import "ViewDissolverShaders.h"

using namespace metal;

// MARK: - Data Structures

typedef struct {
    float4 textureRenderCoordinate [[position]];
    float2 textureSampleCoordinate;
} TextureVertex;

// MARK: - Helpers

float randomFromZeroToOne(float x, float y) {
    int seed = x + y * 57 + (x * y) * 241;
    seed = (seed << 13) ^ seed;
    return ((1.0 - ((seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

float randomFromNegativeOneToOne(float x, float y) {
    float value = randomFromZeroToOne(x, y);
    return randomFromZeroToOne(y, x) < 0.5 ? -1 * value : value;
}

// MARK: - Shaders

vertex TextureVertex viewDissolverVertex(constant ViewDissolverVertexUniforms &uniforms [[buffer(0)]],
                                         unsigned int vertex_id [[vertex_id]]) {
    TextureVertex textureVertex;
    textureVertex.textureRenderCoordinate = uniforms.textureRenderCoordinates[vertex_id];
    textureVertex.textureSampleCoordinate = uniforms.textureCoordinates[vertex_id];
    return textureVertex;
}

fragment float4 viewDissolverFragment(constant ViewDissolverFragmentUniforms &uniforms [[buffer(0)]],
                                      TextureVertex textureVertex [[stage_in]],
                                      texture2d<float, access::sample> texture [[texture(0)]]) {
    float animationProgress = uniforms.animationProgress;

    float x = textureVertex.textureRenderCoordinate.x;
    float y = textureVertex.textureRenderCoordinate.y;

    float texelIntensity = randomFromZeroToOne(x * uniforms.texelIntensitySeeds[0],
                                               y * uniforms.texelIntensitySeeds[1]);

    if (texelIntensity < (1 - uniforms.animationIntensity)) {
        discard_fragment();
    }

    float xDelta = randomFromNegativeOneToOne(x * uniforms.xDeltaSeeds[0],
                                              y * uniforms.xDeltaSeeds[1]);
    float yDelta = randomFromNegativeOneToOne(x * uniforms.yDeltaSeeds[0],
                                              y * uniforms.yDeltaSeeds[1]);
    float2 normalizedXYDelta = float2(xDelta * uniforms.maximumDelta * uniforms.screenScale / uniforms.textureWidth,
                                      yDelta * uniforms.maximumDelta * uniforms.screenScale / uniforms.textureHeight);

    constexpr sampler textureSampler(address::clamp_to_edge, filter::linear);
    float2 textureSampleCoordinate = textureVertex.textureSampleCoordinate + normalizedXYDelta * animationProgress;
    float4 color = texture.sample(textureSampler, textureSampleCoordinate);
    return float4(color.rgb, color.a * (1 - animationProgress));
}
