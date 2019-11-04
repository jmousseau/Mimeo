//
//  ViewDissolverShaders.h
//  Mimeo
//
//  Created by Jack Mousseau on 11/3/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

#import <simd/simd.h>

// MARK: - Vertex

/// The view dissolver's vertex uniforms.
typedef struct {

    /// The four corner texture render coordinates in four dimensional space.
    matrix_float4x4 textureRenderCoordinates;

    /// The four corner texture coordinates in two dimensional space.
    matrix_float4x2 textureCoordinates;

} ViewDissolverVertexUniforms;

// MARK: - Fragment

/// The view dissolver's fragment uniforms.
typedef struct {

    /// The view dissolver's animation progress.
    float animationProgress;

    /// The view dissolver's animation intensity.
    float animationIntensity;

    /// The maximum x and y delta, in points, any particle may move over the
    /// duration of the dissolve animation.
    float maximumDelta;

    /// The view dissolver's texture width.
    float textureWidth;

    /// The view dissolver's texture height.
    float textureHeight;

    /// The screen scale of the device for which the texture is rendered.
    float screenScale;

    /// The texel intensity random seeds.
    vector_float2 texelIntensitySeeds;

    /// The x delta seeds.
    vector_float2 xDeltaSeeds;

    /// The y delta seeds.
    vector_float2 yDeltaSeeds;

} ViewDissolverFragmentUniforms;
