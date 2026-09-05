import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  
  // First, check if location services are enabled on the device
  final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
  debugPrint('[main.dart] Location service enabled: $isLocationEnabled');
  
  if (!isLocationEnabled) {
    debugPrint('[main.dart] Location services are DISABLED - opening settings');
    await openAppSettings();
    // Wait a bit for user to enable
    await Future.delayed(const Duration(seconds: 2));
  }
  
  // Check and request location permissions
  final whenInUseStatus = await Permission.locationWhenInUse.status;
  debugPrint('[main.dart] locationWhenInUse status: $whenInUseStatus');
  
  if (whenInUseStatus == PermissionStatus.denied) {
    debugPrint('[main.dart] Requesting locationWhenInUse permission...');
    final result = await Permission.locationWhenInUse.request();
    debugPrint('[main.dart] locationWhenInUse request result: $result');
  }
  
  // For Android 10+, we need to request background location separately
  // But only after whenInUse is granted
  final alwaysStatus = await Permission.locationAlways.status;
  debugPrint('[main.dart] locationAlways status: $alwaysStatus');
  
  if (whenInUseStatus == PermissionStatus.granted && alwaysStatus == PermissionStatus.denied) {
    debugPrint('[main.dart] Requesting locationAlways (background) permission...');
    final result = await Permission.locationAlways.request();
    debugPrint('[main.dart] locationAlways request result: $result');
  }
  
  // Also check with Geolocator to ensure compatibility
  try {
    final geoPermission = await Geolocator.checkPermission();
    debugPrint('[main.dart] Geolocator permission: $geoPermission');
    
    if (geoPermission == LocationPermission.denied) {
      debugPrint('[main.dart] Requesting Geolocator permission...');
      await Geolocator.requestPermission();
    }
  } catch (e) {
    debugPrint('[main.dart] Geolocator check failed: $e');
  }
  
  // Final check
  final finalWhenInUse = await Permission.locationWhenInUse.status;
  final finalAlways = await Permission.locationAlways.status;
  debugPrint('[main.dart] FINAL - locationWhenInUse: $finalWhenInUse');
  debugPrint('[main.dart] FINAL - locationAlways: $finalAlways');
  
  debugPrint('=== STARTING APP ===');
  
  runApp(
    const ProviderScope(
      child: RunCoachApp(),
    ),
  );
}
