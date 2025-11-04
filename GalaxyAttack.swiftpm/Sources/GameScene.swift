import SpriteKit
import Foundation

public class GameScene: SKScene, SKPhysicsContactDelegate {

    private var player: PlayerSpaceship!
    private var scoreLabel: SKLabelNode!
    private var healthLabel: SKLabelNode!
    private var gameOverLabel: SKLabelNode!
    private var waveLabel: SKLabelNode!

    private var score = 0
    private var currentWave = 1
    private var enemiesInWave = 5
    private var enemiesDestroyed = 0

    private var isGameOver = false
    private var lastUpdateTime: TimeInterval = 0
    private var enemySpawnTimer: TimeInterval = 0
    private let enemySpawnInterval: TimeInterval = 1.5

    private var stars: [SKSpriteNode] = []

    public override func didMove(to view: SKView) {
        setupPhysics()
        setupBackground()
        setupPlayer()
        setupUI()
        startGame()
    }

    private func setupPhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }

    private func setupBackground() {
        backgroundColor = SKColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0)

        for i in 0..<100 {
            let star = SKSpriteNode(color: .white, size: CGSize(width: 2, height: 2))
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            star.alpha = CGFloat.random(in: 0.3...1.0)
            star.zPosition = -1
            addChild(star)
            stars.append(star)

            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: Double.random(in: 0.5...2.0)),
                SKAction.fadeAlpha(to: 1.0, duration: Double.random(in: 0.5...2.0))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }
    }

    private func setupPlayer() {
        player = PlayerSpaceship(scene: self)
        player.position = CGPoint(x: size.width / 2, y: 150)
        addChild(player)
    }

    private func setupUI() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 100, y: size.height - 50)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.text = "Score: 0"
        scoreLabel.zPosition = 100
        addChild(scoreLabel)

        healthLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        healthLabel.fontSize = 32
        healthLabel.fontColor = .red
        healthLabel.position = CGPoint(x: size.width - 100, y: size.height - 50)
        healthLabel.horizontalAlignmentMode = .right
        healthLabel.text = "❤️ 100"
        healthLabel.zPosition = 100
        addChild(healthLabel)

        waveLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        waveLabel.fontSize = 28
        waveLabel.fontColor = .cyan
        waveLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        waveLabel.text = "Wave 1"
        waveLabel.zPosition = 100
        addChild(waveLabel)
    }

    private func startGame() {
        isGameOver = false
        score = 0
        currentWave = 1
        enemiesDestroyed = 0
        updateScore()
        showWaveLabel()
    }

    private func showWaveLabel() {
        waveLabel.text = "Wave \(currentWave)"
        waveLabel.setScale(0.1)
        waveLabel.alpha = 0

        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.3)
        let scale = SKAction.scale(to: 1.5, duration: 0.3)
        let wait = SKAction.wait(forDuration: 1.0)
        let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)

        let group1 = SKAction.group([fadeIn, scale])
        let group2 = SKAction.group([fadeOut, scaleDown])

        waveLabel.run(SKAction.sequence([group1, wait, group2]))
    }

    public override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        if !isGameOver {
            player.update(deltaTime)
            updateStars(deltaTime)
            spawnEnemies(currentTime)
            checkWaveCompletion()
        }
    }

    private func updateStars(_ deltaTime: TimeInterval) {
        for star in stars {
            star.position.y -= CGFloat(30 * deltaTime)

            if star.position.y < 0 {
                star.position.y = size.height
                star.position.x = CGFloat.random(in: 0...size.width)
            }
        }
    }

    private func spawnEnemies(_ currentTime: TimeInterval) {
        enemySpawnTimer += currentTime - lastUpdateTime

        if enemySpawnTimer >= enemySpawnInterval {
            enemySpawnTimer = 0

            let currentEnemyCount = children.filter { $0 is EnemyAlien }.count
            if currentEnemyCount < enemiesInWave {
                spawnEnemy()
            }
        }
    }

    private func spawnEnemy() {
        let enemy = EnemyAlien(scene: self, wave: currentWave)
        let randomX = CGFloat.random(in: 50...(size.width - 50))
        enemy.position = CGPoint(x: randomX, y: size.height + 50)
        addChild(enemy)
    }

    private func checkWaveCompletion() {
        let currentEnemyCount = children.filter { $0 is EnemyAlien }.count

        if enemiesDestroyed >= enemiesInWave && currentEnemyCount == 0 {
            nextWave()
        }
    }

    private func nextWave() {
        currentWave += 1
        enemiesInWave += 3
        enemiesDestroyed = 0
        showWaveLabel()

        if currentWave % 3 == 0 {
            spawnPowerUp()
        }
    }

    private func spawnPowerUp() {
        let powerUp = PowerUp(scene: self)
        let randomX = CGFloat.random(in: 100...(size.width - 100))
        powerUp.position = CGPoint(x: randomX, y: size.height + 50)
        addChild(powerUp)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if isGameOver {
            if gameOverLabel?.contains(location) == true {
                restartGame()
            }
        } else {
            player.moveTowards(location)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !isGameOver else { return }
        let location = touch.location(in: self)
        player.moveTowards(location)
    }

    public func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if collision == PhysicsCategory.playerBullet | PhysicsCategory.enemy {
            handlePlayerBulletEnemyCollision(contact)
        } else if collision == PhysicsCategory.player | PhysicsCategory.enemy {
            handlePlayerEnemyCollision(contact)
        } else if collision == PhysicsCategory.player | PhysicsCategory.enemyBullet {
            handlePlayerEnemyBulletCollision(contact)
        } else if collision == PhysicsCategory.player | PhysicsCategory.powerUp {
            handlePlayerPowerUpCollision(contact)
        }
    }

    private func handlePlayerBulletEnemyCollision(_ contact: SKPhysicsContact) {
        let bullet = contact.bodyA.categoryBitMask == PhysicsCategory.playerBullet ? contact.bodyA.node : contact.bodyB.node
        let enemy = contact.bodyA.categoryBitMask == PhysicsCategory.enemy ? contact.bodyA.node as? EnemyAlien : contact.bodyB.node as? EnemyAlien

        bullet?.removeFromParent()

        if let enemy = enemy {
            enemy.takeDamage(10)
            if enemy.isDead {
                createExplosion(at: enemy.position, color: .green)
                enemy.removeFromParent()
                enemiesDestroyed += 1
                addScore(10 * currentWave)
            }
        }
    }

    private func handlePlayerEnemyCollision(_ contact: SKPhysicsContact) {
        let enemy = contact.bodyA.categoryBitMask == PhysicsCategory.enemy ? contact.bodyA.node as? EnemyAlien : contact.bodyB.node as? EnemyAlien

        if let enemy = enemy {
            createExplosion(at: enemy.position, color: .red)
            enemy.removeFromParent()
            player.takeDamage(20)
            updateHealth()
        }
    }

    private func handlePlayerEnemyBulletCollision(_ contact: SKPhysicsContact) {
        let bullet = contact.bodyA.categoryBitMask == PhysicsCategory.enemyBullet ? contact.bodyA.node : contact.bodyB.node

        bullet?.removeFromParent()
        player.takeDamage(10)
        updateHealth()
    }

    private func handlePlayerPowerUpCollision(_ contact: SKPhysicsContact) {
        let powerUp = contact.bodyA.categoryBitMask == PhysicsCategory.powerUp ? contact.bodyA.node as? PowerUp : contact.bodyB.node as? PowerUp

        if let powerUp = powerUp {
            powerUp.collect()
            player.applyPowerUp(powerUp.type)
            addScore(50)
        }
    }

    private func createExplosion(at position: CGPoint, color: SKColor) {
        let explosion = SKEmitterNode()
        explosion.particleTexture = SKTexture(imageNamed: "spark")
        explosion.particleBirthRate = 500
        explosion.numParticlesToEmit = 50
        explosion.particleLifetime = 0.5
        explosion.emissionAngle = 0
        explosion.emissionAngleRange = .pi * 2
        explosion.particleSpeed = 200
        explosion.particleSpeedRange = 100
        explosion.particleAlpha = 1.0
        explosion.particleAlphaRange = 0.3
        explosion.particleAlphaSpeed = -2.0
        explosion.particleScale = 0.5
        explosion.particleScaleRange = 0.3
        explosion.particleScaleSpeed = -0.5
        explosion.particleColorBlendFactor = 1.0
        explosion.particleColor = color
        explosion.position = position
        explosion.zPosition = 50

        addChild(explosion)

        let wait = SKAction.wait(forDuration: 0.5)
        let remove = SKAction.removeFromParent()
        explosion.run(SKAction.sequence([wait, remove]))
    }

    private func addScore(_ points: Int) {
        score += points
        updateScore()
    }

    private func updateScore() {
        scoreLabel.text = "Score: \(score)"
    }

    private func updateHealth() {
        healthLabel.text = "❤️ \(max(0, player.health))"

        if player.health <= 0 && !isGameOver {
            gameOver()
        }
    }

    private func gameOver() {
        isGameOver = true
        player.stopShooting()

        createExplosion(at: player.position, color: .orange)
        player.removeFromParent()

        gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.fontSize = 64
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.zPosition = 101
        addChild(gameOverLabel)

        let finalScore = SKLabelNode(fontNamed: "AvenirNext-Bold")
        finalScore.fontSize = 40
        finalScore.fontColor = .white
        finalScore.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        finalScore.text = "Final Score: \(score)"
        finalScore.zPosition = 101
        addChild(finalScore)

        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        restartLabel.fontSize = 36
        restartLabel.fontColor = .cyan
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 100)
        restartLabel.text = "Tap to Restart"
        restartLabel.name = "restart"
        restartLabel.zPosition = 101
        addChild(restartLabel)

        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        restartLabel.run(SKAction.repeatForever(blink))
    }

    private func restartGame() {
        removeAllChildren()
        setupBackground()
        setupPlayer()
        setupUI()
        startGame()
    }
}
