# CouponTracker

A native iOS application for tracking and managing coupons.

## Project Structure

```
.
├── docs/                    # Project documentation
│   ├── architecture/        # Architecture diagrams and decisions
│   ├── api/                 # API documentation
│   ├── guides/              # Developer guides
│   └── decisions/           # Architecture Decision Records (ADRs)
├── ios/                     # iOS application
│   ├── CouponTracker/       # Main app target
│   │   ├── Sources/         # Source code
│   │   ├── Resources/       # Assets, localization, fonts
│   │   └── SupportingFiles/ # Info.plist, entitlements
│   ├── CouponTrackerTests/  # Unit tests
│   ├── CouponTrackerUITests/# UI tests
│   └── Packages/            # Local Swift packages
├── scripts/                 # Build and automation scripts
└── .github/workflows/       # CI/CD pipelines
```

## iOS App Architecture

The iOS app follows a modular architecture with clean separation of concerns:

- **App/** - App entry point, app delegate, scene configuration
- **Features/** - Feature modules (Home, Settings, Onboarding, etc.)
- **Core/** - Shared infrastructure (Navigation, Extensions, Protocols)
- **Services/** - Business logic services (Network, Storage, Analytics)
- **Models/** - Data models and entities
- **Utils/** - Utility helpers and common functionality

## Requirements

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

## Getting Started

1. Clone the repository
2. Open `ios/CouponTracker.xcodeproj` in Xcode
3. Build and run the project

## Development

### Code Style

This project follows the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

### Testing

- Unit tests are located in `CouponTrackerTests/`
- UI tests are located in `CouponTrackerUITests/`

Run tests using `Cmd+U` in Xcode or via CLI:
```bash
xcodebuild test -scheme CouponTracker -destination 'platform=iOS Simulator,name=iPhone 15'
```

## License

[Add license information]
