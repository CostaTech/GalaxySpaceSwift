import SpriteKit

public class EnemyAlien: SKSpriteNode {

    private weak var gameScene: SKScene?
    private var health: Int
    public var isDead: Bool { return health <= 0 }

    private var movePattern: MovePattern
    private var shootTimer: TimeInterval = 0
    private let shootInterval: TimeInterval

    private var elapsedTime: TimeInterval = 0
    private let startX: CGFloat
    private let amplitude: CGFloat

    public init(scene: SKScene, wave: Int) {
        self.gameScene = scene
        self.health = 20 + (wave * 5)
        self.shootInterval = Double.random(in: 2.0...4.0)

        let patterns: [MovePattern] = [.straight, .zigzag, .circular]
        self.movePattern = patterns.randomElement() ?? .straight

        self.startX = 0
        self.amplitude = CGFloat.random(in: 80...150)

        let size = CGSize(width: 50, height: 50)
        super.init(texture: nil, color: .clear, size: size)

        self.zPosition = 10
        setupAppearance(wave: wave)
        setupPhysics()
        startMovement()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupAppearance(wave: Int) {
        let colors: [SKColor] = [.green, .red, .purple, .orange]
        let color = colors[min(wave - 1, colors.count - 1)]

        let body = SKShapeNode(circleOfRadius: 20)
        body.fillColor = color
        body.strokeColor = .white
        body.lineWidth = 2
        addChild(body)

        let leftEye = SKShapeNode(circleOfRadius: 5)
        leftEye.fillColor = .red
        leftEye.position = CGPoint(x: -8, y: 5)
        addChild(leftEye)

        let rightEye = SKShapeNode(circleOfRadius: 5)
        rightEye.fillColor = .red
        rightEye.position = CGPoint(x: 8, y: 5)
        addChild(rightEye)

        let leftAntenna = createAntenna()
        leftAntenna.position = CGPoint(x: -10, y: 15)
        addChild(leftAntenna)

        let rightAntenna = createAntenna()
        rightAntenna.position = CGPoint(x: 10, y: 15)
        addChild(rightAntenna)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        run(SKAction.repeatForever(pulse))
    }

    private func createAntenna() -> SKShapeNode {
        let path = UIBezierPath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 0, y: 10))

        let antenna = SKShapeNode(path: path.cgPath)
        antenna.strokeColor = .white
        antenna.lineWidth = 2

        let ball = SKShapeNode(circleOfRadius: 3)
        ball.fillColor = .yellow
        ball.position = CGPoint(x: 0, y: 10)
        antenna.addChild(ball)

        let glow = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.3),
            SKAction.fadeAlpha(to: 1.0, duration: 0.3)
        ])
        ball.run(SKAction.repeatForever(glow))

        return antenna
    }

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: 20)
        physicsBody?.isDynamic = true
        physicsBody?.categoryBitMask = PhysicsCategory.enemy
        physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.playerBullet
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.usesPreciseCollisionDetection = true
    }

    private func startMovement() {
        guard let scene = gameScene else { return }

        let duration: TimeInterval = Double.random(in: 8.0...12.0)

        switch movePattern {
        case .straight:
            let move = SKAction.moveTo(y: -50, duration: duration)
            let remove = SKAction.removeFromParent()
            run(SKAction.sequence([move, remove]))

        case .zigzag:
            let originalX = position.x
            let moveAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let progress = elapsedTime / CGFloat(duration)
                node.position.y = scene.size.height - (progress * (scene.size.height + 100))
                node.position.x = originalX + sin(progress * 10) * 80
            }
            let remove = SKAction.removeFromParent()
            run(SKAction.sequence([moveAction, remove]))

        case .circular:
            let originalX = position.x
            let moveAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let progress = elapsedTime / CGFloat(duration)
                node.position.y = scene.size.height - (progress * (scene.size.height + 100))
                node.position.x = originalX + cos(progress * 8) * 100
            }
            let remove = SKAction.removeFromParent()
            run(SKAction.sequence([moveAction, remove]))
        }
    }

    public func update(_ deltaTime: TimeInterval) {
        elapsedTime += deltaTime
        shootTimer += deltaTime

        if shootTimer >= shootInterval {
            shootTimer = 0
            shoot()
        }
    }

    private func shoot() {
        guard let scene = gameScene else { return }

        let bullet = SKSpriteNode(color: .red, size: CGSize(width: 4, height: 12))
        bullet.position = CGPoint(x: position.x, y: position.y - 30)
        bullet.zPosition = 5

        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = PhysicsCategory.enemyBullet
        bullet.physicsBody?.contactTestBitMask = PhysicsCategory.player
        bullet.physicsBody?.collisionBitMask = PhysicsCategory.none
        bullet.physicsBody?.usesPreciseCollisionDetection = true

        let glow = SKSpriteNode(color: .red, size: CGSize(width: 8, height: 16))
        glow.alpha = 0.3
        glow.zPosition = -1
        bullet.addChild(glow)

        scene.addChild(bullet)

        let moveAction = SKAction.moveTo(y: -50, duration: 2.0)
        let removeAction = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([moveAction, removeAction]))
    }

    public func takeDamage(_ damage: Int) {
        health -= damage

        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.05),
            SKAction.fadeAlpha(to: 1.0, duration: 0.05)
        ])
        run(flash)
    }
}

enum MovePattern {
    case straight
    case zigzag
    case circular
}
