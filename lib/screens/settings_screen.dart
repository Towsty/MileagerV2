import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../utils/settings_utils.dart';
import '../utils/directory_picker.dart';
import 'package:provider/provider.dart';
import 'package:mileager/providers/vehicle_provider.dart';
import 'package:mileager/providers/trip_provider.dart';
import 'package:mileager/screens/cache_debug_screen.dart';
import 'package:mileager/screens/auto_tracking_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _debugTrackingEnabled = false;
  bool _autoReportEnabled = true;
  String _reportSavePath = '';

  // Email settings
  bool _emailReportsEnabled = false;
  String _reportEmailAddress = '';
  String _emailSubjectTemplate = 'Mileage Report - {month} {year}';
  bool _isTestingEmail = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadEmailSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final debugEnabled = await _getDebugTrackingSetting();
    final reportPath = await SettingsUtils.getReportSavePath();

    setState(() {
      _debugTrackingEnabled = debugEnabled;
      _reportSavePath = reportPath;
    });
  }

  Future<void> _loadEmailSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailReportsEnabled = prefs.getBool('email_reports_enabled') ?? false;
      _reportEmailAddress = prefs.getString('report_email_address') ?? '';
      _emailSubjectTemplate = prefs.getString('email_subject_template') ??
          'Mileage Report - {month} {year}';
      _emailController.text = _reportEmailAddress;
      _subjectController.text = _emailSubjectTemplate;
    });
  }

  Future<void> _saveEmailSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_reports_enabled', _emailReportsEnabled);
    await prefs.setString('report_email_address', _reportEmailAddress);
    await prefs.setString('email_subject_template', _emailSubjectTemplate);
  }

  Future<void> _showTestEmailInfo() async {
    if (_reportEmailAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address first')),
      );
      return;
    }

    // Look for CSV files in the report directory
    List<File> csvFiles = [];
    try {
      final reportDir = Directory(_reportSavePath);
      if (await reportDir.exists()) {
        csvFiles = await reportDir
            .list()
            .where((entity) => entity is File && entity.path.endsWith('.csv'))
            .cast<File>()
            .toList();
      }
    } catch (e) {
      // Directory doesn't exist or can't be accessed
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email Address: $_reportEmailAddress'),
            const SizedBox(height: 8),
            Text('Subject Template: $_emailSubjectTemplate'),
            const SizedBox(height: 8),
            Text('Report Directory: $_reportSavePath'),
            const SizedBox(height: 12),
            if (csvFiles.isNotEmpty) ...[
              Text('Found ${csvFiles.length} report(s):'),
              const SizedBox(height: 4),
              ...csvFiles.take(3).map((file) => Text(
                    '• ${path.basename(file.path)}',
                    style: const TextStyle(fontSize: 12),
                  )),
              if (csvFiles.length > 3) const Text('• ...and more'),
              const SizedBox(height: 12),
              const Text(
                'When you generate reports, the app will open your email app with the report attached and these settings applied.',
                style: TextStyle(fontSize: 12),
              ),
            ] else ...[
              const Text(
                'No reports found yet. Generate a report first, then email functionality will be available.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Future<void> _saveDebugTrackingSetting(bool value) async {
    await SettingsUtils.setDebugTrackingEnabled(value);
    setState(() {
      _debugTrackingEnabled = value;
    });
  }

  Future<void> _selectReportSavePath() async {
    final directory = await DirectoryPicker.pickDirectory();
    if (directory != null) {
      await SettingsUtils.setReportSavePath(directory);
      setState(() {
        _reportSavePath = directory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Trip Tracking'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.track_changes),
                  title: const Text('Auto Tracking'),
                  subtitle: const Text('Configure automatic trip detection'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AutoTrackingScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Debug Trip Tracking'),
                  subtitle:
                      const Text('Show detailed logging for trip tracking'),
                  value: _debugTrackingEnabled,
                  onChanged: _saveDebugTrackingSetting,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Reports'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Report Save Location'),
                  subtitle: Text(_reportSavePath.isEmpty
                      ? 'Tap to select folder'
                      : _reportSavePath),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectReportSavePath,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Email Reports'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Email Reports'),
                  subtitle: const Text(
                      'Get reports via email instead of searching files'),
                  value: _emailReportsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _emailReportsEnabled = value;
                    });
                    _saveEmailSettings();
                  },
                ),
                if (_emailReportsEnabled) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email address field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Your Email Address',
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _reportEmailAddress = value;
                            });
                            _saveEmailSettings();
                          },
                        ),
                        const SizedBox(height: 16),

                        // Subject template field
                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Email Subject Template',
                            hintText: 'Mileage Report - {month} {year}',
                            prefixIcon: Icon(Icons.subject),
                            border: OutlineInputBorder(),
                            helperText:
                                'Use {month}, {year}, {filename} as placeholders',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _emailSubjectTemplate = value;
                            });
                            _saveEmailSettings();
                          },
                        ),
                        const SizedBox(height: 16),

                        // Check configuration button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showTestEmailInfo,
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Check Email Configuration'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'When generating reports, the app will automatically open your email app with the report attached and these settings applied.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Debug & Diagnostics'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cached),
                  title: const Text('Image Cache Debug'),
                  subtitle: const Text('View and manage cached images'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CacheDebugScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Future<bool> _getDebugTrackingSetting() async {
    return await SettingsUtils.getDebugTrackingEnabled();
  }
}
