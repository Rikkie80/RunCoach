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
  // PERMISSION HANDLING - Simplified and reliable
  // ============================================
  
  debugPrint('=== STARTING RUN COACH ===');
  debugPrint('Requesting location permissions...');
  
  // Request location permissions - this is the ONLY thing we need to do here
  // The app will handle the rest in the UI
  final status = await Permission.locationWhenInUse.request();
  debugPrint('Location permission result: $status');
  
  // For Android 10+, also request background location
  if (status == PermissionStatus.granted) {
    final backgroundStatus = await Permission.locationAlways.request();
    debugPrint('Background location permission result: $backgroundStatus');
  }
  
  debugPrint('=== STARTING APP ===');
  
  runApp(
    const ProviderScope(
      child: RunCoachApp(),
    ),
  );
}
