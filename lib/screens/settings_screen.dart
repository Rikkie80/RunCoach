import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/run_provider.dart';
import '../services/storage_service.dart';
import '../services/audio_feedback_service.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _audioFeedbackEnabled = true;
  bool _darkModeEnabled = false;
  String _distanceUnit = 'km';
  String _speedUnit = 'km/h';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load saved settings
    // In a real app, this would load from shared preferences
    setState(() {
      _audioFeedbackEnabled = true;
      _darkModeEnabled = false;
      _distanceUnit = 'km';
      _speedUnit = 'km/h';
    });
  }

  Future<void> _saveSettings() async {
    // Save settings
    // In a real app, this would save to shared preferences
    final audioService = ref.read(audioFeedbackServiceProvider);
    audioService.setEnabled(_audioFeedbackEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App settings section
            const Text(
              'App Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // Dark mode toggle
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Enable dark theme'),
                      value: _darkModeEnabled,
                      onChanged: (value) {
                        setState(() => _darkModeEnabled = value);
                        _saveSettings();
                      },
                      secondary: const Icon(Icons.dark_mode),
                    ),
                    const Divider(height: 1),
                    
                    // Audio feedback toggle
                    SwitchListTile(
                      title: const Text('Audio Feedback'),
                      subtitle: const Text('Enable voice feedback during runs'),
                      value: _audioFeedbackEnabled,
                      onChanged: (value) {
                        setState(() => _audioFeedbackEnabled = value);
                        _saveSettings();
                      },
                      secondary: const Icon(Icons.volume_up),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Units section
            const Text(
              'Units',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // Distance unit
                    RadioListTile<String>(
                      title: const Text('Distance Unit'),
                      value: 'km',
                      groupValue: _distanceUnit,
                      onChanged: (value) {
                        setState(() => _distanceUnit = value!);
                        _saveSettings();
                      },
                      secondary: const Icon(Icons.straighten),
                      subtitle: const Text('Kilometers'),
                    ),
                    RadioListTile<String>(
                      title: const Text('Distance Unit'),
                      value: 'mi',
                      groupValue: _distanceUnit,
                      onChanged: (value) {
                        setState(() => _distanceUnit = value!);
                        _saveSettings();
                      },
                      secondary: const Icon(Icons.straighten),
                      subtitle: const Text('Miles'),
                    ),
                    const Divider(height: 1),
                    
                    // Speed unit
                    RadioListTile<String>(
                      title: const Text('Speed Unit'),
                      value: 'km/h',
                      groupValue: _speedUnit,
                      onChanged: (value) {
                        setState(() => _speedUnit = value!);
                        _saveSettings();
                      },
                      secondary: const Icon(Icons.speed),
                      subtitle: const Text('Kilometers per hour'),
                    ),
                    RadioListTile<String>(
                      title: const Text('Speed Unit'),
                      value: 'mi/h',
                      groupValue: _speedUnit,
                      onChanged: (value) {
                        setState(() => _speedUnit = value!);
                        _saveSettings();
                      },
                      secondary: const Icon(Icons.speed),
                      subtitle: const Text('Miles per hour'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Data management section
            const Text(
              'Data Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // Export data
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Export Data'),
                      subtitle: const Text('Export your run history to a file'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportData(),
                    ),
                    const Divider(height: 1),
                    
                    // Clear data
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
                      subtitle: const Text('Delete all your run history'),
                      onTap: () => _showClearDataDialog(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // About section
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.directions_run, size: 48, color: Colors.green),
                    const SizedBox(height: 8),
                    const Text(
                      'Run Coach',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Version 1.0.0'),
                    const SizedBox(height: 8),
                    const Text(
                      'A running coach app that tracks your speed, time, and location during runs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    // Share app
                    ElevatedButton.icon(
                      onPressed: () => _shareApp(),
                      icon: const Icon(Icons.share),
                      label: const Text('Share App'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Export data
  Future<void> _exportData() async {
    final storageService = ref.read(storageServiceProvider);
    final success = await storageService.exportToBackup();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export data')),
      );
    }
  }

  /// Show clear data dialog
  Future<void> _showClearDataDialog(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to delete all your run history? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      final storageService = ref.read(storageServiceProvider);
      final success = await storageService.clearAllData();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
        // Refresh providers
        ref.refresh(runHistoryProvider);
        ref.refresh(overallStatisticsProvider);
      }
    }
  }

  /// Share app
  Future<void> _shareApp() async {
    const text = '''
Check out Run Coach - a running coach app that tracks your speed, time, and location during runs!

Download it now and start tracking your runs.

Features:
- Real-time tracking of distance, speed, and pace
- GPS location tracking
- Run history and statistics
- Audio feedback during runs
- Share your run summaries
''';

    try {
      await Share.share(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }
}
