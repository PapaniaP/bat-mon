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
        .frame(width: 450, height: 320)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var preferencesManager: PreferencesManager

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $preferencesManager.settings.launchAtLogin)
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

    var body: some View {
        Form {
            Section("Menu Bar Icon") {
                Picker("Icon", selection: $preferencesManager.settings.menuBarIcon) {
                    ForEach(MenuBarIcon.allCases) { icon in
                        HStack {
                            if icon != .none {
                                Image(systemName: icon.sfSymbolName)
                            }
                            Text(icon.displayName)
                        }
                        .tag(icon)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Display Format") {
                Picker("Format", selection: $preferencesManager.settings.displayFormat) {
                    ForEach(DisplayFormat.allCases) { format in
                        Text(format.displayName)
                            .tag(format)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Separator") {
                TextField("Separator", text: $preferencesManager.settings.separator)
                    .frame(width: 80)

                Text("Preview: 85%\(preferencesManager.settings.separator)90%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
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
