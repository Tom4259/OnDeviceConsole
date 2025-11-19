# Console Overlay

A SwiftUI developer tool that displays print statements in a floating overlay when your app is running without being connected to Xcode.

## Features

- 🎯 **Floating Button**: Easy-access circular button in the bottom-right corner
- 👀 **Live Preview**: Shows the latest log message without needing to open the sheet
- 📜 **Full Console View**: Tap the button to see all logs with timestamps
- ⏱️ **Precise Timestamps**: Each log includes millisecond-accurate timing
- 📋 **Copy Support**: Select and copy log text directly from the sheet
- 📱 **iOS 17+**: Built with modern `@Observable` macro

## Installation

### Swift Package Manager

Add the package to your project:

```swift
dependencies: [
    .package(url: "https://github.com/Tom4259/OnDeviceConsole.git", from: "1.0.0")
]
```

### Manual Installation

Copy the `ConsoleOverlay.swift` file directly into your Xcode project.

## Usage

### 1. Add the Overlay to Your App

In your root view or App struct, add the `.consoleOverlay()` modifier:

```swift
import SwiftUI
import ConsoleOverlay

@main
struct MyApp: App {

    var body: some Scene {

        WindowGroup {

            ContentView()
                .consoleOverlay()
        }
    }
}
```

### 2. Use Debug Print Statements

**If using as a package**, replace your `print()` calls with `debugPrint()`:

```swift
debugPrint("User logged in")
debugPrint("Counter value: \(counter)")
debugPrint("Error: \(error.localizedDescription)")
```

**If using manual installation**, your existing `print()` statements will work automatically in debug builds.

### Quick Migration Tip

To convert all print statements in your project:
1. Open Xcode's Find & Replace (`⌘⇧F`)
2. Find: `print(`
3. Replace: `debugPrint(`
4. Review and replace in your project files

## How It Works

The console overlay consists of three main components:

1. **ConsoleManager**: Captures and stores log messages with timestamps
2. **Floating Button**: Always-visible button that opens the console sheet
3. **Hint View**: Temporarily shows the latest log next to the button

When you call `debugPrint()`, the message is:
- Added to the console manager with a timestamp
- Displayed in the hint view for 5 seconds
- Still printed to Xcode console (when connected)
- Available in the full console sheet

## Customization

### Disable in Production

The console overlay should only be used during development. Wrap it in a debug flag:

```swift
ContentView()
    #if DEBUG
    .consoleOverlay()
    #endif
```

### Access Console Manager Directly

You can programmatically add logs or clear the console:

```swift
import ConsoleOverlay

// Add a custom log
ConsoleManager.shared.addLog("Custom message")

// Clear all logs
ConsoleManager.shared.clearLogs()

// Access all logs
let allLogs = ConsoleManager.shared.logs
```

## Example

```swift
import SwiftUI

struct ContentView: View {

    @State private var counter = 0
    
    var body: some View {

        VStack(spacing: 20) {

            Text("Counter: \(counter)")
                .font(.headline)
            
            Button("Increment") {

                counter += 1
                debugPrint("Counter incremented to \(counter)")
            }
            .buttonStyle(.borderedProminent)
            
            Button("Generate Logs") {

                for i in 1...5 {

                    debugPrint("Log entry #\(i)")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .consoleOverlay()
    }
}
```

## Requirements

- iOS 17.0+
