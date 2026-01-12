import SwiftUI

struct SFSymbolPicker: View {
    @Binding var selectedSymbol: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    // Curated list of useful SF Symbols for a menu bar app
    private let symbols: [String] = [
        // Keyboards & Input
        "keyboard", "keyboard.fill", "keyboard.badge.ellipsis",

        // Battery & Power
        "battery.100", "battery.75", "battery.50", "battery.25", "battery.0",
        "battery.100.bolt", "bolt.fill", "bolt.circle", "bolt.circle.fill",
        "powerplug", "powerplug.fill", "plug.fill",

        // Tech & Hardware
        "cpu", "cpu.fill", "memorychip", "memorychip.fill",
        "server.rack", "externaldrive", "externaldrive.fill",
        "desktopcomputer", "laptopcomputer", "display",
        "antenna.radiowaves.left.and.right", "wifi", "network",

        // Connectivity
        "link", "link.circle", "link.circle.fill",
        "personalhotspot", "bluetooth", "dot.radiowaves.left.and.right",

        // Shapes
        "circle.fill", "square.fill", "triangle.fill",
        "diamond.fill", "hexagon.fill", "pentagon.fill",
        "star.fill", "star.circle.fill",
        "heart.fill", "heart.circle.fill",

        // Indicators
        "checkmark.circle.fill", "xmark.circle.fill",
        "exclamationmark.triangle.fill", "info.circle.fill",
        "bell.fill", "bell.badge.fill",
        "flag.fill", "bookmark.fill",

        // Gauges & Meters
        "gauge", "gauge.high", "gauge.low",
        "speedometer", "barometer",
        "chart.bar.fill", "chart.pie.fill",

        // Misc Tech
        "gearshape.fill", "wrench.fill", "hammer.fill",
        "terminal.fill", "chevron.left.forwardslash.chevron.right",
        "curlybraces", "number",

        // Nature & Objects
        "leaf.fill", "flame.fill", "drop.fill",
        "snowflake", "sun.max.fill", "moon.fill",
        "cloud.fill", "bolt.horizontal.fill",

        // Arrows & Navigation
        "arrow.up.circle.fill", "arrow.down.circle.fill",
        "arrow.left.arrow.right", "arrow.triangle.2.circlepath",
        "repeat", "shuffle",

        // Communication
        "envelope.fill", "message.fill", "bubble.left.fill",
        "phone.fill", "video.fill",

        // Media
        "play.fill", "pause.fill", "stop.fill",
        "speaker.wave.2.fill", "music.note",

        // Security
        "lock.fill", "lock.open.fill", "key.fill",
        "shield.fill", "checkmark.shield.fill"
    ]

    private var filteredSymbols: [String] {
        if searchText.isEmpty {
            return symbols
        }
        return symbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Choose Icon")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            // Search
            TextField("Search symbols...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.bottom, 8)

            Divider()

            // Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button(action: {
                            selectedSymbol = symbol
                        }) {
                            Image(systemName: symbol)
                                .font(.system(size: 22))
                                .frame(width: 44, height: 44)
                                .background(
                                    selectedSymbol == symbol
                                        ? Color.accentColor.opacity(0.2)
                                        : Color.gray.opacity(0.1)
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            selectedSymbol == symbol
                                                ? Color.accentColor
                                                : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .help(symbol)
                    }
                }
                .padding()
            }
        }
        .frame(width: 360, height: 420)
    }
}
