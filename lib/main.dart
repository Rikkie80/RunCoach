import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for localization
  await initializeDateFormatting();
  
  // ============================================
  // PERMISSION HANDLING FOR ANDROID 16
  // ============================================
  
  debugPrint('=== STARTING RUN COACH ON ANDROID 16 ===');
  
  // For Android 16, we need to request permissions carefully
  // Step 1: Request locationWhenInUse
  debugPrint('Requesting locationWhenInUse permission...');
  final whenInUseStatus = await Permission.locationWhenInUse.request();
  debugPrint('locationWhenInUse: $whenInUseStatus');
  
  // Step 2: If granted, request locationAlways for background tracking
  if (whenInUseStatus == PermissionStatus.granted) {
    debugPrint('Requesting locationAlways (background) permission...');
    final alwaysStatus = await Permission.locationAlways.request();
    debugPrint('locationAlways: $alwaysStatus');
  } else {
    debugPrint('locationWhenInUse denied - cannot request background location');
  }
  
  // Step 3: For Android 16, also request foreground service permission
  // This is required for continuous location tracking
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      debugPrint('Requesting foreground service permission...');
      final foregroundStatus = await Permission.foregroundService.request();
      debugPrint('foregroundService: $foregroundStatus');
    } catch (e) {
      debugPrint('Foreground service permission not available: $e');
    }
  }
  
  debugPrint('=== ALL PERMISSIONS REQUESTED ===');
  debugPrint('Starting app...');
  
  runApp(
    const ProviderScope(
      child: RunCoachApp(),
    ),
  );
}
