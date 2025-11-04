import Foundation

public struct PhysicsCategory {
    public static let none: UInt32 = 0
    public static let player: UInt32 = 0b1
    public static let enemy: UInt32 = 0b10
    public static let playerBullet: UInt32 = 0b100
    public static let enemyBullet: UInt32 = 0b1000
    public static let powerUp: UInt32 = 0b10000
}
