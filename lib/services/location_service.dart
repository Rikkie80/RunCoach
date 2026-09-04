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

  /// Check if location services are available
  Future<bool> checkLocationService() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      onError?.call('Location services not available: $e');
      return false;
    }
  }

  /// Check and request location permissions
  Future<bool> checkAndRequestPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          onError?.call('Location permissions denied');
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        onError?.call('Location permissions permanently denied');
        return false;
      }
      
      return true;
    } catch (e) {
      onError?.call('Permission check failed: $e');
      return false;
    }
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

    // Check location services
    final locationServiceEnabled = await checkLocationService();
    if (!locationServiceEnabled) {
      onError?.call('Please enable location services');
      return false;
    }

    // Check permissions
    final permissionsGranted = await checkAndRequestPermissions();
    if (!permissionsGranted) {
      return false;
    }

    try {
      // Create new session
      _currentSession = RunSession.newSession();
      _isTracking = true;

      // Get initial position
      final initialPosition = await Geolocator.getCurrentPosition();

      _addPosition(initialPosition);

      // Start position stream
      _positionStream = Geolocator.getPositionStream();
      
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
      _positionStream = Geolocator.getPositionStream();
      
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
        return null;
      }

      final position = await Geolocator.getCurrentPosition();

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

  /// Dispose of resources
  void dispose() {
    stopTracking();
    onLocationUpdate = null;
    onSessionUpdate = null;
    onError = null;
  }
}
