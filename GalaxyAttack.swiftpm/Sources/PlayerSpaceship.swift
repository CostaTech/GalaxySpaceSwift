import SpriteKit

public class PlayerSpaceship: SKSpriteNode {

    public var health = 100
    private weak var gameScene: SKScene?

    private var targetPosition: CGPoint?
    private let moveSpeed: CGFloat = 400

    private var shootTimer: TimeInterval = 0
    private let shootInterval: TimeInterval = 0.15
    private var isShooting = true

    private var powerUpLevel = 1
    private var powerUpTimer: TimeInterval = 0
    private let powerUpDuration: TimeInterval = 10.0

    private let thruster: SKEmitterNode

    public init(scene: SKScene) {
        self.gameScene = scene

        thruster = SKEmitterNode()
        thruster.particleTexture = SKTexture(imageNamed: "spark")
        thruster.particleBirthRate = 100
        thruster.particleLifetime = 0.5
        thruster.emissionAngle = -.pi / 2
        thruster.emissionAngleRange = .pi / 8
        thruster.particleSpeed = 100
        thruster.particleSpeedRange = 50
        thruster.particleAlpha = 0.8
        thruster.particleAlphaSpeed = -1.5
        thruster.particleScale = 0.3
        thruster.particleScaleSpeed = -0.3
        thruster.particleColor = .orange
        thruster.particleColorBlendFactor = 1.0
        thruster.position = CGPoint(x: 0, y: -25)
        thruster.zPosition = -1

        let size = CGSize(width: 50, height: 60)
        super.init(texture: nil, color: .clear, size: size)

        self.zPosition = 10
        setupAppearance()
        setupPhysics()

        addChild(thruster)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupAppearance() {
        let body = SKShapeNode(rectOf: CGSize(width: 30, height: 40), cornerRadius: 5)
        body.fillColor = .cyan
        body.strokeColor = .white
        body.lineWidth = 2
        body.position = CGPoint(x: 0, y: 0)
        addChild(body)

        let cockpit = SKShapeNode(circleOfRadius: 8)
        cockpit.fillColor = SKColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        cockpit.strokeColor = .white
        cockpit.lineWidth = 1
        cockpit.position = CGPoint(x: 0, y: 5)
        addChild(cockpit)

        let leftWing = SKShapeNode(path: createWingPath(left: true))
        leftWing.fillColor = .blue
        leftWing.strokeColor = .white
        leftWing.lineWidth = 1.5
        addChild(leftWing)

        let rightWing = SKShapeNode(path: createWingPath(left: false))
        rightWing.fillColor = .blue
        rightWing.strokeColor = .white
        rightWing.lineWidth = 1.5
        addChild(rightWing)
    }

    private func createWingPath(left: Bool) -> CGPath {
        let path = UIBezierPath()
        let sign: CGFloat = left ? -1 : 1

        path.move(to: CGPoint(x: sign * 10, y: 5))
        path.addLine(to: CGPoint(x: sign * 25, y: -5))
        path.addLine(to: CGPoint(x: sign * 25, y: -15))
        path.addLine(to: CGPoint(x: sign * 10, y: -10))
        path.close()

        return path.cgPath
    }

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 40, height: 50))
        physicsBody?.isDynamic = true
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.enemyBullet | PhysicsCategory.powerUp
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.usesPreciseCollisionDetection = true
    }

    public func moveTowards(_ position: CGPoint) {
        targetPosition = position
    }

    public func update(_ deltaTime: TimeInterval) {
        if let target = targetPosition {
            let dx = target.x - position.x
            let dy = target.y - position.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance > 5 {
                let angle = atan2(dy, dx)
                let moveDistance = min(distance, moveSpeed * CGFloat(deltaTime))

                position.x += cos(angle) * moveDistance
                position.y += sin(angle) * moveDistance

                constrainToScreen()
            }
        }

        if isShooting {
            shootTimer += deltaTime
            if shootTimer >= shootInterval {
                shootTimer = 0
                shoot()
            }
        }

        if powerUpLevel > 1 {
            powerUpTimer += deltaTime
            if powerUpTimer >= powerUpDuration {
                powerUpLevel = 1
                powerUpTimer = 0
                flashShip()
            }
        }
    }

    private func constrainToScreen() {
        guard let scene = gameScene else { return }

        let margin: CGFloat = 30
        position.x = max(margin, min(position.x, scene.size.width - margin))
        position.y = max(margin, min(position.y, scene.size.height - margin))
    }

    private func shoot() {
        guard let scene = gameScene else { return }

        if powerUpLevel == 1 {
            let bullet = createBullet()
            bullet.position = CGPoint(x: position.x, y: position.y + 30)
            scene.addChild(bullet)
            animateBullet(bullet)
        } else if powerUpLevel == 2 {
            let leftBullet = createBullet()
            leftBullet.position = CGPoint(x: position.x - 15, y: position.y + 25)
            scene.addChild(leftBullet)
            animateBullet(leftBullet)

            let rightBullet = createBullet()
            rightBullet.position = CGPoint(x: position.x + 15, y: position.y + 25)
            scene.addChild(rightBullet)
            animateBullet(rightBullet)
        } else if powerUpLevel >= 3 {
            let centerBullet = createBullet()
            centerBullet.position = CGPoint(x: position.x, y: position.y + 30)
            scene.addChild(centerBullet)
            animateBullet(centerBullet)

            let leftBullet = createBullet()
            leftBullet.position = CGPoint(x: position.x - 20, y: position.y + 25)
            scene.addChild(leftBullet)
            animateBullet(leftBullet)

            let rightBullet = createBullet()
            rightBullet.position = CGPoint(x: position.x + 20, y: position.y + 25)
            scene.addChild(rightBullet)
            animateBullet(rightBullet)
        }
    }

    private func createBullet() -> SKSpriteNode {
        let bullet = SKSpriteNode(color: .yellow, size: CGSize(width: 4, height: 15))
        bullet.zPosition = 5

        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = PhysicsCategory.playerBullet
        bullet.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        bullet.physicsBody?.collisionBitMask = PhysicsCategory.none
        bullet.physicsBody?.usesPreciseCollisionDetection = true

        let glow = SKSpriteNode(color: .yellow, size: CGSize(width: 8, height: 20))
        glow.alpha = 0.3
        glow.zPosition = -1
        bullet.addChild(glow)

        return bullet
    }

    private func animateBullet(_ bullet: SKSpriteNode) {
        guard let scene = gameScene else { return }

        let moveAction = SKAction.moveTo(y: scene.size.height + 50, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([moveAction, removeAction]))
    }

    public func takeDamage(_ damage: Int) {
        health -= damage
        flashShip()
    }

    private func flashShip() {
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        run(SKAction.repeat(flash, count: 3))
    }

    public func applyPowerUp(_ type: PowerUpType) {
        switch type {
        case .doubleShot:
            powerUpLevel = 2
            powerUpTimer = 0
        case .tripleShot:
            powerUpLevel = 3
            powerUpTimer = 0
        case .health:
            health = min(100, health + 30)
        case .shield:
            health = min(100, health + 50)
            powerUpLevel = 3
            powerUpTimer = 0
        }
    }

    public func stopShooting() {
        isShooting = false
    }
}
