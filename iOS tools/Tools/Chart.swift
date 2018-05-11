
import Foundation
import UIKit
import SpriteKit

class ChartNode : SKSpriteNode {
    var zoom: CGFloat = 1
    var grid_size: CGSize

    public init(size: CGSize, grid_size: CGSize) {
        self.grid_size = grid_size

        // Create a path
        let path = CGMutablePath()
        var x : CGFloat = 0
        while x <= size.width + grid_size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += grid_size.width
        }
        var y : CGFloat = 0
        while y <= size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width + grid_size.width, y: y))
            y += grid_size.height
        }

        // Create a shape node based on the path
        let shape_node = SKShapeNode(path: path)
        // Configure properties of shape_node
        shape_node.path = path
        shape_node.strokeColor = SKColor.red
        shape_node.lineWidth = 1.0
        shape_node.zPosition = 10.0

        // Animate
        let oneMoveLeft = SKAction.moveBy(x: -10, y: 0, duration: 1)
        let oneMoveRight = SKAction.moveBy(x: 10, y: 0, duration: 0)
        let oneSequence = SKAction.sequence([oneMoveLeft, oneMoveRight])
        let repeatMove  = SKAction.repeatForever(oneSequence)
        shape_node.run(repeatMove)

        // Configure properties for ChartNode
        super.init(texture: nil, color: UIColor.gray, size: size)
        self.blendMode = .replace
        self.anchorPoint = CGPoint(x: 0, y: 0)

        // Make shape_node a child of ChartNode
        self.addChild(shape_node)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

