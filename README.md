# CouponTracker

A native iOS application for tracking credit card benefits and maximizing their value. Never let another benefit expire unused.

## Features

- **Benefit Tracking**: Track all your credit card benefits in one place
- **Expiration Alerts**: Push notifications for expiring benefits with customizable reminders
- **Accomplishment Rings**: Apple Fitness-inspired progress visualization
- **Smart Categories**: 7 organized benefit categories (Travel, Dining, Transportation, Shopping, Entertainment, Business, Lifestyle)
- **Snooze Support**: Snooze benefits to be reminded later
- **Period Views**: Track progress by monthly, quarterly, semi-annual, and annual periods

## Screenshots

*Coming soon*

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Clone the repository
```bash
git clone git@github.com:babadudu/coupontracker.git
```

2. Open the project in Xcode
```bash
cd coupontracker
open ios/CouponTracker.xcodeproj
```

3. Build and run on simulator or device (`Cmd+R`)

## Architecture

The app follows a modular MVVM architecture with clean separation of concerns:

```
ios/CouponTracker/Sources/
├── App/                    # App entry point, delegates, DI container
├── Features/               # Feature modules
│   ├── Home/              # Dashboard, Wallet, Card Detail
│   ├── Settings/          # User preferences
│   └── Onboarding/        # First-launch experience
├── Core/                   # Shared infrastructure
│   ├── Navigation/        # Navigation coordinator
│   ├── Extensions/        # Swift extensions
│   └── Protocols/         # Shared protocols
├── Services/              # Business logic services
│   ├── NotificationService.swift
│   ├── BenefitRepository.swift
│   └── CardRepository.swift
├── Models/                # Data models
│   ├── Entities/          # SwiftData models
│   └── Enums/             # App enumerations
└── Utils/                 # Utilities (Formatters, Design System, AppLogger)
```

### Key Technologies

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Persistence layer
- **UserNotifications** - Push notification support
- **Swift Charts** - Data visualization
- **os.Logger** - Structured production logging

## Benefit Categories

| Category | Icon | Description |
|----------|------|-------------|
| Travel | airplane | Flights, hotels, travel credits |
| Dining | fork.knife | Restaurants, food delivery |
| Transportation | car.fill | Rideshare, transit, car services |
| Shopping | bag.fill | Retail, online shopping |
| Entertainment | tv.fill | Streaming, events, digital content |
| Business | briefcase.fill | Office, wireless, professional |
| Lifestyle | sparkles | Wellness, subscriptions, other perks |

## Testing

Run tests using Xcode (`Cmd+U`) or via CLI:

```bash
xcodebuild test \
  -scheme CouponTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Test Coverage

- **Unit Tests**: Models, ViewModels, Services
- **Integration Tests**: Repository operations, SwiftData
- **350+ tests** covering core functionality

## Development

### Code Style

- Follows [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Uses SwiftLint for code consistency
- Design System for consistent UI (colors, typography, spacing)

### Adding New Benefits

1. Update `CardTemplates.json` with new card/benefit data
2. Ensure category matches one of the 7 defined categories
3. Run tests to verify template loading

## Project Structure

```
.
├── docs/                    # Documentation
├── ios/                     # iOS application
│   ├── CouponTracker/       # Main app target
│   ├── CouponTrackerTests/  # Unit tests
│   └── CouponTrackerUITests/# UI tests
├── scripts/                 # Build scripts
└── .github/workflows/       # CI/CD pipelines
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

Copyright 2026 babadudu
