# AGUISwift

The AG-UI Swift SDK is a Swift library for building AI agent user interfaces that implement the Agent User Interaction Protocol (AG-UI). It provides real-time streaming communication between Swift applications and AI agents across iOS, macOS, tvOS, and watchOS platforms.

## Installation

Add the SDK to your `Package.swift` file:

```swift
dependencies: [
    // Complete SDK with all modules (recommended)
    .package(url: "https://github.com/your-org/ag-ui-swift.git", from: "1.0.0")
]
```

The client module automatically includes both `AGUICore` and `AGUITools` as dependencies, giving you access to the complete SDK functionality.

For advanced use cases where you only need specific modules:

```swift
dependencies: [
    // Core protocol types only (advanced)
    .package(url: "https://github.com/your-org/ag-ui-swift.git", from: "1.0.0")
]
```

Then import only the modules you need:
```swift
import AGUICore  // Protocol types only
import AGUITools // Tools framework only
```

Or add it through Xcode:
1. File → Add Packages...
2. Enter the repository URL: `https://github.com/your-org/ag-ui-swift.git`
3. Select the version you want to use

## Architecture

The SDK follows a modular architecture with three main components:

### AGUIClient
High-level agent implementations and client infrastructure.
- **AgUiAgent**: Stateless client for cases where no ongoing context is needed or the agent manages all state server-side
- **StatefulAgUiAgent**: Stateful client that maintains conversation history and sends it with each request
- **HttpAgent**: Low-level HTTP transport implementation
- **AbstractAgent**: Base class for custom agent implementations

### AGUICore
Protocol types, events, and message definitions.
- **Events**: All AG-UI protocol event types and serialization
- **Types**: Protocol message types and state management
- **Serialization**: JSON handling with Codable

### AGUITools
Tool execution framework for extending agent capabilities.
- **ToolExecutor**: Protocol for implementing custom tools
- **ToolRegistry**: Tool registration and management
- **ToolExecutionManager**: Tool execution with circuit breaker patterns

## Requirements

- Swift 5.9+
- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

