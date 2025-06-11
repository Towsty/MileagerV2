import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class DirectoryOption {
  final String path;
  final String displayName;
  final String description;

  DirectoryOption({
    required this.path,
    required this.displayName,
    required this.description,
  });
}

class DirectoryPicker {
  /// Shows the full Android file picker with all cloud storage providers
  static Future<String?> pickDirectory() async {
    try {
      // Use the regular file picker which shows all storage providers
      // including Google Drive, OneDrive, Dropbox, etc.
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle:
            'Browse to your desired folder, then select any file in that folder',
        type: FileType.any,
        allowMultiple: false,
        allowCompression: false,
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;

        // For cloud storage, we'll use the parent directory of the selected file
        String directoryPath = File(filePath).parent.path;

        print('DirectoryPicker: Selected file: $filePath');
        print('DirectoryPicker: Using directory: $directoryPath');

        return directoryPath;
      } else {
        print('DirectoryPicker: No file selected');
        return null;
      }
    } catch (e) {
      print('DirectoryPicker error: $e');
      // If the file picker fails, fall back to creating a local directory
      return await getDefaultDirectory();
    }
  }

  /// Get preset directory options as fallback
  static Future<List<DirectoryOption>> getAvailableDirectories() async {
    final directories = <DirectoryOption>[];

    try {
      // App Documents (always available)
      final documentsDir = await getApplicationDocumentsDirectory();
      directories.add(DirectoryOption(
        path: documentsDir.path,
        displayName: 'App Documents',
        description: 'Private app folder (recommended)',
      ));

      if (Platform.isAndroid) {
        // App External Storage
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          directories.add(DirectoryOption(
            path: externalDir.path,
            displayName: 'App External',
            description: 'App folder on external storage',
          ));

          // Downloads folder
          final downloadsPath =
              '${externalDir.path.split('/Android').first}/Download';
          if (await Directory(downloadsPath).exists()) {
            directories.add(DirectoryOption(
              path: downloadsPath,
              displayName: 'Downloads',
              description: 'Public Downloads folder',
            ));
          }
        }
      }
    } catch (e) {
      print('Error getting directories: $e');
    }

    return directories;
  }

  // Legacy method for backward compatibility
  static Future<List<String>> getAvailableDirectoryPaths() async {
    final options = await getAvailableDirectories();
    return options.map((option) => option.path).toList();
  }

  /// Get the default local directory for reports
  static Future<String?> getDefaultDirectory() async {
    try {
      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final reportsDir = Directory('${externalDir.path}/MileageReports');
          if (!await reportsDir.exists()) {
            await reportsDir.create(recursive: true);
          }
          return reportsDir.path;
        }
      }

      final documentsDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${documentsDir.path}/MileageReports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      return reportsDir.path;
    } catch (e) {
      print('Error getting default directory: $e');
      return null;
    }
  }
}
