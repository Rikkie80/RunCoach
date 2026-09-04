import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/run_session.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/audio_feedback_service.dart';

/// Provider for managing the current run session
final currentRunSessionProvider = StateNotifierProvider<RunSessionNotifier, RunSession?>(
  (ref) => RunSessionNotifier(),
);

class RunSessionNotifier extends StateNotifier<RunSession?> {
  RunSessionNotifier() : super(null);
  
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  final AudioFeedbackService _audioService = AudioFeedbackService();

  /// Start a new run session
  Future<bool> startRun() async {
    if (state != null) {
      // Already have an active session
      return false;
    }

    // Initialize storage
    await _storageService.initialize();

    // Start location tracking
    final success = await _locationService.startTracking(
      onLocationUpdate: (locationPoint) {
        // Update state with new location
        if (state != null) {
          state!.addLocationPoint(locationPoint);
        }
        
        // Provide audio feedback at kilometer milestones
        final distanceKm = state?.totalDistanceKm ?? 0;
        _audioService.announceMilestone(distanceKm);
        _audioService.announceDistance(distanceKm);
      },
      onSessionUpdate: (session) {
        state = session;
      },
      onError: (error) {
        // Handle error
        print('Location error: $error');
      },
    );

    if (success) {
      // Create new session from location service
      final session = _locationService.currentSession;
      if (session != null) {
        state = session;
        _audioService.announceRunStarted();
      }
      return true;
    }
    
    return false;
  }

  /// Stop the current run session and save it
  Future<RunSession?> stopRun() async {
    if (state == null) {
      return null;
    }

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
      
      return completedSession;
    }
    
    return null;
  }

  /// Pause the current run
  Future<bool> pauseRun() async {
    if (state == null) {
      return false;
    }

    final success = await _locationService.pauseTracking();
    if (success) {
      _audioService.announceRunPaused();
    }
    return success;
  }

  /// Resume the current run
  Future<bool> resumeRun() async {
    if (state == null) {
      return false;
    }

    final success = await _locationService.resumeTracking();
    if (success) {
      _audioService.announceRunResumed();
    }
    return success;
  }

  /// Get current statistics
  RunStatistics? getCurrentStatistics() {
    if (state == null) {
      return null;
    }
    return RunStatistics.fromRunSession(state!);
  }
}

/// Provider for run history
final runHistoryProvider = FutureProvider<List<RunSession>>(
  (ref) async {
    final storageService = StorageService();
    await storageService.initialize();
    return storageService.getAllRunSessions();
  },
);

/// Provider for overall statistics
final overallStatisticsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    final storageService = StorageService();
    await storageService.initialize();
    return storageService.getOverallStatistics();
  },
);

/// Provider for location service
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

/// Provider for storage service
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

/// Provider for audio feedback service
final audioFeedbackServiceProvider = Provider<AudioFeedbackService>(
  (ref) => AudioFeedbackService(),
);

/// Provider for checking if a run is active
final isRunActiveProvider = Provider<bool>(
  (ref) {
    final session = ref.watch(currentRunSessionProvider);
    return session != null && session.isActive;
  },
);
