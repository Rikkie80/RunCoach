import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

import 'app.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for localization
  await initializeDateFormatting();
  
  // ============================================
  // PERMISSION HANDLING - This is the critical part
  // ============================================
  
  debugPrint('=== PERMISSION STATUS AT STARTUP ===');
  
  // First, check if we already have permissions
  final whenInUseStatus = await Permission.locationWhenInUse.status;
  final alwaysStatus = await Permission.locationAlways.status;
  
  debugPrint('locationWhenInUse: $whenInUseStatus');
  debugPrint('locationAlways: $alwaysStatus');
  
  // Request permissions if not granted
  if (whenInUseStatus == PermissionStatus.denied) {
    debugPrint('Requesting locationWhenInUse...');
    final result = await Permission.locationWhenInUse.request();
    debugPrint('locationWhenInUse request result: $result');
  }
  
  // For Android 10+, we need to request background location separately
  // But only after whenInUse is granted
  if (whenInUseStatus == PermissionStatus.granted && alwaysStatus == PermissionStatus.denied) {
    debugPrint('Requesting locationAlways (background)...');
    final result = await Permission.locationAlways.request();
    debugPrint('locationAlways request result: $result');
  }
  
  // Also check with Geolocator to ensure compatibility
  try {
    final geoPermission = await Geolocator.checkPermission();
    debugPrint('Geolocator permission: $geoPermission');
    
    if (geoPermission == LocationPermission.denied) {
      debugPrint('Requesting Geolocator permission...');
      await Geolocator.requestPermission();
    }
  } catch (e) {
    debugPrint('Geolocator check failed: $e');
  }
  
  // Check location service
  final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
  debugPrint('Location service enabled: $isLocationEnabled');
  
  if (!isLocationEnabled) {
    debugPrint('Location services are disabled!');
    // Try to open location settings
    await openAppSettings();
  }
  
  debugPrint('=== STARTING APP ===');
  
  runApp(
    const ProviderScope(
      child: RunCoachApp(),
    ),
  );
}
