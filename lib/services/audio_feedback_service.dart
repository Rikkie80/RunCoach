// Audio feedback service for providing voice feedback during runs
// This is a placeholder that can be expanded with actual audio functionality

import 'package:flutter/foundation.dart';
import '../models/run_session.dart';

/// Service for providing audio feedback during runs
class AudioFeedbackService {
  static final AudioFeedbackService _instance = AudioFeedbackService._internal();
  
  factory AudioFeedbackService() => _instance;
  
  AudioFeedbackService._internal();

  bool _isEnabled = true;
  
  /// Enable or disable audio feedback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if audio feedback is enabled
  bool get isEnabled => _isEnabled;

  /// Provide distance feedback (called at each kilometer)
  void announceDistance(double distanceKm) {
    if (!_isEnabled) return;
    
    final distanceInt = distanceKm.floor();
    if (distanceKm >= distanceInt && (distanceKm - distanceInt) < 0.01) {
      _speak('Distance: $distanceInt kilometers');
    }
  }

  /// Provide time feedback
  void announceTime(Duration duration) {
    if (!_isEnabled) return;
    
    final minutes = duration.inMinutes;
    if (minutes > 0 && minutes % 5 == 0) {
      final hours = duration.inHours;
      final remainingMinutes = minutes % 60;
      final seconds = duration.inSeconds % 60;
      
      String timeStr;
      if (hours > 0) {
        timeStr = '$hours hours, $remainingMinutes minutes';
      } else {
        timeStr = '$minutes minutes, $seconds seconds';
      }
      
      _speak('Time: $timeStr');
    }
  }

  /// Provide pace feedback
  void announcePace(double paceMinKm) {
    if (!_isEnabled) return;
    
    final minutes = paceMinKm.floor();
    final seconds = ((paceMinKm - minutes) * 60).round();
    
    _speak('Pace: $minutes minutes $seconds seconds per kilometer');
  }

  /// Provide average speed feedback
  void announceSpeed(double speedKmh) {
    if (!_isEnabled) return;
    
    _speak('Average speed: ${speedKmh.toStringAsFixed(1)} kilometers per hour');
  }

  /// Announce that run has started
  void announceRunStarted() {
    if (!_isEnabled) return;
    _speak('Run started. Good luck!');
  }

  /// Announce that run has been paused
  void announceRunPaused() {
    if (!_isEnabled) return;
    _speak('Run paused');
  }

  /// Announce that run has been resumed
  void announceRunResumed() {
    if (!_isEnabled) return;
    _speak('Run resumed');
  }

  /// Announce that run has ended
  void announceRunEnded(RunStatistics stats) {
    if (!_isEnabled) return;
    
    _speak('''
      Run completed. 
      Distance: ${stats.formattedDistance} kilometers. 
      Time: ${stats.formattedDuration}. 
      Average pace: ${stats.formattedPace} per kilometer. 
      Well done!
    ''');
  }

  /// Announce milestone (e.g., 5k, 10k, half marathon, marathon)
  void announceMilestone(double distanceKm) {
    if (!_isEnabled) return;
    
    String milestone;
    if (distanceKm >= 42.2) {
      milestone = 'Marathon distance!';
    } else if (distanceKm >= 21.1) {
      milestone = 'Half marathon distance!';
    } else if (distanceKm >= 10) {
      milestone = '10 kilometers!';
    } else if (distanceKm >= 5) {
      milestone = '5 kilometers!';
    } else if (distanceKm >= 1) {
      milestone = '1 kilometer!';
    } else {
      return;
    }
    
    _speak('Milestone: $milestone');
  }

  /// Speak text (placeholder implementation)
  void _speak(String text) {
    if (kDebugMode) {
      print('[Audio] $text');
    }
    
    // TODO: Implement actual text-to-speech
    // This would use flutter_tts or similar package
    // Example:
    // FlutterTts tts = FlutterTts();
    // tts.speak(text);
  }

  /// Dispose of resources
  void dispose() {
    // Clean up any audio resources
  }
}
