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

    /// Creates a rendered NSImage of the app's bat icon using the current disconnected icon settings.
    /// - Returns: An `NSImage` containing the bat icon sized for the menu bar, or `nil` if rendering fails. The returned image preserves the icon's original colors (not a template).
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

    /// Renders the standard menu bar label for a connected keyboard, showing an optional icon and the formatted battery string.
    /// - Parameters:
    ///   - keyboard: The keyboard whose battery values are used to produce the display string.
    /// - Returns: A view containing an optional SF Symbol icon (from settings.menuBarIcon) and the keyboard's formatted battery text with monospaced digits.

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

    /// Format the standard battery display string for a keyboard according to the current app settings.
    /// - Parameter keyboard: The keyboard whose left and right battery percentages are used.
    /// - Returns: A formatted string based on `settings.displayFormat`:
    ///   - `.percentage`: "left{suffix}{separator}right" with `--` for missing sides.
    ///   - `.leftOnly`: left value or `--`.
    ///   - `.rightOnly`: right value or `--`.
    ///   - `.lowest`: the lower of left/right or `--`.
    ///   The `suffix` is "%" when `settings.showPercentSymbol` is true, otherwise empty.
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

    /// Renders the keyboard battery display using the user-selected experimental text format.
    /// - Parameters:
    ///   - keyboard: The keyboard whose left and right battery percentages are used for formatting.
    /// - Returns: A view showing the battery state formatted according to `settings.experimentalFormat` (pipes, blocks, bracketed, arrows, or slashes).

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

    /// Format optional left and right battery percentages as pipe-delimited tokens.
    /// - Parameters:
    ///   - left: Left battery percentage, or `nil` if unavailable.
    ///   - right: Right battery percentage, or `nil` if unavailable.
    /// - Returns: A string in the form `"|L| |R|"` where `L`/`R` are the percentages or `"--"` when missing.
    private func pipesFormat(left: Int?, right: Int?) -> String {
        let l = left.map { "|\($0)|" } ?? "|--|"
        let r = right.map { "|\($0)|" } ?? "|--|"
        return "\(l) \(r)"
    }

    /// Formats left and right battery percentages as two 5-character block progress bars separated by a space.
    /// - Parameters:
    ///   - left: Optional percentage (0–100) for the left battery; if `nil`, treated as 0.
    ///   - right: Optional percentage (0–100) for the right battery; if `nil`, treated as 0.
    /// - Returns: A string containing two 5-character block progress bars (left and right) separated by a space.
    private func blocksFormat(left: Int?, right: Int?) -> String {
        let leftBar = progressBar(for: left ?? 0)
        let rightBar = progressBar(for: right ?? 0)
        return "\(leftBar) \(rightBar)"
    }

    /// Create a 5-character progress bar visual representing a percentage.
    /// - Parameters:
    ///   - percentage: The percentage value to represent (expected 0–100). Values outside this range may produce bars with all filled or all empty segments after rounding.
    /// - Returns: A 5-character string composed of filled blocks (`▰`) and empty blocks (`▱`) where the number of filled blocks is the percentage rounded to the nearest segment.
    private func progressBar(for percentage: Int) -> String {
        let total = 5
        let filled = Int(round(Double(percentage) / 100.0 * Double(total)))
        let empty = total - filled
        let filledStr = String(repeating: "▰", count: filled)
        let emptyStr = String(repeating: "▱", count: empty)
        return "\(filledStr)\(emptyStr)"
    }

    /// Formats left and right battery percentages into a bracketed representation.
    /// - Parameters:
    ///   - left: The left battery percentage, or `nil` if unavailable.
    ///   - right: The right battery percentage, or `nil` if unavailable.
    /// - Returns: A string in the form "[L:<left>|R:<right>]" where missing values are represented by `"--"`.
    private func bracketedFormat(left: Int?, right: Int?) -> String {
        let l = left.map { "\($0)" } ?? "--"
        let r = right.map { "\($0)" } ?? "--"
        return "[L:\(l)|R:\(r)]"
    }

    /// Formats left and right battery percentages using an arrow separator.
    /// - Parameters:
    ///   - left: The left battery percentage, or `nil` if unknown.
    ///   - right: The right battery percentage, or `nil` if unknown.
    /// - Returns: A string in the form "`L › R`" where `L` and `R` are the numeric percentages or `"--"` when missing.
    private func arrowsFormat(left: Int?, right: Int?) -> String {
        let l = left.map { "\($0)" } ?? "--"
        let r = right.map { "\($0)" } ?? "--"
        return "\(l) › \(r)"
    }

    /// Format left and right battery percentages as a slash-separated string.
    /// - Parameters:
    ///   - left: The left battery percentage, or `nil` if unknown (represented as "`--`").
    ///   - right: The right battery percentage, or `nil` if unknown (represented as "`--`").
    /// - Returns: A string in the form `"<left>/<right>"` where missing values are shown as `--`.
    private func slashesFormat(left: Int?, right: Int?) -> String {
        let l = left.map { "\($0)" } ?? "--"
        let r = right.map { "\($0)" } ?? "--"
        return "\(l)/\(r)"
    }
}