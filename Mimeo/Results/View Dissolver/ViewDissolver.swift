//
//  ViewDissolver.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/3/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import MetalKit

/// A dissolver.
public final class Dissolver: NSObject, MTKViewDelegate {

    /// A view dissolver configuration.
    public struct Configuration {

        /// The default dissolver configuration.
        public static let `default` = Configuration()

        /// The number of frames the dissolve animation will last.
        public let animationFrameCount: Int = 24

        /// The dissolve animation intensity.
        public let animationIntensity: Float = 0.75

        /// The maximum x and y delta, in points, any particle may move over the
        /// duration of the dissolve animation.
        public let maximumDelta: Int = 24

    }

    /// The dissolver's configuration.
    private let configuration: Configuration

    /// The current dissolve animation frame.
    private var currentAnimationFrame: Int = 0

    /// The current dissolve animation progress.
    private var dissolveAnimationProgress: Float {
        Float(currentAnimationFrame) / Float(configuration.animationFrameCount)
    }

    /// The texel intensity random seeds.
    private var texelIntensitySeeds: vector_float2 = .zero

    /// The x delta seeds.
    private var xDeltaSeeds: vector_float2 = .zero

    /// The y delta seeds.
    private var yDeltaSeeds: vector_float2 = .zero

    /// The image to be dissolved.
    private var dissolvingImage: CGImage?

    /// The texture to be dissolved.
    private var dissolvingTexture: MTLTexture?

    /// The dissolver's render pipeline state.
    private var renderPipelineState: MTLRenderPipelineState?

    /// The dissolver's command queue.
    private var commandQueue: MTLCommandQueue?

    /// The dissolver's fragment uniforms.
    private var fragmentUniformsBuffer: MTLBuffer?

    /// The dissolver's vertex uniforms.
    private var vertexUniformsBuffer: MTLBuffer?

    public init(configuration: Configuration = .default) {
        self.configuration = configuration

        super.init()
    }

    /// Dissolve a given image. Only one item may be dissolved at a time.
    /// - Parameter image: The image which to dissolve.
    public func dissolve(image: CGImage) {
        dissolvingImage = image

        currentAnimationFrame = 0

        texelIntensitySeeds = makeRandomVector()
        xDeltaSeeds = makeRandomVector()
        yDeltaSeeds = makeRandomVector()
    }

    private func makeRandomVector() -> vector_float2 {
        vector2(
            Float.random(in: 0...1),
            Float.random(in: 0...1)
        )
    }

    public func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize
    ) { }

    public func draw(in view: MTKView) {
        guard currentAnimationFrame < configuration.animationFrameCount else {
            currentAnimationFrame = 0
            dissolvingImage = nil
            dissolvingTexture = nil
            return
        }

        guard let dissolvingImage = dissolvingImage, let device = view.device else {
            return
        }

        guard let dissolvingTexture = dissolvingTexture ?? makeTexture(
            for: dissolvingImage,
            using: device
        ) else {
            return
        }

        self.dissolvingTexture = dissolvingTexture

        guard let renderPipelineState = renderPipelineState ?? makeRenderPipelineState(
            for: view
        ) else {
            return
        }

        self.renderPipelineState = renderPipelineState

        guard let commandQueue = commandQueue ?? device.makeCommandQueue() else {
            return
        }

        self.commandQueue = commandQueue

        guard let currentRenderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }

        currentRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)

        guard let currentDrawable = view.currentDrawable,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: currentRenderPassDescriptor
        ) else {
            return
        }

        guard let fragmentUniformsBuffer = fragmentUniformsBuffer ?? makeFragmentUniformsBuffer(
            using: device
        ) else {
            return
        }

        self.fragmentUniformsBuffer = fragmentUniformsBuffer

        guard let vertexUniformsBuffer = vertexUniformsBuffer ?? makeVertexUniformsBuffer(
            using: device
        ) else {
            return
        }

        self.vertexUniformsBuffer = vertexUniformsBuffer

        let fragmentUniformsPointer = fragmentUniformsBuffer.contents().bindMemory(
            to: ViewDissolverFragmentUniforms.self,
            capacity: 1
        )

        fragmentUniformsPointer.pointee.animationProgress = dissolveAnimationProgress
        fragmentUniformsPointer.pointee.animationIntensity = configuration.animationIntensity
        fragmentUniformsPointer.pointee.maximumDelta = Float(configuration.maximumDelta)

        fragmentUniformsPointer.pointee.textureWidth = Float(dissolvingTexture.width);
        fragmentUniformsPointer.pointee.textureHeight = Float(dissolvingTexture.height);
        fragmentUniformsPointer.pointee.screenScale = Float(UIScreen.main.scale);

        fragmentUniformsPointer.pointee.texelIntensitySeeds = texelIntensitySeeds
        fragmentUniformsPointer.pointee.xDeltaSeeds = xDeltaSeeds
        fragmentUniformsPointer.pointee.yDeltaSeeds = yDeltaSeeds

        renderCommandEncoder.setFragmentBuffer(fragmentUniformsBuffer, offset: 0, index: 0)
        renderCommandEncoder.setFragmentTexture(dissolvingTexture, index: 0)

        renderCommandEncoder.setVertexBuffer(vertexUniformsBuffer, offset: 0, index: 0)

        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.drawPrimitives(
            type: .triangleStrip,
            vertexStart: 0,
            vertexCount: 4,
            instanceCount: 1
        )

        renderCommandEncoder.endEncoding()

        commandBuffer.present(currentDrawable)
        commandBuffer.commit()

        currentAnimationFrame += 1
    }

    private func makeTexture(
        for image: CGImage,
        using device: MTLDevice
    ) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: device)
        return try? textureLoader.newTexture(cgImage: image, options: nil)
    }

    private func makeRenderPipelineState(
        for view: MTKView
    ) -> MTLRenderPipelineState? {
        guard let device = view.device,
            let library = device.makeDefaultLibrary() else {
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.sampleCount = 1
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        descriptor.depthAttachmentPixelFormat = .invalid
        descriptor.vertexFunction = library.makeFunction(name: "viewDissolverVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "viewDissolverFragment")

        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    private func makeFragmentUniformsBuffer(
        using device: MTLDevice
    ) -> MTLBuffer? {
        device.makeBuffer(length: MemoryLayout<ViewDissolverFragmentUniforms>.stride, options: [])
    }

    private func makeVertexUniformsBuffer(
        using device: MTLDevice
    ) -> MTLBuffer? {
        var vertexUniforms = ViewDissolverVertexUniforms(
            textureRenderCoordinates: matrix_float4x4(
                vector_float4(-1, -1, 0, 1),
                vector_float4(1, -1, 0, 1),
                vector_float4(-1, 1, 0, 1),
                vector_float4(1, 1, 0, 1)
            ),
            textureCoordinates: matrix_float4x2(
                vector_float2(0, 1),
                vector_float2(1, 1),
                vector_float2(0, 0),
                vector_float2(1, 0)
            )
        )

        return device.makeBuffer(
            bytes: &vertexUniforms,
            length: MemoryLayout<ViewDissolverVertexUniforms>.stride, options: []
        )
    }

}
