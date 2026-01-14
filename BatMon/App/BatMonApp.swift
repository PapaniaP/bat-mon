import SwiftUI
import AppKit

@main
struct BatMonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var preferencesManager = PreferencesManager.shared

    init() {
        // Initialize default themes.json if it doesn't exist
        ThemeRegistry.shared.initializeDefaultThemesIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(bluetoothManager)
                .environmentObject(preferencesManager)
        } label: {
            MenuBarLabel(bluetoothManager: bluetoothManager, preferencesManager: preferencesManager)
                .id("menubar-\(preferencesManager.settings.displayFormat.rawValue)-\(preferencesManager.settings.compactMode)-\(preferencesManager.settings.useExperimentalFormat)-\(preferencesManager.settings.experimentalFormat.rawValue)")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(bluetoothManager)
                .environmentObject(preferencesManager)
        }
    }
}

struct MenuBarLabel: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @ObservedObject var preferencesManager: PreferencesManager

    private var settings: AppSettings { preferencesManager.settings }

    var body: some View {
        if settings.compactMode {
            // Compact mode: icon only
            let iconName = settings.compactIcon == .custom ? settings.customCompactIcon : settings.compactIcon.sfSymbolName
            Image(systemName: iconName)
        } else if let keyboard = bluetoothManager.selectedKeyboard,
           bluetoothManager.connectionState.isConnected {
            if settings.useExperimentalFormat {
                experimentalView(keyboard: keyboard)
            } else {
                standardView(keyboard: keyboard)
            }
        } else {
            // Disconnected state: show custom bat icon with user colors
            // MenuBarExtra requires Image, so we render the shape to an image
            if let nsImage = renderBatIcon() {
                Image(nsImage: nsImage)
            } else {
                Image(systemName: "keyboard.badge.ellipsis")
            }
        }
    }

    private func renderBatIcon() -> NSImage? {
        let batView = BatIconView(
            fillColor: Color(hex: settings.disconnectedIconFillHex),
            borderColor: settings.disconnectedIconBorderEnabled ? Color(hex: settings.disconnectedIconBorderHex) : nil
        )

        let renderer = ImageRenderer(content: batView)
        renderer.scale = 2.0  // Retina

        guard let cgImage = renderer.cgImage else { return nil }

        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width / 2, height: cgImage.height / 2))
        nsImage.isTemplate = false  // Keep original colors
        return nsImage
    }

    // MARK: - Standard View

    @ViewBuilder
    private func standardView(keyboard: ZMKKeyboard) -> some View {
        HStack(spacing: 4) {
            if let iconName = settings.menuBarIcon.sfSymbolName {
                Image(systemName: iconName)
            }
            Text(formatStandardDisplay(keyboard: keyboard))
                .monospacedDigit()
        }
    }

    private func formatStandardDisplay(keyboard: ZMKKeyboard) -> String {
        let left = keyboard.leftBattery?.percentage
        let right = keyboard.rightBattery?.percentage
        let suffix = settings.showPercentSymbol ? "%" : ""

        switch settings.displayFormat {
        case .percentage:
            let leftStr = left.map { "\($0)\(suffix)" } ?? "--"
            let rightStr = right.map { "\($0)\(suffix)" } ?? "--"
            return "\(leftStr)\(settings.separator)\(rightStr)"

        case .leftOnly:
            return left.map { "\($0)\(suffix)" } ?? "--"

        case .rightOnly:
            return right.map { "\($0)\(suffix)" } ?? "--"

        case .lowest:
            let lowest = [left, right].compactMap { $0 }.min()
            return lowest.map { "\($0)\(suffix)" } ?? "--"
        }
    }

    // MARK: - Experimental Views

    @ViewBuilder
    private func experimentalView(keyboard: ZMKKeyboard) -> some View {
        let left = keyboard.leftBattery?.percentage
        let right = keyboard.rightBattery?.percentage

        switch settings.experimentalFormat {
        case .pipes:
            Text(pipesFormat(left: left, right: right))
                .monospacedDigit()

        case .blocks:
            Text(blocksFormat(left: left, right: right))
                .font(.system(size: 11, design: .monospaced))

        case .bracketed:
            Text(bracketedFormat(left: left, right: right))
                .monospacedDigit()

        case .arrows:
            Text(arrowsFormat(left: left, right: right))
                .monospacedDigit()

        case .slashes:
            Text(slashesFormat(left: left, right: right))
                .monospacedDigit()
        }
    }

    // Pipes: |85| |90|
    private func pipesFormat(left: Int?, right: Int?) -> String {
        let l = left.map { "|\($0)|" } ?? "|--|"
        let r = right.map { "|\($0)|" } ?? "|--|"
        return "\(l) \(r)"
    }

    // Progress bars: ▰▰▰▰▱ ▰▰▰▱▱
    private func blocksFormat(left: Int?, right: Int?) -> String {
        let leftBar = left.map { progressBar(for: $0) } ?? "-----"
        let rightBar = right.map { progressBar(for: $0) } ?? "-----"
        return "\(leftBar) \(rightBar)"
    }

    private func progressBar(for percentage: Int) -> String {
        let total = 5
        let filled = Int(round(Double(percentage) / 100.0 * Double(total)))
        let empty = total - filled
        let filledStr = String(repeating: "▰", count: filled)
        let emptyStr = String(repeating: "▱", count: empty)
        return "\(filledStr)\(emptyStr)"
    }

    // Bracketed: [L:85|R:90]
    private func bracketedFormat(left: Int?, right: Int?) -> String {
        let l = left.map { "\($0)" } ?? "--"
        let r = right.map { "\($0)" } ?? "--"
        return "[L:\(l)|R:\(r)]"
    }

    // Arrows: 85 › 90
    private func arrowsFormat(left: Int?, right: Int?) -> String {
        let l = left.map { "\($0)" } ?? "--"
        let r = right.map { "\($0)" } ?? "--"
        return "\(l) › \(r)"
    }

    // Slashes: 85/90
    private func slashesFormat(left: Int?, right: Int?) -> String {
        let l = left.map { "\($0)" } ?? "--"
        let r = right.map { "\($0)" } ?? "--"
        return "\(l)/\(r)"
    }
}
