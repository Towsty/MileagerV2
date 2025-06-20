import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> requestBackgroundLocationPermission() async {
    final status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  static Future<bool> checkBackgroundLocationPermission() async {
    final status = await Permission.locationAlways.status;
    return status.isGranted;
  }

  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  static Future<Map<Permission, PermissionStatus>>
      requestAllRequiredPermissions() async {
    return await [
      Permission.location,
      Permission.locationAlways,
      Permission.activityRecognition,
    ].request();
  }

  static Future<bool> areAllPermissionsGranted() async {
    final permissions = await Future.wait([
      Permission.location.status,
      Permission.locationAlways.status,
      Permission.activityRecognition.status,
    ]);

    return permissions.every((status) => status.isGranted);
  }

  static Future<bool> shouldShowPermissionRationale() async {
    final locationStatus = await Permission.location.status;
    final backgroundStatus = await Permission.locationAlways.status;

    return locationStatus.isDenied || backgroundStatus.isDenied;
  }

  static Future<void> handlePermissionDenial() async {
    final canOpenSettings = await openAppSettings();
    if (!canOpenSettings) {
      throw Exception('Cannot open app settings');
    }
  }
}
