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

    @IBAction func verticalSliderValueChanged(_ sender: NSSlider) {
        renderer?.verticalRotationAngleInDegrees = sender.floatValue
    }

    @IBAction func horizontalSliderValueChanged(_ sender: NSSlider) {
        renderer?.horizontalRotationAngleInDegrees = sender.floatValue
    }

    private var primitives: [Primitive] = [
        BoxPrimitive(size: 0.9, color: .red, behaviour: { _ in .init(x: 0, y: 0, z: 0) }),
        SpherePrimitive(size: 0.9, color: .red, behaviour: { .init(x: sin($0), y: sin($0), z: 0) }),
        IcosanhedronPrimitive(size: 0.3, color: .green, behaviour: { .init(x: tan($0), y: tan($0), z: 0) })
    ]

    private var metalView: MTKView { view as! MTKView }

    private var renderer: MetalRenderer3D?

    override func viewDidLoad() {
        super.viewDidLoad()
        renderer = MetalRenderer3D(metalView: metalView)
        renderer?.render(primitives: primitives)
    }
}

