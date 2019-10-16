//
//  DissolvingTextView.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/14/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import SpriteKit
import SwiftImage

/// A dissolving text view.
public final class DissolvingTextView: SKView {

    /// The dissolving text view's dispatch queue used to preload the pixel
    /// nodes into the scene.
    private let dispatchQueue = DispatchQueue(label: "Dissolving Text View")

    /// The pixel nodes which have been loaded into the scene.
    private var pixelNodes = [SKSpriteNode]()

    /// Preload the view containing the text.
    /// - Parameter view: The text-containing view.
    public func preload(view: UIView) {
        guard let image = image(of: view) else {
            return
        }

        self.pixelNodes.removeAll()

        dispatchQueue.async {
            let fastImage = Image<RGBA<UInt8>>(uiImage: image)

            for x in stride(from: 0, to: fastImage.width, by: 4) {
                for y in stride(from: 0, to: fastImage.height, by: 4) {
                    if fastImage[x, y].alpha == 0 {
                        continue
                    }

                    let pixelNode = SKSpriteNode(color: .white, size: CGSize(width: 1, height: 1))
                    pixelNode.alpha = 0
                    pixelNode.position = CGPoint(
                        x: CGFloat(x) / UIScreen.main.scale,
                        y: CGFloat(fastImage.height - y) / UIScreen.main.scale
                    )

                    self.pixelNodes.append(pixelNode)
                }
            }
        }
    }

    /// Dissolve the text in the view.
    public func dissolveText() {
        self.scene?.removeAllChildren()

        let pixelNodeCopies = pixelNodes.map { pixelNode in
            return pixelNode.copy() as! SKNode
        }

        pixelNodeCopies.forEach { pixelNode in
            scene?.addChild(pixelNode)

            let offsetPosition = CGPoint(
                x: pixelNode.position.x + CGFloat.random(in: -16...16),
                y: pixelNode.position.y + CGFloat.random(in: -16...16)
            )

            pixelNode.alpha = 1
            pixelNode.run(SKAction.group([
                .move(to: offsetPosition, duration: 0.8),
                .fadeAlpha(to: 0, duration: 0.8)
            ]), completion: {
                self.scene?.removeAllChildren()
            })
        }
    }

    private func image(of view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}
