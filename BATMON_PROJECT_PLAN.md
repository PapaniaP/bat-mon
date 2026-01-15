# 🦇 BatMon - Project Plan & Architecture

> A reliable, polished macOS menu bar app for monitoring ZMK split keyboard battery levels

**Version:** 1.0  
**Last Updated:** January 2026  
**Status:** Planning Phase  

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Problem Statement](#problem-statement)
3. [Core Requirements](#core-requirements)
4. [Technical Architecture](#technical-architecture)
5. [Project Structure](#project-structure)
6. [Data Models](#data-models)
7. [Core Managers](#core-managers)
8. [UI/UX Design](#uiux-design)
9. [Feature Roadmap](#feature-roadmap)
10. [Development Plan](#development-plan)
11. [Testing Strategy](#testing-strategy)
12. [Distribution](#distribution)
13. [Future Considerations](#future-considerations)

---

## Project Overview

### What is BatMon?

BatMon is a native macOS menu bar application that displays real-time battery levels for ZMK split keyboards. Unlike existing solutions, BatMon focuses on **reliability** and **user customization** while maintaining a clean, minimal interface.

### Key Differentiators

- ✅ **Reliable auto-reconnection** - No manual restarts needed
- ✅ **Persistent configuration** - Remembers your keyboard across sessions
- ✅ **Highly customizable** - User controls display style, icons, and behavior
- ✅ **Multiple keyboard support** - Easy switching between boards
- ✅ **Setup wizard** - Guided first-run experience
- ✅ **Open source** - MIT licensed on GitHub

### Target Users

- ZMK keyboard enthusiasts
- Split keyboard users
- Power users who want reliable battery monitoring
- Developers who prefer customization options

---

## Problem Statement

### Current Pain Points (from Mighty Mitts)

1. **Connection Issues**
   - Stops updating battery levels even when keyboard is connected
   - Loses connection and fails to reconnect
   - Requires manual app restart to resume monitoring

2. **No Persistence**
   - Doesn't remember selected keyboard between sessions
   - Must reconfigure after every app restart

3. **Limited Reliability**
   - Flip-flop left/right detection is fragile
   - No feedback when connection fails
   - No recovery mechanism

4. **Minimal Customization**
   - Fixed display format
   - No user preferences
   - One-size-fits-all approach

### BatMon Solutions

1. **Robust Connection Management**
   - Smart auto-reconnect with exponential backoff
   - Background scanning for lost keyboards
   - Clear connection state feedback
   - Automatic recovery without user intervention

2. **Complete Persistence**
   - Save keyboard selection to UserDefaults
   - Persist all user preferences
   - Restore full state on app launch
   - Characteristic mapping storage

3. **Enhanced Reliability**
   - Proper characteristic instance identification
   - Connection state monitoring
   - Comprehensive error handling
   - Extensive logging for debugging

4. **Full Customization**
   - Menu bar display options
   - Icon selection
   - Notification thresholds
   - Polling intervals
   - Launch behavior

---

## Core Requirements

### Must-Have (Phase 1 - MVP)

| Priority | Feature | Description |
|----------|---------|-------------|
| **1** | Auto-reconnect | Automatic reconnection without manual restart |
| **1** | Persistent selection | Remember keyboard between app sessions |
| **1** | Low battery alerts | Notifications at user-defined thresholds |
| **1** | Menu bar display | Show both keyboard halves' battery levels |
| **1** | Multiple keyboards | Support switching between different boards |
| **1** | Launch at login | Optional auto-start with macOS |
| **1** | Customizable polling | User-configurable update intervals |
| **1** | Better visual design | Clean, modern interface |

### Nice-to-Have (Phase 2+)

| Priority | Feature | Description |
|----------|---------|-------------|
| **2** | Setup wizard | Guided first-launch configuration |
| **3** | Battery history | Historical graphs and trends |
| **3** | Data export | Export battery data to CSV |
| **3** | Desktop widget | macOS widget support (future) |

---

## Technical Architecture

### Technology Stack

```text
Swift 5.9+
├── SwiftUI              # UI framework
├── Combine              # Reactive data flow
├── CoreBluetooth        # BLE communication
├── UserDefaults         # Preferences persistence
├── UserNotifications    # Battery alerts
└── SF Symbols           # System icons
```

### Architecture Pattern

**MVVM + Repository Pattern**

```
┌─────────────────────────────────────────┐
│         Menu Bar UI (SwiftUI)           │
│   [Icon] [Left: 85%] [Right: 90%]      │
└─────────────────┬───────────────────────┘
                  │
                  │ @Published properties
                  ▼
┌─────────────────────────────────────────┐
│           ViewModels                     │
│  • MenuBarViewModel                      │
│  • KeyboardSelectionViewModel            │
│  • SettingsViewModel                     │
└─────────────────┬───────────────────────┘
                  │
                  │ Business logic calls
                  ▼
┌─────────────────────────────────────────┐
│        Managers (Services)               │
│  • BluetoothManager                      │
│  • ConnectionManager                     │
│  • PreferencesManager                    │
│  • NotificationManager                   │
└─────────────────┬───────────────────────┘
                  │
                  │ Domain models
                  ▼
┌─────────────────────────────────────────┐
│            Models                        │
│  • ZMKKeyboard                           │
│  • BatteryLevel                          │
│  • KeyboardHalf                          │
│  • AppSettings                           │
└─────────────────────────────────────────┘
```

### Why This Architecture?

- **MVVM**: Natural fit for SwiftUI's reactive paradigm
- **Separation of Concerns**: Clear boundaries between UI, logic, and data
- **Testability**: ViewModels and Managers are easily unit-testable
- **Scalability**: Easy to add new features without touching existing code
- **Maintainability**: Single responsibility principle throughout

---

## Project Structure

```text
BatMon/
├── BatMon.xcodeproj
├── BatMon/
│   ├── App/
│   │   ├── BatMonApp.swift                    # SwiftUI App entry point
│   │   └── AppDelegate.swift                  # Menu bar setup & lifecycle
│   │
│   ├── Models/
│   │   ├── ZMKKeyboard.swift                  # Keyboard device model
│   │   ├── BatteryLevel.swift                 # Battery state representation
│   │   ├── KeyboardHalf.swift                 # Left/Right enum + logic
│   │   ├── AppSettings.swift                  # User preferences model
│   │   └── ConnectionState.swift              # Connection state enum
│   │
│   ├── Managers/
│   │   ├── BluetoothManager.swift             # CoreBluetooth wrapper
│   │   ├── ConnectionManager.swift            # Auto-reconnect logic
│   │   ├── PreferencesManager.swift           # UserDefaults persistence
│   │   └── NotificationManager.swift          # Battery alert system
│   │
│   ├── ViewModels/
│   │   ├── MenuBarViewModel.swift             # Menu bar state & logic
│   │   ├── KeyboardSelectionViewModel.swift   # Device picker logic
│   │   └── SettingsViewModel.swift            # Settings panel logic
│   │
│   ├── Views/
│   │   ├── MenuBar/
│   │   │   ├── MenuBarView.swift              # Main dropdown menu
│   │   │   ├── BatteryIndicatorView.swift     # Battery visualization
│   │   │   ├── StatusIconView.swift           # Menu bar icon
│   │   │   └── MenuBarDisplayStyle.swift      # Display customization
│   │   │
│   │   ├── KeyboardSelection/
│   │   │   ├── KeyboardListView.swift         # Available keyboards list
│   │   │   └── KeyboardRowView.swift          # Individual keyboard row
│   │   │
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift             # Main settings window
│   │   │   ├── GeneralSettingsView.swift      # General preferences
│   │   │   ├── DisplaySettingsView.swift      # Menu bar customization
│   │   │   ├── NotificationSettingsView.swift # Alert preferences
│   │   │   └── AboutView.swift                # About/credits
│   │   │
│   │   └── Setup/
│   │       ├── SetupWizardView.swift          # First-run wizard
│   │       ├── WelcomeView.swift              # Welcome screen
│   │       ├── PermissionView.swift           # Bluetooth permission
│   │       ├── KeyboardSelectionStep.swift    # Keyboard picker
│   │       └── ConfigurationView.swift        # Initial configuration
│   │
│   ├── Utilities/
│   │   ├── Constants.swift                    # App constants (UUIDs, defaults)
│   │   ├── Logger.swift                       # Logging wrapper
│   │   ├── Extensions/
│   │   │   ├── Color+App.swift                # App color palette
│   │   │   ├── CBPeripheral+Extensions.swift  # BLE helpers
│   │   │   └── View+Extensions.swift          # SwiftUI helpers
│   │   └── Helpers/
│   │       └── LaunchAtLogin.swift            # Login item management
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   │   ├── AppIcon.appiconset            # App icon
│   │   │   ├── MenuBarIcons/                  # Menu bar icon options
│   │   │   └── Colors/                        # Color assets
│   │   ├── Info.plist                         # App metadata
│   │   └── BatMon.entitlements               # Sandbox permissions
│   │
│   └── Supporting Files/
│       └── Localizable.strings                # Localization (future)
│
├── BatMonTests/                               # Unit tests
│   ├── BluetoothManagerTests.swift
│   ├── ConnectionManagerTests.swift
│   └── ViewModelTests.swift
│
├── README.md                                  # Project documentation
├── LICENSE                                    # MIT License
└── .gitignore                                # Git ignore rules
```

---

## Data Models

### 1. ZMKKeyboard.swift

**Purpose:** Represents a ZMK keyboard device with all its properties

```swift
import Foundation
import CoreBluetooth

struct ZMKKeyboard: Identifiable, Codable, Equatable {
    // Identification
    let id: UUID
    let name: String
    let peripheralIdentifier: UUID  // CBPeripheral.identifier for reconnection
    
    // Battery state
    var leftBattery: BatteryLevel?
    var rightBattery: BatteryLevel?
    
    // Connection tracking
    var lastSeen: Date
    var isConnected: Bool
    
    // User customization
    var displayName: String?        // Custom name (optional)
    var leftHalfLabel: String       // Default: "Left"
    var rightHalfLabel: String      // Default: "Right"
    
    // Characteristic mapping (for left/right identification)
    var characteristicMapping: [String: KeyboardHalf]
    
    // Computed properties
    var effectiveName: String {
        displayName ?? name
    }
    
    var lowestBatteryLevel: Int? {
        guard let left = leftBattery?.percentage,
              let right = rightBattery?.percentage else {
            return nil
        }
        return min(left, right)
    }
    
    var needsAttention: Bool {
        guard let lowest = lowestBatteryLevel else { return false }
        return lowest <= 20  // Below 20% needs attention
    }
}
```

### 2. BatteryLevel.swift

**Purpose:** Represents battery state for one keyboard half

```swift
import SwiftUI

struct BatteryLevel: Codable, Equatable {
    let percentage: Int         // 0-100
    let timestamp: Date
    var isCharging: Bool        // Future: detect charging state
    
    // Visual helpers
    var color: Color {
        switch percentage {
        case 0...10:  return .red
        case 11...20: return .orange
        case 21...50: return .yellow
        case 51...100: return .green
        default: return .gray
        }
    }
    
    var sfSymbolName: String {
        switch percentage {
        case 0...10:   return "battery.0"
        case 11...25:  return "battery.25"
        case 26...50:  return "battery.50"
        case 51...75:  return "battery.75"
        case 76...100: return "battery.100"
        default: return "battery.0"
        }
    }
    
    var visualBar: String {
        let filled = Int(Double(percentage) / 20.0)  // 5 segments
        let empty = 5 - filled
        return String(repeating: "█", count: filled) + 
               String(repeating: "░", count: empty)
    }
    
    var statusDescription: String {
        switch percentage {
        case 0...10:  return "Critical"
        case 11...20: return "Low"
        case 21...50: return "Fair"
        case 51...100: return "Good"
        default: return "Unknown"
        }
    }
}
```

### 3. KeyboardHalf.swift

**Purpose:** Represents left or right keyboard half

```swift
import Foundation

enum KeyboardHalf: String, Codable, CaseIterable, Identifiable {
    case left = "Left"
    case right = "Right"
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .left: return "⬅️"
        case .right: return "➡️"
        }
    }
    
    var abbreviation: String {
        switch self {
        case .left: return "L"
        case .right: return "R"
        }
    }
}
```

### 4. AppSettings.swift

**Purpose:** User preferences and configuration

```swift
import Foundation

struct AppSettings: Codable {
    // Display settings
    var menuBarIcon: MenuBarIcon = .keyboard
    var displayFormat: DisplayFormat = .percentageWithIcon
    var fontStyle: FontStyle = .system
    var useColorCoding: Bool = false
    var separator: String = " • "
    
    // Behavior settings
    var pollingInterval: TimeInterval = 60  // seconds
    var launchAtLogin: Bool = true
    var showDockIcon: Bool = false
    
    // Notification settings
    var enableNotifications: Bool = true
    var lowBatteryThreshold: Int = 20       // percent
    var criticalBatteryThreshold: Int = 10  // percent
    
    // Advanced
    var enableDebugLogging: Bool = false
    var autoReconnect: Bool = true
    var maxReconnectAttempts: Int = 10
}

enum MenuBarIcon: String, Codable, CaseIterable {
    case keyboard = "keyboard"
    case battery = "battery.100"
    case bolt = "bolt.fill"
    case powerplug = "powerplug"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .keyboard: return "Keyboard"
        case .battery: return "Battery"
        case .bolt: return "Lightning Bolt"
        case .powerplug: return "Power Plug"
        case .none: return "No Icon"
        }
    }
}

enum DisplayFormat: String, Codable, CaseIterable {
    case percentageWithIcon = "85% • 90%"
    case percentageOnly = "85 90"
    case visualBars = "████░ ████░"
    
    var displayName: String { rawValue }
}

enum FontStyle: String, Codable, CaseIterable {
    case system = "System"
    case monospace = "Monospace"
    
    var displayName: String { rawValue }
}
```

### 5. ConnectionState.swift

**Purpose:** Track connection status

```swift
import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case searching           // Actively looking for keyboard
    case connecting
    case connected
    case reconnecting(attempt: Int, maxAttempts: Int)
    case failed(Error)
    
    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .searching: return "Searching..."
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .reconnecting(let attempt, let max):
            return "Reconnecting (\(attempt)/\(max))..."
        case .failed(let error):
            return "Failed: \(error.localizedDescription)"
        }
    }
    
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
    
    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected): return true
        case (.searching, .searching): return true
        case (.connecting, .connecting): return true
        case (.connected, .connected): return true
        case (.reconnecting(let l1, let l2), .reconnecting(let r1, let r2)):
            return l1 == r1 && l2 == r2
        case (.failed, .failed): return true
        default: return false
        }
    }
}
```

---

## Core Managers

### 1. BluetoothManager.swift

**Responsibilities:**
- Scan for BLE devices with Battery Service
- Connect/disconnect to keyboards
- Read battery level characteristics
- Identify left vs right keyboard halves
- Handle BLE state changes
- Provide reactive updates via Combine

**Key Properties:**
```swift
class BluetoothManager: NSObject, ObservableObject {
    // Published state
    @Published var availableKeyboards: [ZMKKeyboard] = []
    @Published var selectedKeyboard: ZMKKeyboard?
    @Published var isScanning: Bool = false
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var connectionState: ConnectionState = .disconnected
    
    // Private properties
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var discoveredServices: [CBService] = []
    private var characteristicReadings: [CBUUID: KeyboardHalf] = [:]
    
    // Dependencies
    private let preferences: PreferencesManager
    private let connectionManager: ConnectionManager
}
```

**Key Methods:**
```swift
// Scanning
func startScanning()
func stopScanning()
func refreshAvailableKeyboards()

// Connection
func connect(to keyboard: ZMKKeyboard)
func disconnect()
func reconnect()

// Battery reading
func refreshBatteryLevels()
func readBatteryCharacteristic(_ characteristic: CBCharacteristic)

// Characteristic identification (solves the left/right problem)
func identifyKeyboardHalf(for characteristic: CBCharacteristic) -> KeyboardHalf
func storeCharacteristicMapping(characteristic: CBUUID, half: KeyboardHalf)
```

**Left/Right Detection Strategy:**

```swift
/// Strategy: Use characteristic instance identifiers
/// 
/// BLE characteristics have unique instance IDs within a service.
/// When we first discover characteristics, we map them to left/right
/// based on discovery order, then persist this mapping.
/// 
/// This is more reliable than Mighty Mitts' flip-flop approach.
///
private func identifyKeyboardHalf(for characteristic: CBCharacteristic) -> KeyboardHalf {
    let characteristicID = characteristic.uuid
    
    // Check if we have a saved mapping
    if let savedMapping = selectedKeyboard?.characteristicMapping[characteristicID.uuidString] {
        return savedMapping
    }
    
    // First time seeing this characteristic
    // Auto-assign: first = left, second = right
    let existingMappings = selectedKeyboard?.characteristicMapping ?? [:]
    let newHalf: KeyboardHalf = existingMappings.isEmpty ? .left : .right
    
    // Save this mapping for future
    storeCharacteristicMapping(characteristic: characteristicID, half: newHalf)
    
    return newHalf
}
```

**Connection State Handling:**

```swift
func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    Logger.shared.info("Connected to peripheral: \(peripheral.name ?? "Unknown")")
    connectionState = .connected
    
    // Start discovering services
    peripheral.delegate = self
    peripheral.discoverServices([BLEConstants.batteryServiceUUID])
    
    // Notify connection manager
    connectionManager.onSuccessfulConnection()
}

func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    Logger.shared.warning("Disconnected from peripheral: \(error?.localizedDescription ?? "User initiated")")
    connectionState = .disconnected
    
    // Trigger auto-reconnect if enabled
    if preferences.settings.autoReconnect {
        connectionManager.startAutoReconnect(for: selectedKeyboard)
    }
}
```

---

### 2. ConnectionManager.swift

**Responsibilities:**
- Handle auto-reconnection logic
- Implement exponential backoff
- Monitor connection health
- Coordinate with BluetoothManager

**Key Properties:**
```swift
class ConnectionManager: ObservableObject {
    @Published var isReconnecting: Bool = false
    @Published var reconnectAttempt: Int = 0
    
    private var reconnectTimer: Timer?
    private var maxAttempts: Int
    private let bluetoothManager: BluetoothManager
    
    private let baseDelay: TimeInterval = 1.0      // Start with 1 second
    private let maxDelay: TimeInterval = 30.0      // Cap at 30 seconds
}
```

**Key Methods:**
```swift
// Reconnection
func startAutoReconnect(for keyboard: ZMKKeyboard?)
func attemptReconnect()
func stopAutoReconnect()
func onSuccessfulConnection()

// Backoff calculation
private func calculateDelay() -> TimeInterval {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s, 30s...
    let exponentialDelay = baseDelay * pow(2.0, Double(reconnectAttempt))
    return min(exponentialDelay, maxDelay)
}
```

**Auto-Reconnect Flow:**

```swift
func startAutoReconnect(for keyboard: ZMKKeyboard?) {
    guard let keyboard = keyboard else {
        Logger.shared.warning("No keyboard to reconnect to")
        return
    }
    
    guard reconnectAttempt < maxAttempts else {
        Logger.shared.error("Max reconnection attempts reached")
        stopAutoReconnect()
        return
    }
    
    isReconnecting = true
    reconnectAttempt += 1
    
    let delay = calculateDelay()
    Logger.shared.info("Scheduling reconnect attempt \(reconnectAttempt)/\(maxAttempts) in \(delay)s")
    
    reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
        self?.attemptReconnect()
    }
}

func attemptReconnect() {
    Logger.shared.info("Attempting to reconnect...")
    bluetoothManager.reconnect()
    
    // Schedule next attempt if this one fails
    // (Will be cancelled by onSuccessfulConnection if it succeeds)
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
        guard let self = self,
              !self.bluetoothManager.connectionState.isConnected else { return }
        
        // Connection still not established, try again
        self.startAutoReconnect(for: self.bluetoothManager.selectedKeyboard)
    }
}

func onSuccessfulConnection() {
    Logger.shared.info("Reconnection successful!")
    stopAutoReconnect()
}

func stopAutoReconnect() {
    reconnectTimer?.invalidate()
    reconnectTimer = nil
    reconnectAttempt = 0
    isReconnecting = false
}
```

---

### 3. PreferencesManager.swift

**Responsibilities:**
- Save/load app settings
- Persist selected keyboard
- Store characteristic mappings
- Provide reactive access to preferences

**Key Properties:**
```swift
class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()
    
    @Published var settings: AppSettings
    
    // UserDefaults keys
    private enum Keys {
        static let appSettings = "appSettings"
        static let selectedKeyboardID = "selectedKeyboardID"
        static let selectedKeyboardData = "selectedKeyboardData"
        static let savedKeyboards = "savedKeyboards"
        static let hasCompletedSetup = "hasCompletedSetup"
    }
    
    private let defaults = UserDefaults.standard
}
```

**Key Methods:**
```swift
// Settings
func saveSettings()
func loadSettings()
func resetToDefaults()

// Keyboard persistence
func saveKeyboard(_ keyboard: ZMKKeyboard)
func loadLastSelectedKeyboard() -> ZMKKeyboard?
func saveKeyboards(_ keyboards: [ZMKKeyboard])
func loadSavedKeyboards() -> [ZMKKeyboard]

// Setup state
func markSetupComplete()
func hasCompletedSetup() -> Bool
```

**Implementation:**

```swift
func saveKeyboard(_ keyboard: ZMKKeyboard) {
    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(keyboard)
        defaults.set(data, forKey: Keys.selectedKeyboardData)
        defaults.set(keyboard.id.uuidString, forKey: Keys.selectedKeyboardID)
        Logger.shared.info("Saved keyboard: \(keyboard.name)")
    } catch {
        Logger.shared.error("Failed to save keyboard: \(error)")
    }
}

func loadLastSelectedKeyboard() -> ZMKKeyboard? {
    guard let data = defaults.data(forKey: Keys.selectedKeyboardData) else {
        return nil
    }
    
    do {
        let decoder = JSONDecoder()
        let keyboard = try decoder.decode(ZMKKeyboard.self, from: data)
        Logger.shared.info("Loaded keyboard: \(keyboard.name)")
        return keyboard
    } catch {
        Logger.shared.error("Failed to load keyboard: \(error)")
        return nil
    }
}
```

---

### 4. NotificationManager.swift

**Responsibilities:**
- Request notification permissions
- Send battery alerts
- Handle notification actions
- Respect user preferences

**Key Methods:**
```swift
class NotificationManager {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var sentNotifications: Set<String> = []  // Prevent spam
    
    // Setup
    func requestPermission() async -> Bool
    
    // Notifications
    func sendLowBatteryAlert(keyboard: ZMKKeyboard, half: KeyboardHalf, percentage: Int)
    func sendCriticalBatteryAlert(keyboard: ZMKKeyboard, half: KeyboardHalf, percentage: Int)
    func sendDisconnectAlert(keyboard: ZMKKeyboard)
    func sendReconnectAlert(keyboard: ZMKKeyboard)
    
    // Helpers
    private func shouldSendNotification(identifier: String) -> Bool
    private func markNotificationSent(identifier: String)
}
```

**Implementation:**

```swift
func sendLowBatteryAlert(keyboard: ZMKKeyboard, half: KeyboardHalf, percentage: Int) {
    let identifier = "low-battery-\(keyboard.id)-\(half.rawValue)"
    
    guard shouldSendNotification(identifier: identifier) else {
        return  // Already sent recently
    }
    
    let content = UNMutableNotificationContent()
    content.title = "Low Battery Warning"
    content.body = "\(keyboard.effectiveName) - \(half.rawValue) half is at \(percentage)%"
    content.sound = .default
    content.categoryIdentifier = "BATTERY_ALERT"
    
    let request = UNNotificationRequest(
        identifier: identifier,
        content: content,
        trigger: nil  // Immediate
    )
    
    notificationCenter.add(request) { error in
        if let error = error {
            Logger.shared.error("Failed to send notification: \(error)")
        } else {
            self.markNotificationSent(identifier: identifier)
            Logger.shared.info("Sent low battery notification for \(half.rawValue)")
        }
    }
}

private func shouldSendNotification(identifier: String) -> Bool {
    // Only send same notification once per hour
    if sentNotifications.contains(identifier) {
        return false
    }
    return true
}

private func markNotificationSent(identifier: String) {
    sentNotifications.insert(identifier)
    
    // Clear after 1 hour
    DispatchQueue.main.asyncAfter(deadline: .now() + 3600) { [weak self] in
        self?.sentNotifications.remove(identifier)
    }
}
```

---

## UI/UX Design

### Menu Bar Display Customization

Users can customize the menu bar display through settings:

**Icon Selection:**
- Keyboard icon (SF Symbol: `keyboard`)
- Battery icon (SF Symbol: `battery.100`)
- Lightning bolt (SF Symbol: `bolt.fill`)
- Power plug (SF Symbol: `powerplug`)
- No icon

**Display Format:**
- `85% • 90%` - Percentage with separator
- `85 90` - Numbers only
- `████░ ████░` - Visual bars

**Font Style:**
- System font (native macOS look)
- Monospace (technical appearance)

**Color Coding (optional, for visual bars only):**
- Green: 51-100%
- Yellow: 21-50%
- Orange: 11-20%
- Red: 0-10%

### Menu Bar Dropdown Structure

```
┌─────────────────────────────────────────┐
│ [Keyboard Name] ✓                       │ ← Selected keyboard (checkmark)
│                                         │
│ ┌─────────────────────────────────┐   │
│ │  Left Half:   [████░] 85%       │   │ ← Visual battery indicator
│ │  Right Half:  [████░] 90%       │   │
│ │                                 │   │
│ │  Last Updated: 2 minutes ago    │   │ ← Timestamp
│ │  Status: Connected              │   │ ← Connection state
│ └─────────────────────────────────┘   │
│                                         │
├─────────────────────────────────────────┤
│ 🔄 Refresh Now                          │ ← Manual refresh
├─────────────────────────────────────────┤
│ Other Keyboards:                        │
│   □ Corne Keyboard                      │ ← Other available keyboards
│   □ Lily58 Pro                          │
├─────────────────────────────────────────┤
│ ⚙️  Preferences...                      │ ← Settings window
│ ℹ️  About BatMon                        │ ← About panel
├─────────────────────────────────────────┤
│ ⚡ Quit BatMon                          │ ← Exit
└─────────────────────────────────────────┘
```

### Setup Wizard Flow

**Step 1: Welcome**
```
┌─────────────────────────────────────┐
│      Welcome to BatMon! 🦇          │
│                                     │
│  Monitor your ZMK keyboard battery  │
│  levels right from your menu bar.   │
│                                     │
│  Let's get you set up.              │
│                                     │
│              [Next →]               │
└─────────────────────────────────────┘
```

**Step 2: Bluetooth Permission**
```
┌─────────────────────────────────────┐
│     Bluetooth Access Required       │
│                                     │
│  BatMon needs Bluetooth access to   │
│  read your keyboard's battery       │
│  levels.                            │
│                                     │
│  [Grant Bluetooth Access]           │
│                                     │
│         [← Back]  [Skip]            │
└─────────────────────────────────────┘
```

**Step 3: Select Keyboard**
```
┌─────────────────────────────────────┐
│      Select Your Keyboard           │
│                                     │
│  ⌨️ Corne Keyboard    [Select]     │
│  ⌨️ Lily58 Pro        [Select]     │
│  ⌨️ Sweep             [Select]     │
│                                     │
│  🔄 Refresh List                    │
│                                     │
│         [← Back]  [Next →]          │
└─────────────────────────────────────┘
```

**Step 4: Configure Display**
```
┌─────────────────────────────────────┐
│     Customize Your Display          │
│                                     │
│  Icon:                              │
│  ( ) Keyboard  (•) Battery          │
│  ( ) Bolt      ( ) None             │
│                                     │
│  Format:                            │
│  (•) 85% • 90%                      │
│  ( ) 85 90                          │
│  ( ) ████░ ████░                    │
│                                     │
│  Preview: [🔋] 85% • 90%            │
│                                     │
│         [← Back]  [Next →]          │
└─────────────────────────────────────┘
```

**Step 5: Final Setup**
```
┌─────────────────────────────────────┐
│         Almost Done! 🎉             │
│                                     │
│  ☑ Launch BatMon at login           │
│  ☑ Enable low battery alerts        │
│                                     │
│  Alert me when battery drops below: │
│  [20%] ▼                            │
│                                     │
│              [Finish]               │
│                                     │
│         [← Back]  [Skip]            │
└─────────────────────────────────────┘
```

### Settings Window

**Tabbed Interface:**

```
┌───────────────────────────────────────────────┐
│  General | Display | Notifications | About    │
├───────────────────────────────────────────────┤
│                                               │
│  General Settings                             │
│                                               │
│  ☑ Launch at login                            │
│  ☐ Show in Dock                               │
│  ☑ Auto-reconnect to keyboard                 │
│                                               │
│  Battery Check Interval:                      │
│  [─────●─────────] 60 seconds                 │
│  (10s - 300s)                                 │
│                                               │
│  Maximum Reconnect Attempts:                  │
│  [10] ▼                                       │
│                                               │
│  ☐ Enable debug logging                       │
│                                               │
│              [Reset to Defaults]              │
│                                               │
└───────────────────────────────────────────────┘
```

**Display Tab:**
```
┌───────────────────────────────────────────────┐
│  General | Display | Notifications | About    │
├───────────────────────────────────────────────┤
│                                               │
│  Menu Bar Appearance                          │
│                                               │
│  Icon:                                        │
│  ( ) ⌨️ Keyboard                              │
│  (•) 🔋 Battery                               │
│  ( ) ⚡ Lightning                             │
│  ( ) 🔌 Power                                 │
│  ( ) None                                     │
│                                               │
│  Display Format:                              │
│  (•) 85% • 90%    (Percentage with separator) │
│  ( ) 85 90        (Numbers only)              │
│  ( ) ████░ ████░  (Visual bars)               │
│                                               │
│  Font Style:                                  │
│  (•) System  ( ) Monospace                    │
│                                               │
│  ☐ Enable color coding (bars only)            │
│                                               │
│  Preview: [🔋] 85% • 90%                      │
│                                               │
└───────────────────────────────────────────────┘
```

**Notifications Tab:**
```
┌───────────────────────────────────────────────┐
│  General | Display | Notifications | About    │
├───────────────────────────────────────────────┤
│                                               │
│  Battery Alerts                               │
│                                               │
│  ☑ Enable battery notifications               │
│                                               │
│  Alert me when battery drops below:           │
│                                               │
│  Low Battery Threshold:                       │
│  [─────●─────] 20%                            │
│                                               │
│  Critical Battery Threshold:                  │
│  [●─────────] 10%                             │
│                                               │
│  ☑ Show disconnect notifications              │
│  ☐ Show reconnect notifications               │
│                                               │
│             [Test Notification]               │
│                                               │
└───────────────────────────────────────────────┘
```

---

## Feature Roadmap

### Phase 1: MVP (Week 1) - Core Functionality

**Goal:** Basic working app that solves the restart problem

#### Week 1 Tasks

**Day 1: Project Setup**
- [ ] Create Xcode project
- [ ] Set up folder structure
- [ ] Configure entitlements (Bluetooth, Sandbox)
- [ ] Add Info.plist keys
- [ ] Create base models (ZMKKeyboard, BatteryLevel, KeyboardHalf)
- [ ] Set up Git repository
- [ ] Create initial README

**Day 2-3: Bluetooth Core**
- [ ] Implement BluetoothManager skeleton
- [ ] BLE scanning and device discovery
- [ ] Connection management (connect/disconnect)
- [ ] Read Battery Service characteristics
- [ ] Implement left/right identification logic
- [ ] Test with real ZMK keyboard
- [ ] Add comprehensive logging

**Day 4-5: Menu Bar UI**
- [ ] Set up AppDelegate for menu bar
- [ ] Create StatusIconView
- [ ] Implement MenuBarView (dropdown)
- [ ] Create BatteryIndicatorView
- [ ] Keyboard selection list
- [ ] Connection state display
- [ ] Manual refresh button

**Day 6: Persistence & Auto-Reconnect**
- [ ] Implement PreferencesManager
- [ ] Save/load selected keyboard
- [ ] Implement ConnectionManager
- [ ] Auto-reconnect logic with exponential backoff
- [ ] Test restart scenarios
- [ ] Ensure keyboard remembers across sessions

**Day 7: Testing & Bug Fixes**
- [ ] Test all connection scenarios
- [ ] Test auto-reconnect reliability
- [ ] Fix any critical bugs
- [ ] Performance testing
- [ ] Memory leak checks

#### Success Criteria
- ✅ App shows both battery levels
- ✅ Remembers keyboard across restarts
- ✅ Auto-reconnects without manual intervention
- ✅ No crashes or freezes
- ✅ Reliable left/right detection

---

### Phase 2: Polish (Week 2) - User Experience

**Goal:** Make it beautiful and user-friendly

#### Week 2 Tasks

**Day 8-9: Visual Improvements**
- [ ] Implement display customization (icons, formats)
- [ ] Add SF Symbols for menu bar icons
- [ ] Color-coded battery levels (optional)
- [ ] Smooth animations for state changes
- [ ] Dark/light mode optimization
- [ ] Better connection state indicators

**Day 10: Notifications**
- [ ] Implement NotificationManager
- [ ] Request notification permissions
- [ ] Low battery alerts
- [ ] Critical battery alerts
- [ ] Disconnect/reconnect notifications
- [ ] User-configurable thresholds

**Day 11-12: Settings Window**
- [ ] Create SettingsView with tabs
- [ ] General settings panel
- [ ] Display customization panel
- [ ] Notification preferences panel
- [ ] About panel with credits
- [ ] Persist all settings

**Day 13: Setup Wizard**
- [ ] Create SetupWizardView
- [ ] Welcome screen
- [ ] Bluetooth permission request
- [ ] Keyboard selection step
- [ ] Display customization step
- [ ] Final configuration step
- [ ] First-run detection logic

**Day 14: Polish & Refinement**
- [ ] UI/UX refinements
- [ ] Add keyboard shortcuts
- [ ] Improve error messages
- [ ] Add tooltips and help text
- [ ] Accessibility improvements
- [ ] Final bug fixes

#### Success Criteria
- ✅ Beautiful, polished interface
- ✅ Guided first-run experience
- ✅ Comprehensive customization options
- ✅ Helpful notifications
- ✅ Smooth, responsive UI

---

### Phase 3: Advanced Features (Week 3+) - Nice-to-Have

**Goal:** Power user features and optimizations

#### Future Tasks

**Multiple Keyboard Support**
- [ ] Store multiple keyboards in preferences
- [ ] Quick keyboard switching in dropdown
- [ ] Remember settings per keyboard
- [ ] Favorite keyboards feature

**Battery History**
- [ ] Track battery levels over time
- [ ] Create BatteryHistory model
- [ ] Store readings in UserDefaults or SQLite
- [ ] Battery drain rate calculation
- [ ] Estimated time remaining
- [ ] Graph visualization (last 24h/7d/30d)
- [ ] Export data to CSV

**Advanced Features**
- [ ] Launch at login helper
- [ ] Keyboard shortcuts for common actions
- [ ] Menu bar icon badge for low battery
- [ ] Battery drain analytics
- [ ] Charging state detection (if supported)
- [ ] Multiple device simultaneous monitoring
- [ ] Keyboard sleep/wake detection

**Desktop Widget (macOS 14+)**
- [ ] WidgetKit extension
- [ ] Small widget (battery bars)
- [ ] Medium widget (detailed stats)
- [ ] Large widget (history graph)
- [ ] Live Activities support

**Performance Optimizations**
- [ ] Reduce memory footprint
- [ ] Optimize BLE polling
- [ ] Background task efficiency
- [ ] Battery impact testing

---

## Development Plan

### Milestones

| Milestone | Timeline | Deliverables |
|-----------|----------|--------------|
| **M1: Project Setup** | Day 1 | Project structure, models, Git repo |
| **M2: Bluetooth Core** | Days 2-3 | BLE scanning, connection, battery reading |
| **M3: Menu Bar UI** | Days 4-5 | Basic UI, keyboard selection, display |
| **M4: Persistence** | Day 6 | Save/load keyboard, auto-reconnect |
| **M5: MVP Complete** | Day 7 | Fully functional basic app |
| **M6: Visual Polish** | Days 8-9 | Customization, animations, icons |
| **M7: Notifications** | Day 10 | Alert system, thresholds |
| **M8: Settings** | Days 11-12 | Full settings window with all options |
| **M9: Setup Wizard** | Day 13 | First-run experience |
| **M10: Release Ready** | Day 14 | Final polish, testing, documentation |

### Daily Checklist Template

```markdown
## Day X: [Milestone Name]

**Goals:**
- [ ] Goal 1
- [ ] Goal 2
- [ ] Goal 3

**Tasks:**
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

**Testing:**
- [ ] Test scenario 1
- [ ] Test scenario 2

**Notes:**
- Any blockers?
- Any decisions needed?
- What went well?
- What needs improvement?

**Tomorrow:**
- [ ] Next task
```

---

## Testing Strategy

### Unit Tests

**BluetoothManagerTests.swift**
- [ ] Test device discovery
- [ ] Test connection/disconnection
- [ ] Test characteristic identification
- [ ] Test battery level parsing
- [ ] Test auto-reconnect logic

**ConnectionManagerTests.swift**
- [ ] Test exponential backoff calculation
- [ ] Test max attempt handling
- [ ] Test reconnection cancellation
- [ ] Test state transitions

**PreferencesManagerTests.swift**
- [ ] Test settings persistence
- [ ] Test keyboard save/load
- [ ] Test default values
- [ ] Test migration scenarios

**ViewModelTests.swift**
- [ ] Test MenuBarViewModel state updates
- [ ] Test SettingsViewModel bindings
- [ ] Test KeyboardSelectionViewModel logic

### Integration Tests

**Connection Flow**
- [ ] Scan → Connect → Read → Display
- [ ] Disconnect → Auto-reconnect → Resume
- [ ] App restart → Load saved keyboard → Reconnect
- [ ] Bluetooth off → Bluetooth on → Resume

**Error Scenarios**
- [ ] Keyboard out of range
- [ ] Bluetooth disabled
- [ ] Permission denied
- [ ] Multiple disconnect/reconnect cycles
- [ ] App in background

### Manual Testing Scenarios

**Critical Paths:**
1. **First Launch**
   - Clean install
   - Setup wizard flow
   - Grant permissions
   - Select keyboard
   - Verify menu bar display

2. **Daily Use**
   - App launch (should remember keyboard)
   - Battery levels update every minute
   - No performance issues
   - Menu bar always visible

3. **Reconnection**
   - Turn off keyboard → Turn on → Auto-reconnects
   - Walk out of range → Come back → Reconnects
   - Disable Bluetooth → Enable → Reconnects
   - Force quit app → Relaunch → Reconnects

4. **Settings**
   - Change display format → Updates menu bar
   - Change polling interval → Updates frequency
   - Toggle notifications → Test alerts
   - Change thresholds → Verify triggers

5. **Edge Cases**
   - Multiple keyboards nearby
   - Very low battery (< 5%)
   - Rapid disconnect/reconnect
   - 24+ hour runtime
   - macOS sleep/wake

**Testing Checklist:**
```markdown
- [ ] Fresh install works
- [ ] Setup wizard completes
- [ ] Bluetooth permission granted
- [ ] Keyboard discovered and connected
- [ ] Both battery levels display correctly
- [ ] Left/right halves identified correctly
- [ ] Auto-reconnect works after disconnect
- [ ] App remembers keyboard after restart
- [ ] Settings persist correctly
- [ ] Notifications trigger at thresholds
- [ ] Menu bar updates in real-time
- [ ] No memory leaks (Instruments)
- [ ] No excessive CPU usage
- [ ] Dark mode looks correct
- [ ] Light mode looks correct
- [ ] All settings options work
- [ ] About panel displays correctly
- [ ] Quit button works
- [ ] Launch at login works (if enabled)
```

### Performance Benchmarks

| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| Memory Usage | < 30 MB | < 50 MB | < 100 MB |
| CPU (Idle) | < 1% | < 3% | < 5% |
| CPU (Scanning) | < 10% | < 20% | < 30% |
| Battery Impact | Minimal | Low | Moderate |
| App Launch Time | < 1s | < 2s | < 3s |
| BLE Connect Time | < 2s | < 5s | < 10s |

---

## Distribution

### Build Configuration

**Info.plist Keys:**
```xml
<key>CFBundleName</key>
<string>BatMon</string>

<key>CFBundleDisplayName</key>
<string>BatMon</string>

<key>CFBundleIdentifier</key>
<string>com.yourdomain.bat-mon</string>

<key>CFBundleVersion</key>
<string>1.0.0</string>

<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<key>LSMinimumSystemVersion</key>
<string>13.0</string>

<key>LSUIElement</key>
<true/>  <!-- Menu bar only, no Dock icon -->

<key>NSBluetoothAlwaysUsageDescription</key>
<string>BatMon needs Bluetooth access to monitor your ZMK keyboard's battery levels.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>BatMon needs to connect to your ZMK keyboard to read battery information.</string>
```

**Entitlements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.device.bluetooth</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

### Release Channels

**1. GitHub Releases** (Primary)
- Build signed .app bundle
- Create DMG with drag-to-Applications
- Upload to GitHub Releases
- Provide installation instructions
- Include changelog

**Release Structure:**
```
BatMon-1.0.0.dmg
├── BatMon.app
├── README.txt (installation instructions)
└── .DS_Store (background image)
```

**2. Homebrew Cask** (Recommended)
- Create Homebrew formula
- Submit to homebrew-cask
- Users install via: `brew install --cask bat-mon`

**Homebrew Formula:**
```ruby
cask "bat-mon" do
  version "1.0.0"
  sha256 "..."
  
  url "https://github.com/yourusername/bat-mon/releases/download/v#{version}/BatMon-#{version}.dmg"
  name "BatMon"
  desc "ZMK keyboard battery monitor for macOS"
  homepage "https://github.com/yourusername/bat-mon"
  
  app "BatMon.app"
  
  zap trash: [
    "~/Library/Preferences/com.yourdomain.bat-mon.plist",
    "~/Library/Application Support/BatMon",
  ]
end
```

**3. Build from Source**
- Provide detailed build instructions
- Document Xcode version requirements
- Include troubleshooting guide

### Versioning Strategy

**Semantic Versioning:** `MAJOR.MINOR.PATCH`

- **MAJOR:** Breaking changes (e.g., 1.0.0 → 2.0.0)
- **MINOR:** New features (e.g., 1.0.0 → 1.1.0)
- **PATCH:** Bug fixes (e.g., 1.0.0 → 1.0.1)

**Version Milestones:**
- `v0.1.0` - Alpha (internal testing)
- `v0.9.0` - Beta (public testing)
- `v1.0.0` - First stable release
- `v1.1.0` - Settings window + notifications
- `v1.2.0` - Setup wizard
- `v2.0.0` - Widget support (breaking: requires macOS 14+)

### Code Signing

**For GitHub Releases:**
- Sign with Apple Developer ID
- Notarize with Apple
- Enable hardened runtime
- Users won't see "Unidentified Developer" warning

**Steps:**
1. Join Apple Developer Program ($99/year)
2. Create Developer ID Application certificate
3. Sign app: `codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" BatMon.app`
4. Notarize: `xcrun notarytool submit BatMon.dmg --wait`
5. Staple ticket: `xcrun stapler staple BatMon.dmg`

**For Personal Use:**
- Self-signed certificate (free)
- Users need to right-click → Open first time
- Or build from source themselves

---

## Future Considerations

### macOS Widget (WidgetKit)

**Small Widget:**
```
┌───────────┐
│  BatMon   │
│           │
│  L  ████  │
│  R  ████  │
└───────────┘
```

**Medium Widget:**
```
┌──────────────────────┐
│  BatMon              │
│  Corne Keyboard      │
│                      │
│  Left:  [████░] 85%  │
│  Right: [████░] 90%  │
│                      │
│  Updated 5m ago      │
└──────────────────────┘
```

**Large Widget:**
```
┌─────────────────────────────────┐
│  BatMon - Corne Keyboard        │
│                                 │
│  Left Half:   [████░] 85%       │
│  Right Half:  [████░] 90%       │
│                                 │
│  Battery History (24h)          │
│  ┌─────────────────────────┐   │
│  │ ╱╲      ╱╲             │   │
│  │╱  ╲    ╱  ╲            │   │
│  │     ╲╱      ╲╱         │   │
│  └─────────────────────────┘   │
│  6am    12pm    6pm    12am    │
└─────────────────────────────────┘
```

### iOS/iPadOS Support

**Potential Features:**
- View keyboard battery on iPhone/iPad
- Notifications on mobile devices
- iCloud sync of preferences
- Handoff between Mac and iOS

**Challenges:**
- iOS Bluetooth restrictions
- Background BLE scanning limitations
- Different UX paradigm

### Advanced Analytics

**Battery Intelligence:**
- Usage patterns analysis
- Predictive low battery warnings
- Charging recommendations
- Battery health tracking
- Drain rate calculations

**Insights:**
- "Your keyboard typically lasts 3 weeks on a charge"
- "Battery drains 5% faster on Tuesdays" (if you type more)
- "Recommended charging: Friday evening"

### Community Features

**Keyboard Profiles:**
- Share keyboard configurations
- Community-submitted keyboard database
- Auto-detect keyboard model
- Optimized settings per keyboard

**Social:**
- Compare battery life with other users
- Leaderboard for longest battery life
- Share battery stats

---

## 📚 Constants & Configuration

### Constants.swift

```swift
import Foundation
import CoreBluetooth

enum BLEConstants {
    // Standard Battery Service UUIDs
    static let batteryServiceUUID = CBUUID(string: "0x180F")
    static let batteryLevelCharacteristicUUID = CBUUID(string: "0x2A19")
    
    // Scanning
    static let scanTimeout: TimeInterval = 10.0
    static let connectTimeout: TimeInterval = 10.0
}

enum AppConstants {
    // Polling
    static let defaultPollingInterval: TimeInterval = 60.0   // 1 minute
    static let minPollingInterval: TimeInterval = 10.0       // 10 seconds
    static let maxPollingInterval: TimeInterval = 300.0      // 5 minutes
    
    // Battery thresholds
    static let defaultLowBatteryThreshold = 20     // percent
    static let defaultCriticalBatteryThreshold = 10 // percent
    static let minBatteryThreshold = 5
    static let maxBatteryThreshold = 50
    
    // Reconnection
    static let reconnectBaseDelay: TimeInterval = 1.0
    static let reconnectMaxDelay: TimeInterval = 30.0
    static let defaultMaxReconnectAttempts = 10
    
    // UI
    static let menuBarUpdateThrottle: TimeInterval = 1.0  // Max 1 update/second
    static let notificationCooldown: TimeInterval = 3600.0 // 1 hour between same notifications
}

enum UserDefaultsKeys {
    static let appSettings = "appSettings"
    static let selectedKeyboardID = "selectedKeyboardID"
    static let savedKeyboards = "savedKeyboards"
    static let hasCompletedSetup = "hasCompletedSetup"
    static let characteristicMappings = "characteristicMappings"
}

enum AppInfo {
    static let appName = "BatMon"
    static let bundleIdentifier = "com.yourdomain.bat-mon"
    static let version = "1.0.0"
    static let buildNumber = "1"
    static let githubURL = "https://github.com/yourusername/bat-mon"
    static let issuesURL = "https://github.com/yourusername/bat-mon/issues"
}
```

---

## 📖 Documentation Plan

### README.md Structure

```markdown
# 🦇 BatMon

> A reliable macOS menu bar app for monitoring ZMK split keyboard battery levels

[Screenshot of menu bar]

## Features

✨ **Reliable Auto-Reconnection** - Never manually restart the app  
💾 **Persistent Configuration** - Remembers your keyboard  
🎨 **Fully Customizable** - Choose your icons, formats, and colors  
🔔 **Smart Notifications** - Get alerted before batteries die  
⚡ **Lightweight** - Minimal CPU and memory usage  
🔓 **Open Source** - MIT licensed, community-driven  

## Installation

### Homebrew (Recommended)

```bash
brew install --cask bat-mon
```

### Manual Download

1. Download `BatMon.dmg` from [Releases](https://github.com/yourusername/bat-mon/releases)
2. Open the DMG
3. Drag `BatMon.app` to your Applications folder
4. Launch BatMon from Applications

### Build from Source

```bash
git clone https://github.com/yourusername/bat-mon.git
cd bat-mon
open BatMon.xcodeproj
```

Then build with Cmd+B

## Quick Start

1. Launch BatMon
2. Follow the setup wizard
3. Grant Bluetooth permission
4. Select your ZMK keyboard
5. Done! Battery levels appear in your menu bar

## Usage

[Screenshots and descriptions]

## Configuration

[Settings descriptions]

## Troubleshooting

[Common issues and solutions]

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

MIT License - see [LICENSE](LICENSE)

## Acknowledgments

Inspired by [Mighty Mitts](https://github.com/codyd51/Mighty-Mitts)
```

### Additional Documentation

**CONTRIBUTING.md**
- How to contribute
- Code style guide
- Pull request process

**CHANGELOG.md**
- Version history
- Release notes
- Breaking changes

**TROUBLESHOOTING.md**
- Common issues
- Debug steps
- FAQ

---

## ✅ Success Criteria

### MVP Success Metrics

BatMon MVP will be considered successful when:

- ✅ **Reliability**
  - Auto-reconnects work 100% of the time (tested across 50+ disconnect/reconnect cycles)
  - No manual restarts needed for at least 7 days of continuous use
  - Correctly identifies left vs right halves 100% of the time
  
- ✅ **Persistence**
  - Remembers selected keyboard across app restarts
  - All settings persist correctly
  - No data loss after macOS updates or reboots
  
- ✅ **Performance**
  - Memory usage < 50 MB
  - CPU usage < 3% when idle
  - Battery impact: "Low" or better in Activity Monitor
  - No UI freezes or lag
  
- ✅ **User Experience**
  - Setup takes < 2 minutes
  - Menu bar always shows current battery levels
  - Connection state is always clear
  - Error messages are helpful and actionable

### Long-term Success Metrics

- ⭐ 50+ GitHub stars in first month
- 📥 100+ downloads/installs
- 🐛 < 5 critical bugs reported
- ⏱️ 30+ day continuous uptime reports
- 📈 Positive user feedback
- 🔄 Active community contributions

---

## Next Steps

### Immediate Actions

1. **Review this plan** - Make sure everything makes sense
2. **Answer open questions** - Any decisions needed?
3. **Create GitHub repo** - Set up version control
4. **Set up Xcode project** - Get the foundation ready
5. **Start Day 1 tasks** - Begin implementation!

### Quick Start Checklist

```markdown
Before starting development:

- [ ] Reviewed entire plan
- [ ] All questions answered
- [ ] GitHub repo created
- [ ] Xcode installed and updated
- [ ] Apple Developer account (if signing)
- [ ] ZMK keyboard available for testing
- [ ] Development Mac ready
- [ ] Time blocked for focused work

Ready to build? Let's go! 🚀
```

---

## 📝 Notes

### Design Decisions Log

**Left/Right Detection:**
- **Decision:** Use characteristic instance IDs instead of flip-flop
- **Rationale:** More reliable, persistent across connections
- **Alternative Considered:** User manual configuration only
- **Date:** January 2026

**Auto-Reconnect Strategy:**
- **Decision:** Exponential backoff with 30s cap
- **Rationale:** Balance between responsiveness and battery life
- **Alternative Considered:** Fixed 5-second retry
- **Date:** January 2026

**Menu Bar Only:**
- **Decision:** No Dock icon by default (LSUIElement = true)
- **Rationale:** Matches user preference, less intrusive
- **Alternative Considered:** Optional Dock icon in settings
- **Date:** January 2026

### Open Questions

1. **App Icon Design** - Need to create custom icon or use SF Symbol?
2. **Code Signing** - Will you get Apple Developer account?
3. **Localization** - Support other languages in future?
4. **Telemetry** - Any anonymous usage analytics? (privacy-focused)

### Future Discussion Topics

- Widget design specifics
- iOS companion app scope
- Battery history data structure
- Export format preferences
- Community features implementation

---

**End of Project Plan**

This document is a living blueprint and will be updated as the project evolves. 

**Last Updated:** January 9, 2026  
**Status:** Ready for Development  
**Next Milestone:** M1 - Project Setup

---

*Built with ❤️ for the ZMK keyboard community*
