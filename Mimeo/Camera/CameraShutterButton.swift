//
//  CameraShutterButton.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/5/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

/// A camera shutter button styled like the default camera app's shutter button.
final class CameraShutterButton: UIControl {

    /// The camera button's impact feedback generator.
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)

    /// The camera button's inner circle layer.
    private lazy var innerCircleLayer: CAShapeLayer = {
        let outerRingLayer = CAShapeLayer()
        outerRingLayer.fillColor = UIColor.white.cgColor
        outerRingLayer.rasterizationScale = UIScreen.main.scale
        outerRingLayer.shouldRasterize = true
        return outerRingLayer
    }()

    /// The camera button's outer ring layer.
    private lazy var outerRingLayer: CAShapeLayer = {
        let outerRingLayer = CAShapeLayer()
        outerRingLayer.fillColor = UIColor.white.cgColor
        outerRingLayer.rasterizationScale = UIScreen.main.scale
        outerRingLayer.shouldRasterize = true
        return outerRingLayer
    }()

    private lazy var imageLayer: CALayer = {
        let imageLayer = CALayer()
        imageLayer.backgroundColor = UIColor.clear.cgColor
        imageLayer.contentsGravity = .resizeAspect
        return imageLayer
    }()

    public var image: UIImage? {
        didSet {
            imageLayer.contents = image?.cgImage
        }
    }

    override var isHighlighted: Bool {
        didSet {
            if oldValue != isHighlighted {
                animateInnerCircleLayer()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.addSublayer(innerCircleLayer)
        layer.addSublayer(imageLayer)
        layer.addSublayer(outerRingLayer)

        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        outerRingLayer.frame = rect
        outerRingLayer.path = outerRingPath(in: rect).cgPath

        innerCircleLayer.frame = rect
        innerCircleLayer.path = innerCirclePath(in: rect).cgPath

        imageLayer.frame = rect.scaleAndCenter(withRatio: 0.3)
    }

    private func animateInnerCircleLayer() {
        innerCircleLayer.add(innerCircleAnimation(), forKey: "transform")
        impactFeedbackGenerator.impactOccurred()
    }

    private func innerCircleAnimation() -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform")
        let values = [
            CATransform3DMakeScale(1.0, 1.0, 1.0),
            CATransform3DMakeScale(0.9, 0.9, 0.9)
        ]
        animation.values = isHighlighted ? values : values.reversed()
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.duration = isHighlighted ? 0.25 : 0.2
        return animation
    }

    private func outerRingPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath(ovalIn: rect)
        let innerRect = rect.scaleAndCenter(withRatio: 0.8)
        let innerPath = UIBezierPath(ovalIn: innerRect).reversing()
        path.append(innerPath)
        return path
    }

    private func innerCirclePath(in rect: CGRect) -> UIBezierPath {
        let rect = rect.scaleAndCenter(withRatio: 0.75)
        let path = UIBezierPath(ovalIn: rect)
        return path
    }

}
