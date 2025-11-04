import SwiftUI
import SpriteKit

// MARK: - Game Scene
class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var livesLabel: SKLabelNode!
    var gameOverLabel: SKLabelNode!
    var comboLabel: SKLabelNode!
    
    var score = 0
    var lives = 3
    var isGameOver = false
    var combo = 0
    var lastHitTime: TimeInterval = 0
    var currentGameTime: TimeInterval = 0
    
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
        backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        createEnhancedStarfield()
        createNebula()
        setupPlayer()
        setupAliens()
        setupLabels()
        scheduleAlienMovement()
        scheduleAlienShooting()
        addPlayerGlow()
    }
    
    override func update(_ currentTime: TimeInterval) {
        currentGameTime = currentTime
    }
    
    func createEnhancedStarfield() {
        // Stelle multiple con parallasse
        for layer in 0..<3 {
            let starCount = layer == 0 ? 50 : (layer == 1 ? 30 : 20)
            let speed = TimeInterval(3 + layer * 2)
            
            for _ in 0..<starCount {
                let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
                star.fillColor = .white
                star.strokeColor = .clear
                star.position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                )
                star.alpha = CGFloat.random(in: 0.4...0.9)
                star.zPosition = CGFloat(-3 + layer)
                addChild(star)
                
                // Effetto twinkle
                let twinkle = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.2, duration: Double.random(in: 0.5...1.5)),
                    SKAction.fadeAlpha(to: 0.9, duration: Double.random(in: 0.5...1.5))
                ])
                star.run(SKAction.repeatForever(twinkle))
                
                // Movimento parallasse
                let moveDown = SKAction.moveBy(x: 0, y: -size.height - 100, duration: speed)
                let reset = SKAction.moveBy(x: 0, y: size.height + 100, duration: 0)
                let sequence = SKAction.sequence([moveDown, reset])
                star.run(SKAction.repeatForever(sequence))
            }
        }
    }
    
    func createNebula() {
        for _ in 0..<5 {
            let nebula = SKShapeNode(circleOfRadius: CGFloat.random(in: 100...200))
            nebula.fillColor = UIColor(red: CGFloat.random(in: 0.3...0.6),
                                       green: CGFloat.random(in: 0.1...0.3),
                                       blue: CGFloat.random(in: 0.5...0.8),
                                       alpha: 0.15)
            nebula.strokeColor = .clear
            nebula.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            nebula.zPosition = -5
            addChild(nebula)
            
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: Double.random(in: 20...40))
            nebula.run(SKAction.repeatForever(rotate))
        }
    }
    
    func setupPlayer() {
        player = SKSpriteNode(color: .clear, size: CGSize(width: 60, height: 80))
        player.position = CGPoint(x: size.width / 2, y: 120)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = alienCategory | alienBulletCategory
        player.physicsBody?.collisionBitMask = 0
        
        // Corpo centrale con gradiente
        let body = SKShapeNode(rect: CGRect(x: -20, y: -30, width: 40, height: 60), cornerRadius: 5)
        body.fillColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        body.strokeColor = UIColor(red: 0.0, green: 0.6, blue: 0.9, alpha: 1.0)
        body.lineWidth = 2
        body.glowWidth = 3
        player.addChild(body)
        
        // Ali con design futuristico
        let wing1Path = CGMutablePath()
        wing1Path.move(to: CGPoint(x: -20, y: 0))
        wing1Path.addLine(to: CGPoint(x: -40, y: -15))
        wing1Path.addLine(to: CGPoint(x: -35, y: 15))
        wing1Path.addLine(to: CGPoint(x: -20, y: 20))
        wing1Path.closeSubpath()
        
        let wing1 = SKShapeNode(path: wing1Path)
        wing1.fillColor = UIColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 0.9)
        wing1.strokeColor = .cyan
        wing1.lineWidth = 1.5
        wing1.glowWidth = 2
        player.addChild(wing1)
        
        let wing2Path = CGMutablePath()
        wing2Path.move(to: CGPoint(x: 20, y: 0))
        wing2Path.addLine(to: CGPoint(x: 40, y: -15))
        wing2Path.addLine(to: CGPoint(x: 35, y: 15))
        wing2Path.addLine(to: CGPoint(x: 20, y: 20))
        wing2Path.closeSubpath()
        
        let wing2 = SKShapeNode(path: wing2Path)
        wing2.fillColor = UIColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 0.9)
        wing2.strokeColor = .cyan
        wing2.lineWidth = 1.5
        wing2.glowWidth = 2
        player.addChild(wing2)
        
        // Cockpit con effetto vetro
        let cockpit = SKShapeNode(circleOfRadius: 12)
        cockpit.fillColor = UIColor(red: 0.8, green: 1.0, blue: 1.0, alpha: 0.7)
        cockpit.strokeColor = .white
        cockpit.lineWidth = 2
        cockpit.position = CGPoint(x: 0, y: 20)
        cockpit.glowWidth = 4
        player.addChild(cockpit)
        
        // Motori con particelle
        createEngineParticles()
        
        addChild(player)
    }
    
    func createEngineParticles() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark")
        emitter.particleBirthRate = 30
        emitter.particleLifetime = 0.5
        emitter.particleColor = .cyan
        emitter.particleColorBlendFactor = 1.0
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -1.5
        emitter.particleScale = 0.3
        emitter.particleScaleSpeed = -0.2
        emitter.particleSpeed = 50
        emitter.particleSpeedRange = 30
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 6
        emitter.position = CGPoint(x: 0, y: -40)
        emitter.particleBlendMode = .add
        player.addChild(emitter)
    }
    
    func addPlayerGlow() {
        let glow = SKShapeNode(circleOfRadius: 50)
        glow.fillColor = .clear
        glow.strokeColor = .cyan
        glow.lineWidth = 3
        glow.glowWidth = 20
        glow.alpha = 0.3
        glow.position = player.position
        glow.zPosition = player.zPosition - 1
        addChild(glow)
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 1.0),
            SKAction.scale(to: 1.0, duration: 1.0)
        ])
        glow.run(SKAction.repeatForever(pulse))
        
        // Aggiorna posizione del glow con il player
        let followPlayer = SKAction.run { [weak self, weak glow] in
            guard let self = self, let glow = glow else { return }
            glow.position = self.player.position
        }
        let wait = SKAction.wait(forDuration: 0.01)
        let sequence = SKAction.sequence([followPlayer, wait])
        run(SKAction.repeatForever(sequence))
    }
    
    func setupAliens() {
        let alienWidth: CGFloat = 50
        let alienHeight: CGFloat = 40
        let spacing: CGFloat = 20
        let startX = (size.width - (CGFloat(alienColumns) * (alienWidth + spacing))) / 2
        let startY = size.height - 200
        
        for row in 0..<alienRows {
            for col in 0..<alienColumns {
                let alien = createAlien(row: row, width: alienWidth, height: alienHeight)
                alien.position = CGPoint(
                    x: startX + CGFloat(col) * (alienWidth + spacing),
                    y: startY - CGFloat(row) * (alienHeight + spacing)
                )
                
                // Animazione di entrata
                alien.alpha = 0
                alien.setScale(0.1)
                let delay = Double(row * alienColumns + col) * 0.05
                let fadeIn = SKAction.fadeIn(withDuration: 0.3)
                let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
                let group = SKAction.group([fadeIn, scaleUp])
                alien.run(SKAction.sequence([SKAction.wait(forDuration: delay), group]))
                
                aliens.append(alien)
                addChild(alien)
            }
        }
    }
    
    func createAlien(row: Int, width: CGFloat, height: CGFloat) -> SKSpriteNode {
        let alien = SKSpriteNode(color: .clear, size: CGSize(width: width, height: height))
        alien.name = "alien"
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = false
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = bulletCategory
        alien.physicsBody?.collisionBitMask = 0
        
        let color = alienColor(for: row)
        
        // Corpo dell'alieno con forma organica
        let bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: 0, y: height / 2))
        bodyPath.addCurve(to: CGPoint(x: width / 2, y: 0),
                         control1: CGPoint(x: width / 4, y: height / 2),
                         control2: CGPoint(x: width / 2, y: height / 4))
        bodyPath.addCurve(to: CGPoint(x: 0, y: -height / 2),
                         control1: CGPoint(x: width / 2, y: -height / 4),
                         control2: CGPoint(x: width / 4, y: -height / 2))
        bodyPath.addCurve(to: CGPoint(x: -width / 2, y: 0),
                         control1: CGPoint(x: -width / 4, y: -height / 2),
                         control2: CGPoint(x: -width / 2, y: -height / 4))
        bodyPath.addCurve(to: CGPoint(x: 0, y: height / 2),
                         control1: CGPoint(x: -width / 2, y: height / 4),
                         control2: CGPoint(x: -width / 4, y: height / 2))
        
        let body = SKShapeNode(path: bodyPath)
        body.fillColor = color
        body.strokeColor = color.withAlphaComponent(0.5)
        body.lineWidth = 2
        body.glowWidth = 4
        alien.addChild(body)
        
        // Occhi luminosi
        let eye1 = SKShapeNode(circleOfRadius: 6)
        eye1.fillColor = .red
        eye1.strokeColor = .white
        eye1.lineWidth = 1
        eye1.glowWidth = 6
        eye1.position = CGPoint(x: -12, y: 5)
        alien.addChild(eye1)
        
        let eye2 = SKShapeNode(circleOfRadius: 6)
        eye2.fillColor = .red
        eye2.strokeColor = .white
        eye2.lineWidth = 1
        eye2.glowWidth = 6
        eye2.position = CGPoint(x: 12, y: 5)
        alien.addChild(eye2)
        
        // Animazione pulsante degli occhi
        let eyePulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        eye1.run(SKAction.repeatForever(eyePulse))
        eye2.run(SKAction.repeatForever(eyePulse))
        
        // Animazione ondulazione del corpo
        let wave = SKAction.sequence([
            SKAction.scaleX(to: 1.1, y: 0.95, duration: 0.8),
            SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.8)
        ])
        body.run(SKAction.repeatForever(wave))
        
        return alien
    }
    
    func alienColor(for row: Int) -> UIColor {
        switch row {
        case 0: return UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
        case 1: return UIColor(red: 0.2, green: 1.0, blue: 0.4, alpha: 1.0)
        default: return UIColor(red: 0.8, green: 0.2, blue: 1.0, alpha: 1.0)
        }
    }
    
    func setupLabels() {
        // Score label con effetto glow
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = .cyan
        scoreLabel.position = CGPoint(x: 100, y: size.height - 60)
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
        
        let scoreGlow = scoreLabel.copy() as! SKLabelNode
        scoreGlow.fontColor = .cyan
        scoreGlow.alpha = 0.5
        scoreGlow.zPosition = scoreLabel.zPosition - 1
        scoreGlow.position = scoreLabel.position
        addChild(scoreGlow)
        
        // Lives label
        livesLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        livesLabel.fontSize = 32
        livesLabel.fontColor = .green
        livesLabel.position = CGPoint(x: size.width - 100, y: size.height - 60)
        livesLabel.text = "Lives: 3"
        livesLabel.horizontalAlignmentMode = .right
        addChild(livesLabel)
        
        // Combo label (nascosto inizialmente)
        comboLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        comboLabel.fontSize = 48
        comboLabel.fontColor = .yellow
        comboLabel.position = CGPoint(x: size.width / 2, y: size.height - 150)
        comboLabel.alpha = 0
        addChild(comboLabel)
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
        let bullet = SKSpriteNode(color: .red, size: CGSize(width: 8, height: 20))
        bullet.position = shooter.position
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = alienBulletCategory
        bullet.physicsBody?.contactTestBitMask = playerCategory
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        
        // Effetto glow sul proiettile alieno
        let glow = SKShapeNode(rect: CGRect(x: -4, y: -10, width: 8, height: 20), cornerRadius: 2)
        glow.fillColor = .clear
        glow.strokeColor = .red
        glow.glowWidth = 8
        glow.lineWidth = 2
        bullet.addChild(glow)
        
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
        let bullet = SKSpriteNode(color: .yellow, size: CGSize(width: 6, height: 25))
        bullet.position = CGPoint(x: player.position.x, y: player.position.y + 50)
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.categoryBitMask = bulletCategory
        bullet.physicsBody?.contactTestBitMask = alienCategory
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        
        // Trail di particelle per il proiettile
        let trail = SKShapeNode(rect: CGRect(x: -3, y: -12, width: 6, height: 25), cornerRadius: 3)
        trail.fillColor = .clear
        trail.strokeColor = .yellow
        trail.glowWidth = 10
        trail.lineWidth = 2
        bullet.addChild(trail)
        
        addChild(bullet)
        
        let move = SKAction.moveTo(y: size.height + 50, duration: 0.8)
        let remove = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([move, remove]))
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
        
        // Esplosione spettacolare con particelle
        createExplosion(at: alien.position, color: alien.children.first?.children.first is SKShapeNode ?
                       (alien.children.first?.children.first as? SKShapeNode)?.fillColor ?? .orange : .orange)
        
        // Gestione combo
        if currentGameTime - lastHitTime < 1.0 {
            combo += 1
            showCombo()
        } else {
            combo = 1
        }
        lastHitTime = currentGameTime
        
        alien.removeFromParent()
        if let index = aliens.firstIndex(of: alien) {
            aliens.remove(at: index)
        }
        
        let points = 10 * combo
        score += points
        scoreLabel.text = "Score: \(score)"
        
        // Mostra punti fluttuanti
        showFloatingPoints(points: points, at: alien.position)
        
        if aliens.isEmpty {
            youWin()
        }
    }
    
    func createExplosion(at position: CGPoint, color: UIColor) {
        // Onda d'urto
        let shockwave = SKShapeNode(circleOfRadius: 5)
        shockwave.strokeColor = color
        shockwave.lineWidth = 3
        shockwave.glowWidth = 10
        shockwave.fillColor = .clear
        shockwave.position = position
        addChild(shockwave)
        
        let expand = SKAction.scale(to: 8.0, duration: 0.4)
        let fade = SKAction.fadeOut(withDuration: 0.4)
        let remove = SKAction.removeFromParent()
        shockwave.run(SKAction.sequence([SKAction.group([expand, fade]), remove]))
        
        // Particelle di esplosione
        for _ in 0..<12 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            particle.fillColor = color
            particle.strokeColor = .white
            particle.lineWidth = 1
            particle.glowWidth = 5
            particle.position = position
            addChild(particle)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 40...80)
            let targetX = position.x + cos(angle) * distance
            let targetY = position.y + sin(angle) * distance
            
            let move = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: 0.5)
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let scale = SKAction.scale(to: 0.1, duration: 0.5)
            let remove = SKAction.removeFromParent()
            particle.run(SKAction.sequence([SKAction.group([move, fade, scale]), remove]))
        }
    }
    
    func showCombo() {
        if combo > 1 {
            comboLabel.text = "COMBO x\(combo)!"
            comboLabel.alpha = 1.0
            comboLabel.setScale(0.5)
            
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            let wait = SKAction.wait(forDuration: 0.5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            
            comboLabel.run(SKAction.sequence([scaleUp, scaleDown, wait, fadeOut]))
        }
    }
    
    func showFloatingPoints(points: Int, at position: CGPoint) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "+\(points)"
        label.fontSize = 24
        label.fontColor = .yellow
        label.position = position
        label.zPosition = 100
        addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.8)
        let fade = SKAction.fadeOut(withDuration: 0.8)
        let remove = SKAction.removeFromParent()
        label.run(SKAction.sequence([SKAction.group([moveUp, fade]), remove]))
    }
    
    func playerHit() {
        lives -= 1
        livesLabel.text = "Lives: \(lives)"
        livesLabel.fontColor = lives <= 1 ? .red : .green
        
        // Reset combo
        combo = 0
        
        // Effetto di danno più intenso
        createExplosion(at: player.position, color: .cyan)
        
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        player.run(SKAction.repeat(flash, count: 5))
        
        // Scossa dello schermo
        let shakeLeft = SKAction.moveBy(x: -10, y: 0, duration: 0.05)
        let shakeRight = SKAction.moveBy(x: 10, y: 0, duration: 0.05)
        let shakeSequence = SKAction.sequence([shakeLeft, shakeRight, shakeLeft, shakeRight])
        camera?.run(shakeSequence)
        
        if lives <= 0 {
            gameOver()
        }
    }
    
    func gameOver() {
        isGameOver = true
        removeAction(forKey: "alienMovement")
        
        // Effetto di fade sul background
        let overlay = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        overlay.fillColor = .black
        overlay.alpha = 0
        overlay.zPosition = 50
        addChild(overlay)
        overlay.run(SKAction.fadeAlpha(to: 0.7, duration: 0.5))
        
        gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.fontSize = 72
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.zPosition = 100
        gameOverLabel.alpha = 0
        gameOverLabel.setScale(0.5)
        addChild(gameOverLabel)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.5)
        gameOverLabel.run(SKAction.group([fadeIn, scaleUp]))
        
        // Glow rosso sul testo
        let glow = gameOverLabel.copy() as! SKLabelNode
        glow.fontColor = .red
        glow.alpha = 0.3
        glow.zPosition = gameOverLabel.zPosition - 1
        glow.position = gameOverLabel.position
        addChild(glow)
        
        let finalScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        finalScoreLabel.fontSize = 36
        finalScoreLabel.fontColor = .white
        finalScoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        finalScoreLabel.text = "Final Score: \(score)"
        finalScoreLabel.zPosition = 100
        finalScoreLabel.alpha = 0
        addChild(finalScoreLabel)
        finalScoreLabel.run(SKAction.fadeIn(withDuration: 0.5))
        
        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        restartLabel.fontSize = 32
        restartLabel.fontColor = .cyan
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 100)
        restartLabel.text = "Tap to Restart"
        restartLabel.zPosition = 100
        restartLabel.alpha = 0
        addChild(restartLabel)
        
        let wait = SKAction.wait(forDuration: 0.5)
        let fadeInRestart = SKAction.fadeIn(withDuration: 0.5)
        restartLabel.run(SKAction.sequence([wait, fadeInRestart]))
        
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        restartLabel.run(SKAction.repeatForever(blink))
    }
    
    func youWin() {
        isGameOver = true
        removeAction(forKey: "alienMovement")
        
        // Celebrazione con fuochi d'artificio
        createFireworks()
        
        // Effetto di fade sul background
        let overlay = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        overlay.fillColor = .black
        overlay.alpha = 0
        overlay.zPosition = 50
        addChild(overlay)
        overlay.run(SKAction.fadeAlpha(to: 0.6, duration: 0.5))
        
        let winLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        winLabel.fontSize = 72
        winLabel.fontColor = .green
        winLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        winLabel.text = "YOU WIN!"
        winLabel.zPosition = 100
        winLabel.alpha = 0
        winLabel.setScale(0.5)
        addChild(winLabel)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
        let scaleNormal = SKAction.scale(to: 1.0, duration: 0.2)
        winLabel.run(SKAction.sequence([SKAction.group([fadeIn, scaleUp]), scaleNormal]))
        
        // Glow verde
        let glow = winLabel.copy() as! SKLabelNode
        glow.fontColor = .green
        glow.alpha = 0.3
        glow.zPosition = winLabel.zPosition - 1
        glow.position = winLabel.position
        addChild(glow)
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        glow.run(SKAction.repeatForever(pulse))
        
        let finalScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        finalScoreLabel.fontSize = 36
        finalScoreLabel.fontColor = .yellow
        finalScoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        finalScoreLabel.text = "Final Score: \(score)"
        finalScoreLabel.zPosition = 100
        finalScoreLabel.alpha = 0
        addChild(finalScoreLabel)
        finalScoreLabel.run(SKAction.fadeIn(withDuration: 0.5))
        
        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        restartLabel.fontSize = 32
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 100)
        restartLabel.text = "Tap to Restart"
        restartLabel.zPosition = 100
        restartLabel.alpha = 0
        addChild(restartLabel)
        
        let wait = SKAction.wait(forDuration: 0.5)
        let fadeInRestart = SKAction.fadeIn(withDuration: 0.5)
        restartLabel.run(SKAction.sequence([wait, fadeInRestart]))
        
        let blink = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.5)
        ])
        restartLabel.run(SKAction.repeatForever(blink))
    }
    
    func createFireworks() {
        for i in 0..<5 {
            let delay = Double(i) * 0.3
            let wait = SKAction.wait(forDuration: delay)
            let spawn = SKAction.run { [weak self] in
                guard let self = self else { return }
                let x = CGFloat.random(in: self.size.width * 0.2...self.size.width * 0.8)
                let y = CGFloat.random(in: self.size.height * 0.4...self.size.height * 0.8)
                self.createFirework(at: CGPoint(x: x, y: y))
            }
            run(SKAction.sequence([wait, spawn]))
        }
    }
    
    func createFirework(at position: CGPoint) {
        let colors: [UIColor] = [.red, .green, .blue, .yellow, .cyan, .magenta]
        let color = colors.randomElement()!
        
        for _ in 0..<20 {
            let particle = SKShapeNode(circleOfRadius: 4)
            particle.fillColor = color
            particle.strokeColor = .white
            particle.lineWidth = 1
            particle.glowWidth = 6
            particle.position = position
            particle.zPosition = 60
            addChild(particle)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 60...120)
            let targetX = position.x + cos(angle) * distance
            let targetY = position.y + sin(angle) * distance
            
            let move = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: 0.8)
            let fade = SKAction.fadeOut(withDuration: 0.8)
            let scale = SKAction.scale(to: 0.1, duration: 0.8)
            let remove = SKAction.removeFromParent()
            particle.run(SKAction.sequence([SKAction.group([move, fade, scale]), remove]))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            restartGame()
        }
    }
    
    func restartGame() {
        let newScene = GameScene(size: size)
        newScene.scaleMode = scaleMode
        view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 1.0))
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
