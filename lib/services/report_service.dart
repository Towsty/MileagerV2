import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip.dart';
import '../models/vehicle.dart';
import '../utils/settings_utils.dart';

class ReportService {
  static Future<String> generateMonthlyReport({
    required List<Trip> trips,
    required List<Vehicle> vehicles,
    required DateTime month,
    String? savePath,
    bool shareReport = false,
  }) async {
    // Filter trips for the selected month
    final monthTrips = trips.where((trip) {
      return trip.startTime.year == month.year &&
          trip.startTime.month == month.month;
    }).toList();

    // Sort trips by date
    monthTrips.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Calculate summary stats
    final totalMiles =
        monthTrips.fold(0.0, (sum, trip) => sum + (trip.distance ?? 0.0));
    final businessMiles = monthTrips
        .where((trip) => trip.purpose == TripPurpose.business)
        .fold(0.0, (sum, trip) => sum + (trip.distance ?? 0.0));
    final personalMiles = monthTrips
        .where((trip) => trip.purpose == TripPurpose.personal)
        .fold(0.0, (sum, trip) => sum + (trip.distance ?? 0.0));

    // Create CSV content
    final monthYear = DateFormat('MMMM yyyy').format(month);
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Monthly Mileage Report - $monthYear');
    buffer.writeln(
        'Generated: ${DateFormat('MM/dd/yyyy').format(DateTime.now())}');
    buffer.writeln();

    // Summary
    buffer.writeln('SUMMARY');
    buffer.writeln('Total Miles:,${totalMiles.toStringAsFixed(2)}');
    buffer.writeln('Business Miles:,${businessMiles.toStringAsFixed(2)}');
    buffer.writeln('Personal Miles:,${personalMiles.toStringAsFixed(2)}');
    buffer.writeln();

    // Detailed trip log
    buffer.writeln('DETAILED TRIP LOG');
    buffer.writeln('Date,Vehicle,Distance,Purpose,Memo,Entry Type');

    for (final trip in monthTrips) {
      final vehicle = vehicles.where((v) => v.id == trip.vehicleId).firstOrNull;
      final vehicleName = vehicle != null
          ? '${vehicle.year} ${vehicle.make} ${vehicle.model}'
          : 'Unknown Vehicle';

      final memo = (trip.memo ?? '')
          .replaceAll(',', ';'); // Replace commas to avoid CSV issues
      buffer.writeln(
          '${DateFormat('MM/dd/yyyy').format(trip.startTime)},$vehicleName,${trip.distance?.toStringAsFixed(2) ?? '0.00'},${trip.purpose.toString().split('.').last.toUpperCase()},$memo,${trip.isManualEntry ? 'Manual' : 'Tracked'}');
    }

    buffer.writeln();

    // Vehicle summary
    buffer.writeln('VEHICLE SUMMARY');
    buffer.writeln('Vehicle,Trips,Miles,Business Miles,Personal Miles');

    // Group trips by vehicle
    final vehicleGroups = <String, List<Trip>>{};
    for (final trip in monthTrips) {
      final vehicleId = trip.vehicleId;
      vehicleGroups[vehicleId] ??= [];
      vehicleGroups[vehicleId]!.add(trip);
    }

    for (final entry in vehicleGroups.entries) {
      final vehicle = vehicles.where((v) => v.id == entry.key).firstOrNull;
      final vehicleName = vehicle != null
          ? '${vehicle.year} ${vehicle.make} ${vehicle.model}'
          : 'Unknown Vehicle';
      final vehicleTrips = entry.value;
      final vehicleMiles =
          vehicleTrips.fold(0.0, (sum, trip) => sum + (trip.distance ?? 0.0));
      final vehicleBusinessMiles = vehicleTrips
          .where((trip) => trip.purpose == TripPurpose.business)
          .fold(0.0, (sum, trip) => sum + (trip.distance ?? 0.0));
      final vehiclePersonalMiles = vehicleTrips
          .where((trip) => trip.purpose == TripPurpose.personal)
          .fold(0.0, (sum, trip) => sum + (trip.distance ?? 0.0));

      buffer.writeln(
          '$vehicleName,${vehicleTrips.length},${vehicleMiles.toStringAsFixed(2)},${vehicleBusinessMiles.toStringAsFixed(2)},${vehiclePersonalMiles.toStringAsFixed(2)}');
    }

    // Determine save location
    String saveDir;
    if (shareReport) {
      // For sharing, use temporary directory
      final tempDir = await getTemporaryDirectory();
      saveDir = tempDir.path;
    } else {
      saveDir = savePath ?? await SettingsUtils.getReportSavePath();
    }

    final fileName =
        'mileage_report_${DateFormat('yyyy_MM').format(month)}.csv';
    final filePath = path.join(saveDir, fileName);

    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    // If shareReport is true, trigger Android share dialog
    if (shareReport) {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Mileage Report - $monthYear',
        text:
            'Monthly mileage report for $monthYear\n\nTotal Miles: ${totalMiles.toStringAsFixed(2)}\nBusiness Miles: ${businessMiles.toStringAsFixed(2)}\nPersonal Miles: ${personalMiles.toStringAsFixed(2)}',
      );
    }

    return filePath;
  }

  /// Generate and share a monthly report via Android share dialog
  static Future<String> generateAndShareMonthlyReport({
    required List<Trip> trips,
    required List<Vehicle> vehicles,
    required DateTime month,
  }) async {
    return await generateMonthlyReport(
      trips: trips,
      vehicles: vehicles,
      month: month,
      shareReport: true,
    );
  }

  static Future<List<DateTime>> getAvailableReportMonths(
      List<Trip> trips) async {
    final months = <DateTime>{};

    for (final trip in trips) {
      final monthStart = DateTime(trip.startTime.year, trip.startTime.month, 1);
      months.add(monthStart);
    }

    final sortedMonths = months.toList()..sort((a, b) => b.compareTo(a));
    return sortedMonths;
  }
}
