import Foundation

enum KeyboardHalf: String, Codable, CaseIterable, Identifiable {
    case left = "Left"
    case right = "Right"

    var id: String { rawValue }
}
