//
//  ViewController.swift
//  MetalPipelineTutorial
//
//  Created by Ernest Chechelski on 06/04/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

import Cocoa
import MetalKit

final class ViewController: NSViewController {

    private var primitives: [Primitive] = [
        SpherePrimitive(size: 1.0, color: .red, behaviour: { .init(x: sin($0 - 1.2) * 0.5, y: cos($0 - 1.2) * 0.5) }),
        SpherePrimitive(size: 0.8, color: .orange, behaviour: { .init(x: sin($0 - 1) * 0.5, y: cos($0 - 1) * 0.5) }),
        SpherePrimitive(size: 0.6, color: .yellow, behaviour: { .init(x: sin($0 - 0.8) * 0.5, y: cos($0 - 0.8) * 0.5) }),
        SpherePrimitive(size: 0.4, color: .green, behaviour: { .init(x: sin($0 - 0.6) * 0.5, y: cos($0 - 0.6) * 0.5) }),
        SpherePrimitive(size: 0.3, color: .blue, behaviour: { .init(x: sin($0 - 0.4) * 0.5, y: cos($0 - 0.4) * 0.5) }),
        SpherePrimitive(size: 0.2, color: .purple, behaviour: { .init(x: sin($0 - 0.2) * 0.5, y: cos($0 - 0.2) * 0.5) })
    ]

    private var metalView: MTKView { view as! MTKView }

    private var renderer: MetalRenderer2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        renderer = MetalRenderer2D(metalView: metalView)
        renderer?.render(primitives: primitives)
    }
}

