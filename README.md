# Mileager

A Flutter app for tracking vehicle mileage with automated trip recording using Bluetooth connectivity.

## Features

- Add and manage multiple vehicles
- Automatic trip tracking via Bluetooth connection
- Manual trip entry for offline trips
- Trip categorization (business/personal)
- Monthly mileage reports in Excel format
- Vehicle photo management
- Status indicators for trip, GPS, and Bluetooth
- Dark mode support

## Requirements

- Android 14 or higher
- Bluetooth 4.0 or higher
- Location services enabled
- Storage permissions for reports and photos

## Setup

1. Install Flutter:
   ```bash
   # Follow Flutter installation guide at https://flutter.dev/docs/get-started/install
   ```

2. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/mileager.git
   cd mileager
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Setup Firebase:
   - Create a new Firebase project
   - Add an Android app to your Firebase project
   - Download the `google-services.json` file
   - Place it in the `android/app` directory

5. Run the app:
   ```bash
   flutter run
   ```

## Permissions

The app requires the following permissions:
- Bluetooth (for device connection)
- Location (for trip tracking)
- Storage (for reports and photos)
- Background processing (for continuous trip tracking)

## Architecture

- **Models**: Data structures for vehicles and trips
- **Providers**: State management using Provider pattern
- **Services**: Bluetooth and location services
- **Screens**: UI components and navigation
- **Utils**: Helper functions and theme configuration

## Data Storage

- Vehicle and trip data stored in Firebase Firestore
- Local storage for vehicle photos
- Monthly reports saved to device storage
- Automatic data sync when online

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All contributors and users 