import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }

            DisplaySettingsView()
                .tabItem {
                    Label("Display", systemImage: "menubar.rectangle")
                }

            NotificationSettingsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }

            KeyboardsSettingsView()
                .tabItem {
                    Label("Keyboards", systemImage: "keyboard")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 520)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { LaunchAtLogin.isEnabled },
            set: { LaunchAtLogin.isEnabled = $0 }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: launchAtLoginBinding)
                Toggle("Auto-reconnect to keyboard", isOn: $preferencesManager.settings.autoReconnect)
            }

            Section("Battery Check Interval") {
                Slider(
                    value: $preferencesManager.settings.pollingInterval,
                    in: AppConstants.minPollingInterval...AppConstants.maxPollingInterval,
                    step: 10
                ) {
                    Text("Interval")
                } minimumValueLabel: {
                    Text("10s")
                } maximumValueLabel: {
                    Text("5m")
                }

                Text("Check every \(Int(preferencesManager.settings.pollingInterval)) seconds")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Stepper(
                    "Max reconnect attempts: \(preferencesManager.settings.maxReconnectAttempts)",
                    value: $preferencesManager.settings.maxReconnectAttempts,
                    in: 1...20
                )

                Toggle("Enable debug logging", isOn: $preferencesManager.settings.enableDebugLogging)
            }

            Section {
                Button("Reset to Defaults") {
                    preferencesManager.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @ObservedObject private var themeRegistry = ThemeRegistry.shared
    @State private var showingThemeEditor = false
    @State private var editingTheme: ConfigurableTheme?

    private var currentTheme: any ColorTheme {
        themeRegistry.theme(for: preferencesManager.settings.colorThemeId)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Live Preview at the top
            LayoutThemePreview(
                layout: preferencesManager.settings.menuLayout,
                theme: currentTheme
            )
            .padding()
            .background(Color(nsColor: .textBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Layout Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Layout")
                            .font(.headline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(MenuLayout.allCases) { layout in
                                LayoutCard(
                                    layout: layout,
                                    isSelected: preferencesManager.settings.menuLayout == layout
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        preferencesManager.settings.menuLayout = layout
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    // Theme Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Color Theme")
                                .font(.headline)

                            Spacer()

                            Button {
                                if let url = URL(string: "https://github.com/PapaniaP/bat-mon#custom-themes") {
                                    NSWorkspace.shared.open(url)
                                }
                            } label: {
                                Image(systemName: "questionmark.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Open theme documentation")
                        }

                        if !preferencesManager.settings.menuLayout.usesFullThemePalette {
                            Text("(affects battery & status colors)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(themeRegistry.allThemes, id: \.id) { theme in
                                ThemeCard(
                                    theme: theme,
                                    isSelected: preferencesManager.settings.colorThemeId == theme.id,
                                    isCustom: themeRegistry.isCustom(theme.id)
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        preferencesManager.settings.colorThemeId = theme.id
                                    }
                                } onEdit: {
                                    if let customTheme = themeRegistry.customThemes.first(where: { $0.id == theme.id }) {
                                        editingTheme = customTheme
                                        showingThemeEditor = true
                                    }
                                }
                            }

                            // Show invalid themes with error state
                            ForEach(themeRegistry.invalidThemes) { invalid in
                                InvalidThemeCard(theme: invalid)
                            }
                        }

                        // Add New Theme button
                        Button {
                            editingTheme = nil
                            showingThemeEditor = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create New Theme")
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, 4)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingThemeEditor) {
            ThemeEditorSheet(
                editingTheme: editingTheme,
                themeRegistry: themeRegistry,
                preferencesManager: preferencesManager
            )
        }
        .onAppear {
            // Reload themes in case the user edited themes.json directly
            themeRegistry.reloadCustomThemes()
        }
    }
}

// MARK: - Layout + Theme Preview

struct LayoutThemePreview: View {
    let layout: MenuLayout
    let theme: any ColorTheme

    var body: some View {
        VStack(spacing: 8) {
            Text("Preview")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Group {
                switch layout {
                case .native:
                    NativePreviewMini(theme: theme)
                case .rich:
                    RichPreviewMini(theme: theme)
                case .minimal:
                    MinimalPreviewMini(theme: theme)
                case .tui:
                    TUIPreviewMini(theme: theme)
                }
            }
            .frame(maxWidth: 220)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
    }
}

// MARK: - Preview Mini Views

struct NativePreviewMini: View {
    let theme: any ColorTheme

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 10))
                Text("Keyboard")
                    .font(.system(size: 10, weight: .semibold))
                Spacer()
                Circle().fill(theme.success).frame(width: 6, height: 6)
            }

            HStack(spacing: 16) {
                MiniArcGauge(percentage: 85, label: "L", color: theme.batteryColor(for: 85))
                MiniArcGauge(percentage: 92, label: "R", color: theme.batteryColor(for: 92))
            }

            Text("Updated just now")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(.ultraThinMaterial)
    }
}

struct MiniArcGauge: View {
    let percentage: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(percentage)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .frame(width: 32, height: 32)
            Text(label)
                .font(.system(size: 7))
                .foregroundStyle(.secondary)
        }
    }
}

struct RichPreviewMini: View {
    let theme: any ColorTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Keyboard")
                    .font(.system(size: 10, weight: .semibold))
                Spacer()
                Text("Connected")
                    .font(.system(size: 7))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(theme.success.opacity(0.2))
                    .cornerRadius(4)
            }

            MiniHorizontalBar(label: "Left", percentage: 85, color: theme.batteryColor(for: 85))
            MiniHorizontalBar(label: "Right", percentage: 92, color: theme.batteryColor(for: 92))
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct MiniHorizontalBar: View {
    let label: String
    let percentage: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 8))
                Spacer()
                Text("\(percentage)%")
                    .font(.system(size: 8, weight: .medium))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.gradient)
                        .frame(width: geo.size.width * CGFloat(percentage) / 100)
                }
            }
            .frame(height: 5)
        }
    }
}

struct MinimalPreviewMini: View {
    let theme: any ColorTheme

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                HStack(spacing: 2) {
                    Text("L")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                    Text("85%")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.batteryColor(for: 85))
                }
                HStack(spacing: 2) {
                    Text("R")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                    Text("92%")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.batteryColor(for: 92))
                }
            }
            Divider()
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise").font(.system(size: 8))
                Spacer()
                Image(systemName: "gear").font(.system(size: 8))
                Image(systemName: "power").font(.system(size: 8))
            }
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct TUIPreviewMini: View {
    let theme: any ColorTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("bat-mon")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.accent)

            HStack {
                Text("Keyboard")
                    .foregroundStyle(theme.foreground)
                Spacer()
                Text("●")
                    .foregroundStyle(theme.success)
            }

            Divider().background(theme.divider)

            Text("LEFT  ━━━━━━━━── 85%")
                .foregroundStyle(theme.foreground)
            Text("RIGHT ━━━━━━━━━─ 92%")
                .foregroundStyle(theme.foreground)

            Divider().background(theme.divider)

            Text("~ refresh")
                .foregroundStyle(theme.accent)
        }
        .font(.system(size: 7, design: .monospaced))
        .padding(8)
        .background(theme.background)
    }
}

// MARK: - Layout Card

struct LayoutCard: View {
    let layout: MenuLayout
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(layout.displayName)
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }

                Text(layout.description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.03))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: any ColorTheme
    let isSelected: Bool
    var isCustom: Bool = false
    let action: () -> Void
    var onEdit: (() -> Void)? = nil

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Color swatch preview
                HStack(spacing: 3) {
                    Circle().fill(theme.success).frame(width: 14, height: 14)
                    Circle().fill(theme.warning).frame(width: 14, height: 14)
                    Circle().fill(theme.error).frame(width: 14, height: 14)
                    Circle().fill(theme.accent).frame(width: 14, height: 14)
                }

                Text(theme.name)
                    .font(.system(size: 12, weight: .medium))

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 14))
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.03))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                if isCustom, let onEdit = onEdit {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Invalid Theme Card

struct InvalidThemeCard: View {
    let theme: InvalidTheme
    @State private var showingPopover = false

    var body: some View {
        Button {
            showingPopover.toggle()
        } label: {
            VStack(spacing: 8) {
                // Warning icon instead of color swatches
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.orange)

                Text(theme.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Image(systemName: "questionmark.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPopover, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Invalid Theme")
                        .font(.headline)
                }

                Text("This theme is missing required color fields:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(theme.missingFields, id: \.self) { field in
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 12))
                        Text(field)
                            .font(.system(size: 12, design: .monospaced))
                    }
                }

                Divider()

                Text("Edit themes.json to fix this theme.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(minWidth: 200)
        }
    }
}

// MARK: - Theme Editor Sheet

struct ThemeEditorSheet: View {
    let editingTheme: ConfigurableTheme?
    @ObservedObject var themeRegistry: ThemeRegistry
    @ObservedObject var preferencesManager: PreferencesManager
    @Environment(\.dismiss) private var dismiss

    @State private var themeName: String = ""
    @State private var backgroundColor: Color = Color(hex: "#1a1b26")
    @State private var textColor: Color = Color(hex: "#c0caf5")
    @State private var accentColor: Color = Color(hex: "#7aa2f7")
    @State private var healthyColor: Color = Color(hex: "#9ece6a")
    @State private var warningColor: Color = Color(hex: "#e0af68")
    @State private var alertColor: Color = Color(hex: "#f7768e")

    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?

    private var isEditing: Bool { editingTheme != nil }

    private var previewTheme: ConfigurableTheme {
        ConfigurableTheme(
            name: themeName.isEmpty ? "Preview" : themeName,
            background: backgroundColor,
            foreground: textColor,
            accent: accentColor,
            success: healthyColor,
            warning: warningColor,
            error: alertColor
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Text(isEditing ? "Edit Theme" : "New Theme")
                    .font(.headline)

                Spacer()

                Button(isEditing ? "Save" : "Create") {
                    saveTheme()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(themeName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()

            Divider()

            // Live Preview
            TUIPreviewMini(theme: previewTheme)
                .frame(maxWidth: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding()

            Divider()

            // Editor Form
            Form {
                Section("Theme Name") {
                    TextField("Name", text: $themeName)
                }

                Section("Colors") {
                    ColorPicker("Background", selection: $backgroundColor)
                    ColorPicker("Text", selection: $textColor)
                    ColorPicker("Accent", selection: $accentColor)
                    ColorPicker("Healthy (>40%)", selection: $healthyColor)
                    ColorPicker("Warning (21-40%)", selection: $warningColor)
                    ColorPicker("Alert (≤20%)", selection: $alertColor)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                if isEditing {
                    Section {
                        Button("Delete Theme", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 550)
        .onAppear {
            if let theme = editingTheme {
                themeName = theme.name
                backgroundColor = theme.background
                textColor = theme.foreground
                accentColor = theme.accent
                healthyColor = theme.success
                warningColor = theme.warning
                alertColor = theme.error
            }
        }
        .alert("Delete Theme?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTheme()
            }
        } message: {
            Text("This will permanently remove \"\(editingTheme?.name ?? "")\" from your themes.")
        }
    }

    /// Validates the theme name, constructs a configurable theme from the editor fields, and persists it.
    /// 
    /// If the trimmed theme name is empty, sets `errorMessage` to `"Theme name cannot be empty"` and returns.
    /// On successful save, sets the saved theme as the current color theme in `preferencesManager.settings.colorThemeId` and calls `dismiss()`.
    /// On failure, sets `errorMessage` to `"Failed to save theme: <localized error description>"`.
    private func saveTheme() {
        let trimmedName = themeName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Theme name cannot be empty"
            return
        }

        let newTheme = ConfigurableTheme(
            name: trimmedName,
            background: backgroundColor,
            foreground: textColor,
            accent: accentColor,
            success: healthyColor,
            warning: warningColor,
            error: alertColor
        )

        do {
            try themeRegistry.saveCustomTheme(newTheme)
            // Select the newly created/updated theme
            preferencesManager.settings.colorThemeId = newTheme.id
            dismiss()
        } catch {
            errorMessage = "Failed to save theme: \(error.localizedDescription)"
        }
    }

    /// Deletes the currently edited custom theme and closes the editor.
    /// 
    /// If the edited theme is the active selection, this switches the selected theme to `"system"` before attempting removal. On successful deletion the theme is removed from the theme registry and the sheet is dismissed. If deletion fails, an explanatory message is stored in `errorMessage`.
    private func deleteTheme() {
        guard let theme = editingTheme else { return }

        do {
            // If this theme is selected, switch to System first
            if preferencesManager.settings.colorThemeId == theme.id {
                preferencesManager.settings.colorThemeId = "system"
            }
            try themeRegistry.removeCustomTheme(withId: theme.id)
            dismiss()
        } catch {
            errorMessage = "Failed to delete theme: \(error.localizedDescription)"
        }
    }
}

// MARK: - Display Settings

struct DisplaySettingsView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    @State private var showingIconPicker = false

    private var previewText: String? {
        let settings = preferencesManager.settings

        // Compact mode shows icon only - no text preview
        if settings.compactMode {
            return nil
        }

        if settings.useExperimentalFormat {
            return settings.experimentalFormat.example
        }

        let suffix = settings.showPercentSymbol ? "%" : ""

        switch settings.displayFormat {
        case .percentage:
            return "85\(suffix)\(settings.separator)90\(suffix)"
        case .leftOnly:
            return "85\(suffix)"
        case .rightOnly:
            return "90\(suffix)"
        case .lowest:
            return "85\(suffix)"
        }
    }


    var body: some View {
        Form {
            // Live Preview
            Section {
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        // Show icon based on mode
                        if preferencesManager.settings.compactMode {
                            let iconName = preferencesManager.settings.compactIcon == .custom
                                ? preferencesManager.settings.customCompactIcon
                                : preferencesManager.settings.compactIcon.sfSymbolName
                            Image(systemName: iconName)
                        } else if let iconName = preferencesManager.settings.menuBarIcon.sfSymbolName {
                            Image(systemName: iconName)
                        }
                        if let text = previewText {
                            Text(text)
                                .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
                    Spacer()
                }
            } header: {
                Text("Preview")
            }

            // Compact Mode Section
            Section {
                Toggle("Compact Mode", isOn: $preferencesManager.settings.compactMode)

                if preferencesManager.settings.compactMode {
                    // Icon picker grid
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 44))
                    ], spacing: 8) {
                        // Preset icons (excluding .custom)
                        ForEach(CompactModeIcon.allCases.filter { $0 != .custom }) { icon in
                            Button(action: {
                                preferencesManager.settings.compactIcon = icon
                            }) {
                                Image(systemName: icon.sfSymbolName)
                                    .font(.system(size: 18))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        preferencesManager.settings.compactIcon == icon
                                            ? Color.accentColor.opacity(0.2)
                                            : Color.gray.opacity(0.1)
                                    )
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                preferencesManager.settings.compactIcon == icon
                                                    ? Color.accentColor
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(icon.displayName)
                        }

                        // Custom icon button
                        Button(action: {
                            preferencesManager.settings.compactIcon = .custom
                            showingIconPicker = true
                        }) {
                            ZStack {
                                if preferencesManager.settings.compactIcon == .custom {
                                    Image(systemName: preferencesManager.settings.customCompactIcon)
                                        .font(.system(size: 18))
                                } else {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 18))
                                }
                            }
                            .frame(width: 40, height: 40)
                            .background(
                                preferencesManager.settings.compactIcon == .custom
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.gray.opacity(0.1)
                            )
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        preferencesManager.settings.compactIcon == .custom
                                            ? Color.accentColor
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Custom icon")
                    }
                    .padding(.vertical, 4)

                    // Show "Change" button if custom is selected
                    if preferencesManager.settings.compactIcon == .custom {
                        Button("Change Custom Icon...") {
                            showingIconPicker = true
                        }
                        .font(.caption)
                    }
                }
            } header: {
                Text("Compact Mode")
            } footer: {
                Text("Shows only an icon in the menu bar. Battery info appears when you click it.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Icon") {
                Picker("Menu Bar Icon", selection: $preferencesManager.settings.menuBarIcon) {
                    ForEach(MenuBarIcon.allCases) { icon in
                        HStack(spacing: 8) {
                            if let sfName = icon.sfSymbolName {
                                Image(systemName: sfName)
                                    .frame(width: 20)
                            } else {
                                Text("—")
                                    .frame(width: 20)
                            }
                            Text(icon.displayName)
                        }
                        .tag(icon)
                    }
                }
                .pickerStyle(.radioGroup)
            }
            .disabled(preferencesManager.settings.compactMode || preferencesManager.settings.useExperimentalFormat)

            Section("Format") {
                Picker("Display Format", selection: $preferencesManager.settings.displayFormat) {
                    ForEach(DisplayFormat.allCases) { format in
                        VStack(alignment: .leading) {
                            Text(format.displayName)
                        }
                        .tag(format)
                    }
                }
                .pickerStyle(.radioGroup)

                Toggle("Show % symbol", isOn: $preferencesManager.settings.showPercentSymbol)
            }
            .disabled(preferencesManager.settings.compactMode || preferencesManager.settings.useExperimentalFormat)

            Section("Separator") {
                Picker("Separator", selection: $preferencesManager.settings.separator) {
                    ForEach(SeparatorOption.allCases) { option in
                        Text(option.displayName)
                            .tag(option.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
            .disabled(preferencesManager.settings.compactMode || preferencesManager.settings.useExperimentalFormat)

            // Experimental Section
            Section {
                Toggle("Enable Experimental Format", isOn: $preferencesManager.settings.useExperimentalFormat)

                if preferencesManager.settings.useExperimentalFormat {
                    Picker("Style", selection: $preferencesManager.settings.experimentalFormat) {
                        ForEach(ExperimentalFormat.allCases) { format in
                            HStack {
                                Text(format.displayName)
                                Spacer()
                                Text(format.example)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .tag(format)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }
            } header: {
                HStack {
                    Text("Experimental")
                    Text("⚗️")
                }
            } footer: {
                Text("Visual styles that may not work perfectly on all systems.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .disabled(preferencesManager.settings.compactMode)

            // Disconnected Icon Customization
            Section {
                // Preview
                HStack {
                    Spacer()
                    BatIconView(
                        fillColor: Color(hex: preferencesManager.settings.disconnectedIconFillHex),
                        borderColor: preferencesManager.settings.disconnectedIconBorderEnabled
                            ? Color(hex: preferencesManager.settings.disconnectedIconBorderHex)
                            : nil
                    )
                    .scaleEffect(2.0)
                    .frame(width: 50, height: 35)
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.8))
                .cornerRadius(6)

                // Fill color picker
                ColorPicker(
                    "Icon Color",
                    selection: Binding(
                        get: { Color(hex: preferencesManager.settings.disconnectedIconFillHex) },
                        set: { preferencesManager.settings.disconnectedIconFillHex = $0.toHex() }
                    )
                )

                // Border toggle and color
                Toggle("Show Border", isOn: $preferencesManager.settings.disconnectedIconBorderEnabled)

                if preferencesManager.settings.disconnectedIconBorderEnabled {
                    ColorPicker(
                        "Border Color",
                        selection: Binding(
                            get: { Color(hex: preferencesManager.settings.disconnectedIconBorderHex) },
                            set: { preferencesManager.settings.disconnectedIconBorderHex = $0.toHex() }
                        )
                    )
                }
            } header: {
                Text("Disconnected Icon")
            } footer: {
                Text("Customize the bat icon shown when no keyboard is connected.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showingIconPicker) {
            SFSymbolPicker(selectedSymbol: $preferencesManager.settings.customCompactIcon)
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager

    var body: some View {
        Form {
            Section {
                Toggle("Enable battery notifications", isOn: $preferencesManager.settings.enableNotifications)
            }

            Section("Alert Thresholds") {
                VStack(alignment: .leading) {
                    Text("Low Battery Threshold: \(preferencesManager.settings.lowBatteryThreshold)%")

                    Slider(
                        value: Binding(
                            get: { Double(preferencesManager.settings.lowBatteryThreshold) },
                            set: { preferencesManager.settings.lowBatteryThreshold = Int($0) }
                        ),
                        in: Double(AppConstants.minBatteryThreshold)...Double(AppConstants.maxBatteryThreshold),
                        step: 5
                    )
                }

                VStack(alignment: .leading) {
                    Text("Critical Battery Threshold: \(preferencesManager.settings.criticalBatteryThreshold)%")

                    Slider(
                        value: Binding(
                            get: { Double(preferencesManager.settings.criticalBatteryThreshold) },
                            set: { preferencesManager.settings.criticalBatteryThreshold = Int($0) }
                        ),
                        in: Double(AppConstants.minBatteryThreshold)...Double(preferencesManager.settings.lowBatteryThreshold),
                        step: 5
                    )
                }
            }
            .disabled(!preferencesManager.settings.enableNotifications)

            Section {
                Button("Test Notification") {
                    NotificationManager.shared.sendTestNotification()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Keyboards Settings

struct KeyboardsSettingsView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var preferencesManager: PreferencesManager

    var body: some View {
        Form {
            Section("Selected Keyboard") {
                if let keyboard = bluetoothManager.selectedKeyboard {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(keyboard.effectiveName)
                                .font(.headline)

                            Text("ID: \(keyboard.peripheralIdentifier.uuidString.prefix(8))...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Circle()
                            .fill(bluetoothManager.connectionState.isConnected ? .green : .gray)
                            .frame(width: 10, height: 10)
                    }

                    Button("Forget Keyboard") {
                        preferencesManager.clearSelectedKeyboard()
                        bluetoothManager.disconnect()
                    }
                } else {
                    Text("No keyboard selected")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button(bluetoothManager.isScanning ? "Stop Scanning" : "Scan for Keyboards") {
                    if bluetoothManager.isScanning {
                        bluetoothManager.stopScanning()
                    } else {
                        bluetoothManager.startScanning()
                    }
                }

                if !bluetoothManager.availableKeyboards.isEmpty {
                    ForEach(bluetoothManager.availableKeyboards) { keyboard in
                        Button(action: { bluetoothManager.selectKeyboard(keyboard) }) {
                            HStack {
                                Image(systemName: "keyboard")
                                Text(keyboard.name)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "keyboard")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text(AppInfo.appName)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Version \(AppInfo.version)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("ZMK Keyboard Battery Monitor")
                .font(.subheadline)

            Divider()
                .padding(.vertical)

            Text("A reliable, open-source battery monitor for ZMK split keyboards.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Link("View on GitHub", destination: URL(string: AppInfo.githubURL)!)
                .font(.caption)

            Spacer()

            Text("MIT License")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}