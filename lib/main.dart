import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for localization
  await initializeDateFormatting();
  
  // Check and request location permissions
  // This is the PRIMARY method to request permissions
  final status = await Permission.locationWhenInUse.request();
  
  // If denied, try again with more context
  if (status == PermissionStatus.denied) {
    // Wait a moment and try again
    await Future.delayed(const Duration(milliseconds: 500));
    await Permission.locationWhenInUse.request();
  }
  
  // For Android 10+ (API 29+), we also need background location
  // But this should only be requested after the app has been granted
  // locationWhenInUse permission
  if (status == PermissionStatus.granted) {
    // On Android 10+ (Q), we need to request background location separately
    // This will show a separate dialog
    final backgroundStatus = await Permission.locationAlways.request();
    
    // Log the status for debugging
    debugPrint('Location WhenInUse: $status');
    debugPrint('Location Always: $backgroundStatus');
  }
  
  runApp(
    const ProviderScope(
      child: RunCoachApp(),
    ),
  );
}
