# bat-mon

> ZMK Keyboard Battery Monitor for macOS

---

| | |
|---|---|
| **Version** | 1.0 |
| **Date** | January 9, 2026 |
| **Author** | Paolo |
| **Status** | Draft |

---

## Executive Summary

bat-mon is a lightweight, open-source macOS menu bar application that displays battery levels for ZMK-powered keyboards. The app solves a critical pain point for split keyboard users who currently lack reliable, native battery monitoring on macOS.

The primary focus of bat-mon is **reliability**. Unlike existing solutions that lose keyboard connections after system restarts or sleep cycles, bat-mon will maintain persistent connections and automatically reconnect to paired keyboards.

---

## Problem Statement

### Current Pain Points

- **Connection persistence:** Existing apps forget paired keyboards after macOS restarts, requiring manual re-pairing
- **Auto-reconnect failures:** Apps fail to reconnect after keyboard sleep/wake cycles or Bluetooth disconnections
- **Limited customization:** Current solutions offer minimal UI customization for menu bar display
- **No battery alerts:** Users are surprised by dead keyboards mid-work session

### Target Users

Split mechanical keyboard enthusiasts using ZMK firmware on macOS, particularly those with boards like Corne, Sofle, Lily58, and similar. These users typically connect wirelessly to a single Mac and value reliability and simplicity over feature complexity.

---

## Scope & Goals

### MVP Goals (Priority 1)

1. Reliable auto-reconnect that survives macOS restarts and sleep cycles
2. Persistent keyboard memory between app launches and system restarts
3. Low battery notifications at critical thresholds
4. Clean, customizable menu bar display
5. Support for multiple keyboards (user selects active one)
6. Launch at login option
7. Customizable polling interval

### Out of Scope (Future)

- Battery history graphs and data export
- Desktop widgets (macOS widget support)
- Simultaneous multi-keyboard monitoring

---

## Feature Requirements

| Feature | Priority | Description |
|---------|----------|-------------|
| Auto-reconnect | MVP | Automatically reconnect to keyboard after Bluetooth disconnection, sleep/wake, or restart. Must be completely reliable. |
| Persistent memory | MVP | Remember paired keyboard(s) between app launches and system restarts. Store in UserDefaults or similar. |
| Low battery alerts | MVP | Native macOS notifications when battery reaches critical level (user-configurable threshold). |
| Menu bar display | MVP | Customizable display: icon choice (or no icon), percentage, number, or visual bars. User preference. |
| Multi-keyboard support | MVP | Store multiple keyboards. User selects which one is active (like Mighty Mitts approach). |
| Launch at login | MVP | Option to auto-start with macOS. Default: enabled. User can toggle. |
| Polling interval | MVP | Configurable refresh rate for battery status checks. |
| Setup wizard | MVP | First-run onboarding to guide keyboard pairing and preferences. |
| Disconnect state | MVP | Show "Disconnected" in menu bar when keyboard is unavailable. |
| Battery history | Future | Track and display battery drain over time with graphs. |
| Export data | Future | Export battery logs as CSV or JSON. |
| Desktop widget | Future | Native macOS widget for battery display. |

---

## User Interface Specifications

### Menu Bar Display

The menu bar item should be highly customizable:

- **Icon options:** Multiple icon choices (battery, keyboard, bat-mon logo) or no icon
- **Value display:** Percentage ("85%"), number only ("85"), or visual bars
- **Split keyboard:** Show both halves (e.g., "L: 92% | R: 87%") or combined average
- **Disconnect state:** Display "Disconnected" or icon change when keyboard is unavailable

### Menu Bar Dropdown

Clicking the menu bar item reveals:

1. Current battery levels for connected keyboard (left/right if split)
2. Keyboard name and connection status
3. Quick access to switch active keyboard (if multiple configured)
4. Settings/Preferences menu item
5. Quit option

### Settings Window

Preferences accessible from menu dropdown:

- **General:** Launch at login toggle (default: on), polling interval slider
- **Appearance:** Icon selection, display format (%, number, bars)
- **Notifications:** Enable/disable, critical threshold percentage
- **Keyboards:** List of paired keyboards, add/remove, select active

### Setup Wizard

First-run experience:

1. Welcome screen with brief app description
2. Bluetooth permission request (required for keyboard discovery)
3. Keyboard scanning and selection
4. Display preference configuration
5. Notification preferences
6. Launch at login option
7. Completion confirmation

---

## Technical Specifications

### Platform & Technology

| | |
|---|---|
| **Platform** | macOS 14.0+ (Sonoma and later) |
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI for menu bar and settings |
| **Bluetooth** | CoreBluetooth framework for BLE communication |
| **Storage** | UserDefaults for preferences and keyboard data |
| **License** | Open Source (MIT or similar) |

### ZMK Battery Service

ZMK keyboards expose battery information via Bluetooth Low Energy (BLE) using the standard Battery Service (0x180F). The app will:

- Scan for devices advertising Battery Service UUID
- Read Battery Level characteristic (0x2A19)
- Support split keyboards with separate battery readings for each half
- Auto-detect keyboard type (split vs. unified) based on discovered services

### Connection Reliability Strategy

To ensure reliable reconnection (the core differentiator):

- **Persistent identifiers:** Store keyboard UUID in UserDefaults
- **Background scanning:** Continuously scan for known keyboards when disconnected
- **Wake handlers:** Subscribe to NSWorkspace notifications for system wake
- **Bluetooth state monitoring:** React to Bluetooth power state changes
- **Exponential backoff:** Retry connection attempts with increasing delays

---

## Distribution

bat-mon will be distributed through multiple channels to serve different user preferences:

- **GitHub Releases:** Pre-built .app bundles for direct download
- **Homebrew:** Install via `brew install bat-mon` (cask formula)
- **Source:** Users can clone and build in Xcode themselves

---

## Success Metrics

- **Primary:** Zero reports of connection loss after system restart within 30 days of release
- **Secondary:** Auto-reconnect succeeds within 10 seconds of keyboard wake
- **User satisfaction:** Positive feedback on GitHub issues and r/mechanicalkeyboards

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| macOS Bluetooth API limitations | Research IOBluetooth as fallback; document known limitations |
| Split keyboard BLE variations | Test with multiple board types; community beta testing |
| Battery drain from constant polling | Default to conservative polling interval; benchmark battery impact |
| App Store distribution complexities | Focus on GitHub/Homebrew; consider App Store later |

---
