//
//  Rendering.swift
//  MetalPipelineTutorial
//
//  Created by Ernest Chechelski on 06/04/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

import MetalKit

// Struct for descrition of position in 3D Dimension
struct PositionOffsets {
    let x: Float
    let y: Float
}

import MetalKit

class Primitive {

    // Every primitive has some mesh object, which describes it's shape. This mesh can be generated later
    var mesh: MDLMesh!

    // Every primitive, to be recognized by Metal, must have mesh in MTKMesh type.
    var mtkMesh: MTKMesh!

    // Every primive has it's descriptor, which tells encoder how to interpret it's shape
    var pipelineDescriptor: MTLRenderPipelineDescriptor!

    // Let's every shape has some it's own behaviour. For specific time provide it's position
    let behaviour: ((Float) -> PositionOffsets)?

    // Every primitive has it's own color
    let color: NSColor

    // Every primitive has it's own size
    let size: Float

    init(size: Float, color: NSColor, behaviour: ((Float) -> PositionOffsets)? = nil) {
        self.color = color
        self.size = size
        self.behaviour = behaviour
    }

    /// Override this method to create mesh with provided allocator.
    /// However there is several ways to generate that mesh!
    func create(allocator: MTKMeshBufferAllocator) {}
}

final class BoxPrimitive: Primitive {

    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(boxWithExtent: [size, size, size],
                           segments: [1, 1, 1],
                           inwardNormals: false, geometryType: .lines,
                           allocator: allocator)
    }
}

class SpherePrimitive: Primitive {

    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(sphereWithExtent: [size/2,size/2,size/2],
                       segments: [20,20],
                       inwardNormals: false,
                       geometryType: .lines,
                       allocator: allocator)
    }
}

final class ConePrimitive: Primitive {

    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(coneWithExtent: [size,size,size],
                       segments: [2,20],
                       inwardNormals: false, cap: true,
                       geometryType: .lines,
                       allocator: allocator)

    }
}

final class IcosanhedronPrimitive: Primitive {

    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(icosahedronWithExtent: [size,size,size],
                       inwardNormals: false,
                       geometryType: .lines,
                       allocator: allocator)
    }
}

final class MetalRenderer2D: NSObject, MTKViewDelegate {

    private let metalView: MTKView /// UI component which shows rendered content.
    private let device: MTLDevice /// Abstract layer which describes device which performs Metal code.
    private let commandQueue: MTLCommandQueue /// Queue of commands. More info below :)
    private let allocator: MTKMeshBufferAllocator /// This class is used to allocate all meshes in the scene.

    private let vertexFunction: MTLFunction /// Here I'll keep vertex function, which translates mesh position to the position on the screen.
    private let fragmentFunction: MTLFunction /// Here I'll keep fragment function, which provides appearance (like color) for each piece of mesh.

    private var timer: Float = 0 /// To animate all objects I defined a timer.

    private var primitves = [Primitive]() /// Reference to keep all defined primitives to render.


    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("GPU not available") }

        guard let commandQueue = device.makeCommandQueue() else {  fatalError("No available resources to create command queue") }

        /// All functions implemented in metal language we can access here.
        guard let library = device.makeDefaultLibrary() else {  fatalError("Cannot create library with Metl functions") }

        self.device = device
        self.metalView = metalView
        self.metalView.device = device
        self.commandQueue = commandQueue
        self.allocator = MTKMeshBufferAllocator(device: device)
        self.vertexFunction = library.vertexAdvancedFunction
        self.fragmentFunction = library.fragmentColorFunction

        super.init()
        metalView.delegate = self
    }

    func render(primitives: [Primitive]) {
        self.primitves = primitives
        primitives.forEach {
            $0.create(allocator: allocator)
            $0.mtkMesh = try! MTKMesh(mesh: $0.mesh, device: device)

            /// Descriptor describes how bytes put in encoder should be interpreted via Metal code
            $0.pipelineDescriptor = MTLRenderPipelineDescriptor(
                  vertexFunction: vertexFunction,
                  fragmentFunction: fragmentFunction,
                  primitiveForVertexDescriptor: $0,
                  colorPixelFormat: metalView.colorPixelFormat
            )
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

    func draw(in view: MTKView) {
        timer += 0.02
        timer = timer.truncatingRemainder(dividingBy: 1000)  /// Truncate timer to make sure that won't generate too huge value

        guard
            let descriptor = view.currentRenderPassDescriptor, /// For each frame we need descriptor which describes current parameters (like shape) of MTKView.
            let commandBuffer = commandQueue.makeCommandBuffer(), /// Buffer is place for array of commands for each frame.
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) /// Encoder translates input data to actually rendered pixels.
        else {
            return
        }

        primitves.forEach {

            let vertexBuffer = $0.mtkMesh.vertexBuffers.first?.buffer // Each primitve has at least one vertex buffer, which holds it's vertex data.
            vertexBuffer?.setPurgeableState(.nonVolatile) // Let's prevent buffer from releasing it's data.

            do {
                let pipelineState = try device.makeRenderPipelineState(descriptor: $0.pipelineDescriptor) /// Making pipeline state means that we know current device supports pipeline descriptor.

                renderEncoder.setRenderPipelineState(pipelineState) /// Put ready state into encoder.
                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0) /// Put vertex buffer for this mesh into encoder.

                renderEncoder.setPositionOffset(offset: $0.behaviour?(timer) ?? PositionOffsets(x: 0, y: 0)) /// Calculate offset for each mesh based on it's behaviour
                renderEncoder.setColor($0.color) /// Set color for each mesh.
                renderEncoder.draw(mtkMesh: $0.mtkMesh) ///Draw every submesh of each mesh.

            } catch let error {
                fatalError(error.localizedDescription)
            }
            vertexBuffer?.setPurgeableState(.volatile) /// Now we can allow to release all buffer data as it is not useful anymore.
        }

        renderEncoder.endEncoding() /// End encoding every command.

        /// If view has frame which can be filled with our rendered content, just attach it to buffer.
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

extension MTLRenderPipelineDescriptor {

    /// This initializer describes all things that we need to properly render primitive
    convenience init(vertexFunction: MTLFunction, fragmentFunction: MTLFunction, primitiveForVertexDescriptor: Primitive, colorPixelFormat: MTLPixelFormat) {
        self.init()
        self.vertexFunction = vertexFunction
        self.fragmentFunction = fragmentFunction
        self.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(primitiveForVertexDescriptor.mesh.vertexDescriptor)!
        colorAttachments[0].pixelFormat = colorPixelFormat
    }
}


extension MTLLibrary {

    /// Reference to 
    var vertexAdvancedFunction: MTLFunction {
        makeFunction(name: "vertex_advanced")!
    }

    var fragmentColorFunction: MTLFunction {
        makeFunction(name: "fragment_color")!
    }
}

extension MTLRenderCommandEncoder {

    /// Compatible with `MTLLibrary.fragmentColorFunction`
    func setColor(_ color: NSColor) {
        var fragmentColor = color.fragmentBytes
        setFragmentBytes(&fragmentColor, length: MemoryLayout.size(ofValue: fragmentColor), index: 0)
    }

    /// Compatible with `MTLLibrary.vertexAdvancedFunction`
    func setPositionOffset(offset: PositionOffsets) {
        var currentOffset = offset.vertexBytes
        setVertexBytes(&currentOffset, length: MemoryLayout.size(ofValue: currentOffset), index: 1)
    }
}

extension MTLRenderCommandEncoder {

    func draw(mtkMesh: MTKMesh) {
        mtkMesh.submeshes.forEach(draw(mtkSubmesh:))
    }

    func draw(mtkSubmesh: MTKSubmesh) {
        drawIndexedPrimitives(
            type: mtkSubmesh.primitiveType,
            indexCount: mtkSubmesh.indexCount,
            indexType: mtkSubmesh.indexType,
            indexBuffer: mtkSubmesh.indexBuffer.buffer,
            indexBufferOffset: mtkSubmesh.indexBuffer.offset
        )
    }
}

fileprivate extension PositionOffsets {

    /// Compatible with `MTLLibrary.vertexAdvancedFunction`
    var vertexBytes: vector_float2 {
        vector_float2(x,y)
    }
}

extension NSColor {

    /// Compatible with `fragment_color`
    var fragmentBytes: vector_float4 {
        vector_float4(
            Float(redComponent),
            Float(greenComponent),
            Float(blueComponent),
            Float(alphaComponent)
        )
    }

    /// Compatible with MTKView
    var mtlColor: MTLClearColor {
        MTLClearColor(
            red: Double(redComponent),
            green: Double(greenComponent),
            blue: Double(blueComponent),
            alpha: Double(alphaComponent)
        )
    }

    /// mtlColor field is supported only with RGB colorspace.
    static var rgbBlack: NSColor {
        NSColor(colorSpace: .genericRGB, components: [
            CGFloat(0),
            CGFloat(0),
            CGFloat(0),
            CGFloat(0)
        ], count: 4)
    }
}
