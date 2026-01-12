import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
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
        .frame(width: 480, height: 440)
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
