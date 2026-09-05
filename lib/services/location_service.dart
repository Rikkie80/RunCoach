import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/run_session.dart';

/// Service for handling location tracking during runs
class LocationService {
  static final LocationService _instance = LocationService._internal();
  
  factory LocationService() => _instance;
  
  LocationService._internal();

  bool _isTracking = false;
  Stream<Position>? _positionStream;
  RunSession? _currentSession;
  
  // Callbacks for location updates
  Function(LocationPoint)? onLocationUpdate;
  Function(RunSession)? onSessionUpdate;
  Function(String)? onError;

  /// Initialize the location service
  Future<bool> initialize() async {
    try {
      // Check if location services are enabled
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        onError?.call('Location services are disabled. Please enable location services in your device settings.');
        return false;
      }
      
      // Check and request permissions
      return await _checkAndRequestPermissions();
    } catch (e) {
      onError?.call('Failed to initialize location service: $e');
      return false;
    }
  }

  /// Check and request location permissions
  Future<bool> _checkAndRequestPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      // If permissions are denied, request them
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      // Check the result
      if (permission == LocationPermission.denied) {
        onError?.call('Location permissions denied. Please allow location access in app settings.');
        return false;
      }
      
      if (permission == LocationPermission.deniedForever) {
        onError?.call('Location permissions permanently denied. Please enable in app settings.');
        // For Android, try to open app settings
        if (defaultTargetPlatform == TargetPlatform.android) {
          _openAppSettings();
        }
        return false;
      }
      
      // For Android 10+, check background location
      if (defaultTargetPlatform == TargetPlatform.android) {
        final isBackgroundEnabled = await Geolocator.isBackgroundLocationEnabled();
        if (!isBackgroundEnabled) {
          onError?.call('Background location access is required. Please enable it in app settings.');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      onError?.call('Permission check failed: $e');
      return false;
    }
  }

  /// Check if location services are available
  Future<bool> checkLocationService() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      onError?.call('Location services not available: $e');
      return false;
    }
  }

  /// Check and request location permissions (public method)
  Future<bool> checkAndRequestPermissions() async {
    return await _checkAndRequestPermissions();
  }

  /// Open app settings for permission management
  Future<void> _openAppSettings() async {
    if (kDebugMode) {
      print('[LocationService] Please enable location permissions in app settings');
    }
    // In a real app, you would use url_launcher to open settings
    // For now, we just print the message
  }

  /// Start tracking location for a new run session
  Future<bool> startTracking({
    Function(LocationPoint)? onLocationUpdate,
    Function(RunSession)? onSessionUpdate,
    Function(String)? onError,
  }) async {
    if (_isTracking) {
      onError?.call('Already tracking a run');
      return false;
    }

    this.onLocationUpdate = onLocationUpdate;
    this.onSessionUpdate = onSessionUpdate;
    this.onError = onError;

    // Initialize and check permissions
    final initialized = await initialize();
    if (!initialized) {
      return false;
    }

    try {
      // Create new session
      _currentSession = RunSession.newSession();
      _isTracking = true;

      // Get initial position with high accuracy
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _addPosition(initialPosition);

      // Start position stream with optimal settings
      final locationOptions = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Update every 5 meters
        timeInterval: Duration(seconds: 1),
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationOptions,
      );
      
      _positionStream!.listen(
        (Position position) {
          _addPosition(position);
        },
        onError: (error) {
          onError?.call('Location stream error: $error');
          stopTracking();
        },
        onDone: () {
          stopTracking();
        },
        cancelOnError: false,
      );

      onSessionUpdate?.call(_currentSession!);
      return true;
      
    } catch (e) {
      onError?.call('Failed to start tracking: $e');
      _isTracking = false;
      _currentSession = null;
      return false;
    }
  }

  /// Stop tracking and end the current session
  Future<RunSession?> stopTracking() async {
    if (!_isTracking || _currentSession == null) {
      return null;
    }

    try {
      // Cancel position stream
      await _positionStream?.cancel();
      _positionStream = null;
      
      // End the session
      _currentSession!.endSession();
      
      final completedSession = _currentSession;
      _currentSession = null;
      _isTracking = false;
      
      onSessionUpdate?.call(completedSession!);
      return completedSession;
      
    } catch (e) {
      onError?.call('Failed to stop tracking: $e');
      return null;
    }
  }

  /// Pause tracking (keep session but stop updates)
  Future<bool> pauseTracking() async {
    if (!_isTracking || _currentSession == null) {
      return false;
    }

    try {
      await _positionStream?.cancel();
      _positionStream = null;
      _isTracking = false;
      return true;
    } catch (e) {
      onError?.call('Failed to pause tracking: $e');
      return false;
    }
  }

  /// Resume tracking after pause
  Future<bool> resumeTracking() async {
    if (_currentSession == null) {
      onError?.call('No active session to resume');
      return false;
    }

    if (_isTracking) {
      return true; // Already tracking
    }

    try {
      final locationOptions = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
        timeInterval: Duration(seconds: 1),
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationOptions,
      );
      
      _positionStream!.listen(
        (Position position) {
          _addPosition(position);
        },
        onError: (error) {
          onError?.call('Location stream error: $error');
          stopTracking();
        },
        onDone: () {
          stopTracking();
        },
        cancelOnError: false,
      );

      _isTracking = true;
      return true;
      
    } catch (e) {
      onError?.call('Failed to resume tracking: $e');
      return false;
    }
  }

  /// Get current session (if active)
  RunSession? get currentSession => _currentSession;

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Add a position to the current session
  void _addPosition(Position position) {
    if (_currentSession == null) return;

    final locationPoint = LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
    );

    _currentSession!.addLocationPoint(locationPoint);
    onLocationUpdate?.call(locationPoint);
    onSessionUpdate?.call(_currentSession!);
  }

  /// Get current location (one-time)
  Future<LocationPoint?> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        onError?.call('Location permissions not granted');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
      );
      
    } catch (e) {
      onError?.call('Failed to get current location: $e');
      return null;
    }
  }

  /// Request location permissions explicitly
  Future<bool> requestLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        onError?.call('Please enable location permissions in app settings');
        return false;
      }
      
      return true;
    } catch (e) {
      onError?.call('Failed to request permissions: $e');
      return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    stopTracking();
    onLocationUpdate = null;
    onSessionUpdate = null;
    onError = null;
  }
}
