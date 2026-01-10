import Foundation

struct ZMKKeyboard: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let peripheralIdentifier: UUID

    var leftBattery: BatteryLevel?
    var rightBattery: BatteryLevel?

    var lastSeen: Date
    var isConnected: Bool

    var displayName: String?
    var leftHalfLabel: String = "Left"
    var rightHalfLabel: String = "Right"

    var effectiveName: String {
        displayName ?? name
    }

    var lowestBatteryLevel: Int? {
        let levels = [leftBattery?.percentage, rightBattery?.percentage].compactMap { $0 }
        return levels.min()
    }

    init(
        id: UUID = UUID(),
        name: String,
        peripheralIdentifier: UUID,
        leftBattery: BatteryLevel? = nil,
        rightBattery: BatteryLevel? = nil,
        lastSeen: Date = Date(),
        isConnected: Bool = false,
        displayName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.peripheralIdentifier = peripheralIdentifier
        self.leftBattery = leftBattery
        self.rightBattery = rightBattery
        self.lastSeen = lastSeen
        self.isConnected = isConnected
        self.displayName = displayName
    }
}
