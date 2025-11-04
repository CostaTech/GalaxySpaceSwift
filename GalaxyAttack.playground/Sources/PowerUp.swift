import SpriteKit

public enum PowerUpType {
    case doubleShot
    case tripleShot
    case health
    case shield
}

public class PowerUp: SKSpriteNode {

    private weak var gameScene: SKScene?
    public let type: PowerUpType

    public init(scene: SKScene) {
        self.gameScene = scene

        let types: [PowerUpType] = [.doubleShot, .tripleShot, .health, .shield]
        self.type = types.randomElement() ?? .doubleShot

        let size = CGSize(width: 40, height: 40)
        super.init(texture: nil, color: .clear, size: size)

        self.zPosition = 10
        setupAppearance()
        setupPhysics()
        startMovement()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupAppearance() {
        let (color, symbol) = getAppearance()

        let background = SKShapeNode(circleOfRadius: 18)
        background.fillColor = color
        background.strokeColor = .white
        background.lineWidth = 2
        background.alpha = 0.8
        addChild(background)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = symbol
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        addChild(label)

        let glow = SKShapeNode(circleOfRadius: 22)
        glow.fillColor = .clear
        glow.strokeColor = color
        glow.lineWidth = 3
        glow.alpha = 0.5
        glow.zPosition = -1
        addChild(glow)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.6),
            SKAction.scale(to: 1.0, duration: 0.6)
        ])
        run(SKAction.repeatForever(pulse))

        let glowPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.6),
            SKAction.fadeAlpha(to: 0.7, duration: 0.6)
        ])
        glow.run(SKAction.repeatForever(glowPulse))

        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 3.0)
        run(SKAction.repeatForever(rotate))
    }

    private func getAppearance() -> (SKColor, String) {
        switch type {
        case .doubleShot:
            return (SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0), "2×")
        case .tripleShot:
            return (SKColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 1.0), "3×")
        case .health:
            return (SKColor(red: 0.0, green: 0.8, blue: 0.3, alpha: 1.0), "+")
        case .shield:
            return (SKColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0), "🛡")
        }
    }

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: 18)
        physicsBody?.isDynamic = true
        physicsBody?.categoryBitMask = PhysicsCategory.powerUp
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.none
        physicsBody?.usesPreciseCollisionDetection = true
    }

    private func startMovement() {
        let moveDown = SKAction.moveTo(y: -50, duration: 8.0)
        let remove = SKAction.removeFromParent()
        run(SKAction.sequence([moveDown, remove]))
    }

    public func collect() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 2.0, duration: 0.2)
        let group = SKAction.group([fadeOut, scaleUp])
        let remove = SKAction.removeFromParent()

        run(SKAction.sequence([group, remove]))

        if let scene = gameScene {
            let particles = SKEmitterNode()
            particles.particleTexture = SKTexture(imageNamed: "spark")
            particles.particleBirthRate = 200
            particles.numParticlesToEmit = 30
            particles.particleLifetime = 0.5
            particles.emissionAngle = 0
            particles.emissionAngleRange = .pi * 2
            particles.particleSpeed = 150
            particles.particleSpeedRange = 50
            particles.particleAlpha = 1.0
            particles.particleAlphaSpeed = -2.0
            particles.particleScale = 0.4
            particles.particleScaleSpeed = -0.4
            particles.particleColor = getAppearance().0
            particles.particleColorBlendFactor = 1.0
            particles.position = position
            particles.zPosition = 50

            scene.addChild(particles)

            let wait = SKAction.wait(forDuration: 0.5)
            let removeParticles = SKAction.removeFromParent()
            particles.run(SKAction.sequence([wait, removeParticles]))
        }
    }
}
