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
  
  // Note: FOREGROUND_SERVICE / FOREGROUND_SERVICE_LOCATION are Android
  // "normal" permissions. They're declared in AndroidManifest.xml and are
  // granted automatically at install time — there's no runtime permission
  // to request for them (and permission_handler has no such API), so there
  // is nothing to do here.
  
  debugPrint('=== ALL PERMISSIONS REQUESTED ===');
  debugPrint('Starting app...');
  
  runApp(
    const ProviderScope(
      child: RunCoachApp(),
    ),
  );
}
