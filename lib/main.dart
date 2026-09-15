import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for localization
  await initializeDateFormatting();

  // Location permissions are intentionally NOT requested here. Calling
  // Permission.request() before runApp() / the first frame means Android
  // doesn't yet have a fully resumed Activity with the Flutter engine
  // attached, so the request can silently resolve to "denied" without ever
  // showing the user a dialog — and on a fresh install that can burn one of
  // Android's two prompts, leaving the permission stuck in a state where
  // later requests return "permanently denied" with no dialog at all.
  //
  // Permissions are requested later, in response to the user tapping
  // "Start" on the home screen (see home_screen.dart / location_service.dart),
  // where the Activity is guaranteed to be resumed.

  runApp(
    const ProviderScope(
      child: RunCoachApp(),
    ),
  );
}
