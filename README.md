# bat-mon

A reliable macOS menu bar app for monitoring ZMK keyboard battery levels.

macOS's native Bluetooth UI only shows the battery level of one keyboard half. bat-mon shows both halves and automatically reconnects after sleep/wake cycles and system restarts.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/PapaniaP/bat-mon/blob/main/LICENSE)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)](https://github.com/PapaniaP/bat-mon)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)](https://github.com/PapaniaP/bat-mon)

<!--
Screenshot: Add a screenshot of the menu bar dropdown here
![bat-mon menu bar](assets/menubar.png)
-->

## Features

- **Reliable auto-reconnect** - Survives sleep/wake cycles and system restarts
- **Split keyboard support** - Shows battery levels for both halves
- **Multiple layouts** - Native, Rich, Minimal, and Terminal (TUI) styles
- **Custom themes** - 9 built-in themes + create your own via JSON
- **Low battery alerts** - Native macOS notifications at configurable thresholds
- **Menu bar customization** - Icons, separators, compact mode, and more

<!--
Screenshot: Show the 4 different layouts side by side
![Layouts](assets/layouts.png)
-->

## Installation

### Download

Download the latest release from [GitHub Releases](https://github.com/PapaniaP/bat-mon/releases).

### Homebrew (coming soon)

```bash
brew install --cask bat-mon
```

### Build from Source

```bash
git clone https://github.com/PapaniaP/bat-mon.git
cd bat-mon
open BatMon.xcodeproj
```

Build and run with Xcode (⌘R).

## Usage

1. Launch bat-mon - it appears in your menu bar
2. Click the menu bar icon to open the panel
3. Click "Scan for Keyboards" to find your ZMK keyboard
4. Select your keyboard to connect

The app will remember your keyboard and automatically reconnect.

<!--
Screenshot: Show Settings window with Appearance tab open
![Settings](assets/settings.png)
-->

## Custom Themes

bat-mon supports custom color themes via a JSON configuration file.

### File Location

```
~/Library/Application Support/BatMon/themes.json
```

> **Note:** For sandboxed builds, the actual path is:
> `~/Library/Containers/com.paolo.bat-mon/Data/Library/Application Support/BatMon/themes.json`

### Theme Structure

Each theme requires 6 color values:

```json
[
  {
    "name": "My Custom Theme",
    "colors": {
      "background": "#1a1b26",
      "text": "#c0caf5",
      "accent": "#7aa2f7",
      "healthy": "#9ece6a",
      "warning": "#e0af68",
      "alert": "#f7768e"
    }
  }
]
```

### Color Keys

| Key | Description |
|-----|-------------|
| `background` | Main panel background color |
| `text` | Primary text color |
| `accent` | Buttons, highlights, active states |
| `healthy` | Battery >40%, connected status |
| `warning` | Battery 21-40%, reconnecting |
| `alert` | Battery ≤20%, errors, disconnected |

### Optional Overrides

Power users can override derived colors:

| Key | Default Derivation |
|-----|-------------------|
| `backgroundSecondary` | `background` lightened 10% |
| `textSecondary` | `text` at 70% opacity |
| `textMuted` | `text` at 40% opacity |
| `divider` | `textMuted` at 30% opacity |
| `critical` | Same as `alert` |

### Example Themes

<details>
<summary>Monokai</summary>

```json
{
  "name": "Monokai",
  "colors": {
    "background": "#272822",
    "text": "#f8f8f2",
    "accent": "#66d9ef",
    "healthy": "#a6e22e",
    "warning": "#fd971f",
    "alert": "#f92672"
  }
}
```
</details>

<details>
<summary>One Dark</summary>

```json
{
  "name": "One Dark",
  "colors": {
    "background": "#282c34",
    "text": "#abb2bf",
    "accent": "#61afef",
    "healthy": "#98c379",
    "warning": "#e5c07b",
    "alert": "#e06c75"
  }
}
```
</details>

<details>
<summary>Rosé Pine</summary>

```json
{
  "name": "Rosé Pine",
  "colors": {
    "background": "#191724",
    "text": "#e0def4",
    "accent": "#c4a7e7",
    "healthy": "#9ccfd8",
    "warning": "#f6c177",
    "alert": "#eb6f92"
  }
}
```
</details>

### Validation

If a theme is missing required fields, it will appear in Settings with a warning icon. Click the warning to see which fields are missing.

Themes are hot-reloaded - save the file and changes appear immediately in Settings.

## Built-in Themes

<!--
Screenshot: Show theme picker in Settings with a few theme previews
![Themes](assets/themes.png)
-->

### Hardcoded (always available)
- System (adapts to macOS appearance)
- Gruvbox Dark
- Gruvbox Light
- Tokyo Night
- Solarized Light

### From themes.json (editable)
- GitHub Dark
- Dracula
- Nord
- Catppuccin

## Requirements

- macOS 14.0 or later
- Bluetooth-enabled Mac
- ZMK-powered split keyboard with peripheral battery reporting enabled

### ZMK Firmware Configuration

For bat-mon to display battery levels for both halves of your split keyboard, your ZMK firmware must be configured to fetch and proxy the peripheral's battery level over Bluetooth.

Add the following to your **central half's** `.conf` file (usually the left half):

```ini
CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_FETCHING=y
CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_PROXY=y
```

After updating your config, rebuild and flash your firmware.

See the [ZMK battery documentation](https://zmk.dev/docs/config/battery) for more details.

## Troubleshooting

### "Bluetooth access denied"

Click the "Allow Bluetooth" button in the app to open System Settings → Privacy & Security → Bluetooth. Enable access for bat-mon.

### Keyboard not found

1. Ensure your keyboard is powered on and in range
2. Check that Bluetooth is enabled on your Mac
3. Try "Scan for Keyboards" again

### Only one half shows battery

Your central half needs to fetch and proxy the peripheral's battery level. Add these to your central half's `.conf` file and reflash:

```ini
CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_FETCHING=y
CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_PROXY=y
```

### Theme not appearing

1. Check the JSON syntax is valid
2. Ensure all 6 required color fields are present
3. Click the warning icon in Settings to see which fields are missing

## Related Projects

- [Mighty-Mitts](https://github.com/codyd51/Mighty-Mitts) - macOS menu bar app for ZMK battery levels (Objective-C)
- [zmk-battery-center](https://github.com/kot149/zmk-battery-center) - Cross-platform system tray app (Tauri/Rust)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please open an issue first to discuss what you'd like to change.
