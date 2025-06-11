# MileagerV2

A Flutter-based mileage tracking app designed for business trip logging and tax reporting.

## Features

### 🚗 Vehicle Management
- Add and manage multiple vehicles
- Track starting odometer readings
- Upload vehicle photos
- Set vehicle nicknames

### 📍 Trip Tracking
- **Manual Trip Tracking**: Start and stop trips manually
- **Automatic Trip Detection**: GPS-based automatic trip detection
- **Pause/Resume Functionality**: Pause trips temporarily and resume later
- **Real-time Distance Calculation**: Accurate GPS-based distance tracking
- **Variable GPS Tracking**: Intelligent power-saving GPS intervals

### 📊 Trip Management
- Categorize trips by purpose (Business, Personal, Medical, etc.)
- Add custom memos to trips
- View detailed trip history
- Real-time trip progress monitoring

### 🎨 User Interface
- Clean, modern Material Design interface
- Dark/Light theme support
- Intuitive trip progress widget with visual status indicators
- Color-coded trip states (active, paused, inactive)

### 🔧 Settings & Debugging
- Debug tracking mode for testing
- Customizable settings
- Status indicators for services
- Debug panel for development

## Technical Features

- **Flutter Framework**: Cross-platform mobile development
- **Firebase Integration**: Cloud storage and authentication
- **GPS Location Services**: High-precision location tracking
- **Activity Recognition**: Automatic driving detection
- **State Management**: Provider pattern for reactive UI updates

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio / Xcode
- Firebase project setup

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/iancarr1412/MileagerV2.git
   cd MileagerV2
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Add your `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
   - Update Firebase configuration

4. Run the app:
   ```bash
   flutter run
   ```

## App Structure

```
lib/
├── models/          # Data models (Trip, Vehicle)
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Business logic services
├── utils/          # Utility functions
└── widgets/        # Reusable UI components
```

## Key Components

- **TripTrackingService**: Core trip tracking logic with pause/resume functionality
- **LocationService**: GPS tracking and distance calculation
- **ActivityRecognitionService**: Automatic driving detection
- **VehicleProvider**: Vehicle management state
- **TripProvider**: Trip data management state

## Recent Updates

- ✅ Added trip pause/resume functionality
- ✅ Improved UI with better color contrast and readability
- ✅ Fixed manual trip auto-termination issues
- ✅ Enhanced trip progress widget with always-visible status
- ✅ Better state management for trip tracking

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please use the GitHub Issues page. 