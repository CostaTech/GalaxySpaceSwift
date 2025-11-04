import SwiftUI
import SpriteKit

// MARK: - Game Scene
class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var livesLabel: SKLabelNode!
    var gameOverLabel: SKLabelNode!
    
    var score = 0
    var lives = 3
    var isGameOver = false
    
    let playerCategory: UInt32 = 0x1 << 0
    let alienCategory: UInt32 = 0x1 << 1
    let bulletCategory: UInt32 = 0x1 << 2
    let alienBulletCategory: UInt32 = 0x1 << 3
    
    var alienRows = 3
    var alienColumns = 6
    var aliens: [SKSpriteNode] = []
    var moveRight = true
    var alienSpeed: TimeInterval = 2.0
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        createStarfield()
        setupPlayer()
        setupAliens()
        setupLabels()
        scheduleAlienMovement()
        scheduleAlienShooting()
    }
    
    func createStarfield() {
        for _ in 0..<100 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2))
            star.fillColor = .white
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            star.alpha = CGFloat.random(in: 0.3...1.0)
            addChild(star)
            
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: Double.random(in: 0.5...2)),
                SKAction.fadeAlpha(to: 1.0, duration: Double.random(in: 0.5...2))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }
    }
    
    func setupPlayer() {
        player = SKSpriteNode(color: .cyan, size: CGSize(width: 60, height: 80))
        player.position = CGPoint(x: size.width / 2, y: 120)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = alienCategory | alienBulletCategory
        player.physicsBody?.collisionBitMask = 0
        
        // Aggiungi dettagli visivi alla nave
        let wing1 = SKShapeNode(rect: CGRect(x: -35, y: -20, width: 15, height: 40))
        wing1.fillColor = .blue
        wing1.strokeColor = .clear
        player.addChild(wing1)
        
        let wing2 = SKShapeNode(rect: CGRect(x: 20, y: -20, width: 15, height: 40))
        wing2.fillColor = .blue
        wing2.strokeColor = .clear
        player.addChild(wing2)
        
        let cockpit = SKShapeNode(circleOfRadius: 15)
        cockpit.fillColor = .white
        cockpit.position = CGPoint(x: 0, y: 20)
        player.addChild(cockpit)
        
        addChild(player)
    }
    
    func setupAliens() {
        let alienWidth: CGFloat = 50
        let alienHeight: CGFloat = 40
        let spacing: CGFloat = 20
        let startX = (size.width - (CGFloat(alienColumns) * (alienWidth + spacing))) / 2
        let startY = size.height - 200
        
        for row in 0..<alienRows {
            for col in 0..<alienColumns {
                let alien = SKSpriteNode(color: alienColor(for: row), size: CGSize(width: alienWidth, height: alienHeight))
                alien.position = CGPoint(
                    x: startX + CGFloat(col) * (alienWidth + spacing),
                    y: startY - CGFloat(row) * (alienHeight + spacing)
                )
                alien.name = "alien"
                alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
                alien.physicsBody?.isDynamic = false
                alien.physicsBody?.categoryBitMask = alienCategory
                alien.physicsBody?.contactTestBitMask = bulletCategory
                alien.physicsBody?.collisionBitMask = 0
                
                // Aggiungi occhi agli alieni
                let eye1 = SKShapeNode(circleOfRadius: 5)
                eye1.fillColor = .red
                eye1.position = CGPoint(x: -10, y: 5)
                alien.addChild(eye1)
                
                let eye2 = SKShapeNode(circleOfRadius: 5)
                eye2.fillColor = .red
                eye2.position = CGPoint(x: 10, y: 5)
                alien.addChild(eye2)
                
                aliens.append(alien)
                addChild(alien)
            }
        }
    }
    
    func alienColor(for row: Int) -> UIColor {
        switch row {
        case 0: return .systemRed
        case 1: return .systemGreen
        default: return .systemPurple
        }
    }
    
    func setupLabels() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 100, y: size.height - 60)
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)
        
        livesLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        livesLabel.fontSize = 32
        livesLabel.fontColor = .white
        livesLabel.position = CGPoint(x: size.width - 100, y: size.height - 60)
        livesLabel.text = "Lives: 3"
        addChild(livesLabel)
    }
    
    func scheduleAlienMovement() {
        let wait = SKAction.wait(forDuration: alienSpeed)
        let move = SKAction.run { [weak self] in
            self?.moveAliens()
        }
        let sequence = SKAction.sequence([wait, move])
        run(SKAction.repeatForever(sequence), withKey: "alienMovement")
    }
    
    func moveAliens() {
        guard !isGameOver else { return }
        
        let moveDistance: CGFloat = 30
        var shouldMoveDown = false
        
        for alien in aliens {
            if moveRight {
                alien.position.x += moveDistance
                if alien.position.x > size.width - 50 {
                    shouldMoveDown = true
                }
            } else {
                alien.position.x -= moveDistance
                if alien.position.x < 50 {
                    shouldMoveDown = true
                }
            }
        }
        
        if shouldMoveDown {
            moveRight.toggle()
            for alien in aliens {
                alien.position.y -= 30
                if alien.position.y < 200 {
                    gameOver()
                }
            }
            alienSpeed = max(0.3, alienSpeed * 0.95)
            removeAction(forKey: "alienMovement")
            scheduleAlienMovement()
        }
    }
    
    func scheduleAlienShooting() {
        let wait = SKAction.wait(forDuration: 1.5)
        let shoot = SKAction.run { [weak self] in
            self?.alienShoot()
        }
        let sequence = SKAction.sequence([wait, shoot])
        run(SKAction.repeatForever(sequence))
    }
    
    func alienShoot() {
        guard !isGameOver, !aliens.isEmpty else { return }
        
        let shooter = aliens.randomElement()!
        let bullet = SKSpriteNode(color: .red, size: CGSize(width: 6, height: 20))
        bullet.position = shooter.position
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = alienBulletCategory
        bullet.physicsBody?.contactTestBitMask = playerCategory
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        addChild(bullet)
        
        let move = SKAction.moveTo(y: -50, duration: 2.0)
        let remove = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([move, remove]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        
        for touch in touches {
            let location = touch.location(in: self)
            player.position.x = location.x
            shootBullet()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        
        for touch in touches {
            let location = touch.location(in: self)
            player.position.x = max(50, min(size.width - 50, location.x))
        }
    }
    
    func shootBullet() {
        let bullet = SKSpriteNode(color: .yellow, size: CGSize(width: 8, height: 25))
        bullet.position = CGPoint(x: player.position.x, y: player.position.y + 50)
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = bulletCategory
        bullet.physicsBody?.contactTestBitMask = alienCategory
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        addChild(bullet)
        
        let move = SKAction.moveTo(y: size.height + 50, duration: 1.0)
        let remove = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([move, remove]))
        
        run(SKAction.playSoundFileNamed("", waitForCompletion: false))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        if (bodyA.categoryBitMask == bulletCategory && bodyB.categoryBitMask == alienCategory) ||
           (bodyA.categoryBitMask == alienCategory && bodyB.categoryBitMask == bulletCategory) {
            
            let alien = bodyA.categoryBitMask == alienCategory ? bodyA.node : bodyB.node
            let bullet = bodyA.categoryBitMask == bulletCategory ? bodyA.node : bodyB.node
            
            alienHit(alien: alien as? SKSpriteNode)
            bullet?.removeFromParent()
        }
        
        if (bodyA.categoryBitMask == playerCategory && bodyB.categoryBitMask == alienBulletCategory) ||
           (bodyA.categoryBitMask == alienBulletCategory && bodyB.categoryBitMask == playerCategory) {
            
            let bullet = bodyA.categoryBitMask == alienBulletCategory ? bodyA.node : bodyB.node
            bullet?.removeFromParent()
            playerHit()
        }
        
        if (bodyA.categoryBitMask == playerCategory && bodyB.categoryBitMask == alienCategory) ||
           (bodyA.categoryBitMask == alienCategory && bodyB.categoryBitMask == playerCategory) {
            gameOver()
        }
    }
    
    func alienHit(alien: SKSpriteNode?) {
        guard let alien = alien else { return }
        
        let explosion = SKShapeNode(circleOfRadius: 30)
        explosion.fillColor = .orange
        explosion.position = alien.position
        addChild(explosion)
        
        let scale = SKAction.scale(to: 2.0, duration: 0.2)
        let fade = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        explosion.run(SKAction.sequence([SKAction.group([scale, fade]), remove]))
        
        alien.removeFromParent()
        if let index = aliens.firstIndex(of: alien) {
            aliens.remove(at: index)
        }
        
        score += 10
        scoreLabel.text = "Score: \(score)"
        
        if aliens.isEmpty {
            youWin()
        }
    }
    
    func playerHit() {
        lives -= 1
        livesLabel.text = "Lives: \(lives)"
        
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        player.run(SKAction.repeat(flash, count: 3))
        
        if lives <= 0 {
            gameOver()
        }
    }
    
    func gameOver() {
        isGameOver = true
        removeAction(forKey: "alienMovement")
        
        gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.fontSize = 64
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gameOverLabel.text = "GAME OVER"
        addChild(gameOverLabel)
        
        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        restartLabel.fontSize = 32
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 80)
        restartLabel.text = "Tap to Restart"
        addChild(restartLabel)
        
        let blink = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.5)
        ])
        restartLabel.run(SKAction.repeatForever(blink))
    }
    
    func youWin() {
        isGameOver = true
        removeAction(forKey: "alienMovement")
        
        let winLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        winLabel.fontSize = 64
        winLabel.fontColor = .green
        winLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        winLabel.text = "YOU WIN!"
        addChild(winLabel)
        
        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        restartLabel.fontSize = 32
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 80)
        restartLabel.text = "Tap to Restart"
        addChild(restartLabel)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            restartGame()
        }
    }
    
    func restartGame() {
        let newScene = GameScene(size: size)
        newScene.scaleMode = scaleMode
        view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 0.5))
    }
}

// MARK: - SwiftUI View
struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: createScene(size: geometry.size))
                .ignoresSafeArea()
        }
    }
    
    func createScene(size: CGSize) -> GameScene {
        let scene = GameScene(size: size)
        scene.scaleMode = .aspectFill
        return scene
    }
}

// MARK: - App Entry Point
@main
struct GalaxyAttackApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
