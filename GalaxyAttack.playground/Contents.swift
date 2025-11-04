import PlaygroundSupport
import SpriteKit
import UIKit

let sceneView = SKView(frame: CGRect(x: 0, y: 0, width: 1080, height: 810))
let scene = GameScene(size: CGSize(width: 1080, height: 810))
scene.scaleMode = .aspectFill
sceneView.presentScene(scene)

PlaygroundPage.current.liveView = sceneView
