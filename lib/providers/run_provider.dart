import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/run_session.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/audio_feedback_service.dart';

/// Provider for managing the current run session
final currentRunSessionProvider = NotifierProvider<RunSessionNotifier, RunSession?>(
  () => RunSessionNotifier(),
);

class RunSessionNotifier extends Notifier<RunSession?> {
  @override
  RunSession? build() => null;
  
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  final AudioFeedbackService _audioService = AudioFeedbackService();

  /// Start a new run session
  Future<bool> startRun() async {
    if (state != null) {
      debugPrint('[RunSessionNotifier] Already have an active session');
      return false;
    }

    debugPrint('[RunSessionNotifier] Starting new run...');

    // Initialize storage
    await _storageService.initialize();

    // Start location tracking
    final success = await _locationService.startTracking(
      onLocationUpdate: (locationPoint) {
        debugPrint('[RunSessionNotifier] Location update received');
        if (state != null) {
          final updatedSession = state!.copyWithAddedPoint(locationPoint);
          state = updatedSession;
          
          // Provide audio feedback at kilometer milestones
          final distanceKm = updatedSession.totalDistanceKm;
          _audioService.announceMilestone(distanceKm);
          _audioService.announceDistance(distanceKm);
        }
      },
      onSessionUpdate: (session) {
        debugPrint('[RunSessionNotifier] Session update: ${session.id}');
        state = session;
      },
      onError: (error) {
        debugPrint('[RunSessionNotifier] Location error: $error');
      },
    );

    if (success) {
      final session = _locationService.currentSession;
      if (session != null) {
        debugPrint('[RunSessionNotifier] New session created: ${session.id}');
        state = session;
        _audioService.announceRunStarted();
      }
      return true;
    }
    
    debugPrint('[RunSessionNotifier] Failed to start run');
    return false;
  }

  /// Stop the current run session and save it
  Future<RunSession?> stopRun() async {
    if (state == null) {
      debugPrint('[RunSessionNotifier] No active session to stop');
      return null;
    }

    debugPrint('[RunSessionNotifier] Stopping run...');

    // Stop location tracking
    final completedSession = await _locationService.stopTracking();
    
    if (completedSession != null) {
      // Save to storage
      await _storageService.saveRunSession(completedSession);
      
      // Update state
      state = null;
      
      // Provide audio feedback
      final stats = RunStatistics.fromRunSession(completedSession);
      _audioService.announceRunEnded(stats);
      
      debugPrint('[RunSessionNotifier] Run stopped and saved');
      return completedSession;
    }
    
    debugPrint('[RunSessionNotifier] Failed to stop run');
    return null;
  }

  /// Pause the current run
  Future<bool> pauseRun() async {
    if (state == null) {
      debugPrint('[RunSessionNotifier] No active session to pause');
      return false;
    }

    debugPrint('[RunSessionNotifier] Pausing run...');
    final success = await _locationService.pauseTracking();
    if (success) {
      _audioService.announceRunPaused();
      debugPrint('[RunSessionNotifier] Run paused');
    } else {
      debugPrint('[RunSessionNotifier] Failed to pause run');
    }
    return success;
  }

  /// Resume the current run
  Future<bool> resumeRun() async {
    if (state == null) {
      debugPrint('[RunSessionNotifier] No active session to resume');
      return false;
    }

    debugPrint('[RunSessionNotifier] Resuming run...');
    final success = await _locationService.resumeTracking();
    if (success) {
      _audioService.announceRunResumed();
      debugPrint('[RunSessionNotifier] Run resumed');
    } else {
      debugPrint('[RunSessionNotifier] Failed to resume run');
    }
    return success;
  }

  /// Get current statistics
  RunStatistics? getCurrentStatistics() {
    if (state == null) {
      debugPrint('[RunSessionNotifier] No session for statistics');
      return null;
    }
    debugPrint('[RunSessionNotifier] Getting statistics for session ${state!.id}');
    return RunStatistics.fromRunSession(state!);
  }
}

/// Provider for run history
final runHistoryProvider = FutureProvider<List<RunSession>>(
  (ref) async {
    debugPrint('[runHistoryProvider] Loading run history...');
    final storageService = StorageService();
    await storageService.initialize();
    final sessions = await storageService.getAllRunSessions();
    debugPrint('[runHistoryProvider] Loaded ${sessions.length} sessions');
    return sessions;
  },
);

/// Provider for overall statistics
final overallStatisticsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    debugPrint('[overallStatisticsProvider] Loading overall statistics...');
    final storageService = StorageService();
    await storageService.initialize();
    final stats = await storageService.getOverallStatistics();
    debugPrint('[overallStatisticsProvider] Statistics loaded');
    return stats;
  },
);

/// Provider for location service
final locationServiceProvider = Provider<LocationService>(
  (ref) {
    debugPrint('[locationServiceProvider] Creating LocationService');
    return LocationService();
  },
);

/// Provider for storage service
final storageServiceProvider = Provider<StorageService>(
  (ref) {
    debugPrint('[storageServiceProvider] Creating StorageService');
    return StorageService();
  },
);

/// Provider for audio feedback service
final audioFeedbackServiceProvider = Provider<AudioFeedbackService>(
  (ref) {
    debugPrint('[audioFeedbackServiceProvider] Creating AudioFeedbackService');
    return AudioFeedbackService();
  },
);

/// Provider for checking if a run is active
final isRunActiveProvider = Provider<bool>(
  (ref) {
    final session = ref.watch(currentRunSessionProvider);
    final isActive = session != null && session.isActive;
    debugPrint('[isRunActiveProvider] Run active: $isActive');
    return isActive;
  },
);
