# Documentation

This directory contains the generated documentation for AGUISwift.

## Local Documentation Generation

### Using Swift Package Manager (DocC)

To generate documentation locally using DocC:

```bash
# Generate documentation for all targets
swift package generate-documentation \
  --target AGUICore \
  --target AGUIClient \
  --target AGUITools \
  --target AGUIAgentSDK \
  --output-path docs

# Generate documentation with static hosting transformation
swift package generate-documentation \
  --target AGUICore \
  --target AGUIClient \
  --target AGUITools \
  --target AGUIAgentSDK \
  --transform-for-static-hosting \
  --hosting-base-path /ag-ui-swift \
  --output-path docs
```

### Using Xcode

1. Open the package in Xcode:
   ```bash
   open Package.swift
   ```

2. Select **Product** → **Build Documentation** (⌘⇧⌥D)

3. The documentation will open in Xcode's documentation viewer

### Viewing Documentation Locally

After generating documentation with static hosting transformation, you can view it locally:

```bash
# Using Python's built-in HTTP server
cd docs
python3 -m http.server 8000

# Then open http://localhost:8000 in your browser
```

Or using Swift's built-in server:

```bash
swift package --disable-sandbox preview-documentation --target AGUICore
```

## Documentation Structure

The documentation is organized by module:

- **AGUICore**: Protocol types, events, and domain value objects
- **AGUIClient**: Low-level client infrastructure
- **AGUITools**: Tool execution framework
- **AGUIAgentSDK**: High-level agent APIs

## GitHub Pages

Documentation is automatically generated and deployed to GitHub Pages on every push to the `main` branch.

The documentation is available at: https://paduh.github.io/ag-ui-swift/

## Writing Documentation

Documentation is written using Swift's DocC format. Add documentation comments to your code:

```swift
/// A brief description of the type or function.
///
/// A more detailed explanation can go here.
/// 
/// - Parameters:
///   - parameter1: Description of parameter1
///   - parameter2: Description of parameter2
/// - Returns: Description of return value
/// - Throws: Description of errors that can be thrown
public struct MyType {
    // ...
}
```

For more information on DocC, see [Apple's Documentation](https://www.swift.org/documentation/docc/).

