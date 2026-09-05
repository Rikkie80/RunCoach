import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
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

  /// Initialize the location service and request permissions
  Future<bool> initialize() async {
    try {
      debugPrint('[LocationService] Initializing location service...');
      
      // Step 1: Check if location services are enabled on the device
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        debugPrint('[LocationService] Location services are disabled on device');
        onError?.call('Location services are disabled. Please enable location services in your device settings.');
        return false;
      }
      
      debugPrint('[LocationService] Location services are enabled');
      
      // Step 2: Check and request location permissions
      return await _checkAndRequestPermissions();
    } catch (e) {
      debugPrint('[LocationService] Failed to initialize: $e');
      onError?.call('Failed to initialize location service: $e');
      return false;
    }
  }

  /// Check and request location permissions
  Future<bool> _checkAndRequestPermissions() async {
    try {
      debugPrint('[LocationService] Checking location permissions...');
      
      // Check current permission status using permission_handler
      final permissionStatus = await Permission.locationWhenInUse.status;
      debugPrint('[LocationService] Current permission status: $permissionStatus');
      
      // If denied, request the permission
      if (permissionStatus == PermissionStatus.denied) {
        debugPrint('[LocationService] Requesting locationWhenInUse permission...');
        final newStatus = await Permission.locationWhenInUse.request();
        debugPrint('[LocationService] Permission request result: $newStatus');
        
        if (newStatus == PermissionStatus.denied || newStatus == PermissionStatus.deniedForever) {
          onError?.call('Location permissions denied. Please allow location access in app settings.');
          return false;
        }
      } else if (permissionStatus == PermissionStatus.deniedForever) {
        debugPrint('[LocationService] Permissions denied forever');
        onError?.call('Location permissions permanently denied. Please enable in app settings.');
        return false;
      }
      
      // Check if we can access location using Geolocator
      LocationPermission geolocatorPermission = await Geolocator.checkPermission();
      debugPrint('[LocationService] Geolocator permission: $geolocatorPermission');
      
      if (geolocatorPermission == LocationPermission.denied) {
        debugPrint('[LocationService] Geolocator permission denied, requesting...');
        geolocatorPermission = await Geolocator.requestPermission();
        debugPrint('[LocationService] Geolocator permission after request: $geolocatorPermission');
        
        if (geolocatorPermission == LocationPermission.denied || 
            geolocatorPermission == LocationPermission.deniedForever) {
          onError?.call('Location permissions denied by Geolocator. Please allow location access.');
          return false;
        }
      } else if (geolocatorPermission == LocationPermission.deniedForever) {
        onError?.call('Location permissions permanently denied in Geolocator.');
        return false;
      }
      
      // For Android 10+ (API 29+), check background location
      // This is only needed if we want to track in the background
      if (defaultTargetPlatform == TargetPlatform.android) {
        final isBackgroundEnabled = await Geolocator.isBackgroundLocationEnabled();
        debugPrint('[LocationService] Background location enabled: $isBackgroundEnabled');
        
        if (!isBackgroundEnabled) {
          // Try to request background location
          final backgroundStatus = await Permission.locationAlways.status;
          debugPrint('[LocationService] Background location status: $backgroundStatus');
          
          if (backgroundStatus == PermissionStatus.denied) {
            debugPrint('[LocationService] Requesting background location permission...');
            final newBackgroundStatus = await Permission.locationAlways.request();
            debugPrint('[LocationService] Background permission result: $newBackgroundStatus');
            
            if (newBackgroundStatus == PermissionStatus.denied) {
              // This is OK - we can still track when app is in foreground
              debugPrint('[LocationService] Background location not granted, but foreground will work');
            }
          }
        }
      }
      
      debugPrint('[LocationService] All permissions granted!');
      return true;
      
    } catch (e) {
      debugPrint('[LocationService] Permission check failed: $e');
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
      debugPrint('[LocationService] Please enable location permissions in app settings');
    }
    await openAppSettings();
  }

  /// Start tracking location for a new run session
  Future<bool> startTracking({
    Function(LocationPoint)? onLocationUpdate,
    Function(RunSession)? onSessionUpdate,
    Function(String)? onError,
  }) async {
    if (_isTracking) {
      debugPrint('[LocationService] Already tracking a run');
      onError?.call('Already tracking a run');
      return false;
    }

    this.onLocationUpdate = onLocationUpdate;
    this.onSessionUpdate = onSessionUpdate;
    this.onError = onError;

    debugPrint('[LocationService] Starting tracking...');
    
    // Initialize and check permissions
    final initialized = await initialize();
    if (!initialized) {
      debugPrint('[LocationService] Failed to initialize');
      return false;
    }

    try {
      debugPrint('[LocationService] Creating new session');
      // Create new session
      _currentSession = RunSession.newSession();
      _isTracking = true;

      // Get initial position with high accuracy
      debugPrint('[LocationService] Getting initial position...');
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint('[LocationService] Initial position: ${initialPosition.latitude}, ${initialPosition.longitude}');
      _addPosition(initialPosition);

      // Start position stream with optimal settings
      final locationOptions = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Update every 5 meters
        timeInterval: Duration(seconds: 1),
      );

      debugPrint('[LocationService] Starting position stream...');
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationOptions,
      );
      
      _positionStream!.listen(
        (Position position) {
          debugPrint('[LocationService] New position: ${position.latitude}, ${position.longitude}');
          _addPosition(position);
        },
        onError: (error) {
          debugPrint('[LocationService] Position stream error: $error');
          onError?.call('Location stream error: $error');
          stopTracking();
        },
        onDone: () {
          debugPrint('[LocationService] Position stream done');
          stopTracking();
        },
        cancelOnError: false,
      );

      debugPrint('[LocationService] Tracking started successfully');
      onSessionUpdate?.call(_currentSession!);
      return true;
      
    } catch (e) {
      debugPrint('[LocationService] Failed to start tracking: $e');
      onError?.call('Failed to start tracking: $e');
      _isTracking = false;
      _currentSession = null;
      return false;
    }
  }

  /// Stop tracking and end the current session
  Future<RunSession?> stopTracking() async {
    if (!_isTracking || _currentSession == null) {
      debugPrint('[LocationService] No active session to stop');
      return null;
    }

    try {
      debugPrint('[LocationService] Stopping tracking...');
      // Cancel position stream
      await _positionStream?.cancel();
      _positionStream = null;
      
      // End the session
      _currentSession!.endSession();
      
      final completedSession = _currentSession;
      _currentSession = null;
      _isTracking = false;
      
      debugPrint('[LocationService] Tracking stopped');
      onSessionUpdate?.call(completedSession!);
      return completedSession;
      
    } catch (e) {
      debugPrint('[LocationService] Failed to stop tracking: $e');
      onError?.call('Failed to stop tracking: $e');
      return null;
    }
  }

  /// Pause tracking (keep session but stop updates)
  Future<bool> pauseTracking() async {
    if (!_isTracking || _currentSession == null) {
      debugPrint('[LocationService] No active session to pause');
      return false;
    }

    try {
      debugPrint('[LocationService] Pausing tracking...');
      await _positionStream?.cancel();
      _positionStream = null;
      _isTracking = false;
      debugPrint('[LocationService] Tracking paused');
      return true;
    } catch (e) {
      debugPrint('[LocationService] Failed to pause tracking: $e');
      onError?.call('Failed to pause tracking: $e');
      return false;
    }
  }

  /// Resume tracking after pause
  Future<bool> resumeTracking() async {
    if (_currentSession == null) {
      debugPrint('[LocationService] No session to resume');
      onError?.call('No active session to resume');
      return false;
    }

    if (_isTracking) {
      debugPrint('[LocationService] Already tracking');
      return true; // Already tracking
    }

    try {
      debugPrint('[LocationService] Resuming tracking...');
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
          debugPrint('[LocationService] Resumed - new position: ${position.latitude}, ${position.longitude}');
          _addPosition(position);
        },
        onError: (error) {
          debugPrint('[LocationService] Resumed stream error: $error');
          onError?.call('Location stream error: $error');
          stopTracking();
        },
        onDone: () {
          debugPrint('[LocationService] Resumed stream done');
          stopTracking();
        },
        cancelOnError: false,
      );

      _isTracking = true;
      debugPrint('[LocationService] Tracking resumed');
      return true;
      
    } catch (e) {
      debugPrint('[LocationService] Failed to resume tracking: $e');
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
      debugPrint('[LocationService] Requesting location permissions explicitly...');
      
      // First try with permission_handler
      final status = await Permission.locationWhenInUse.request();
      debugPrint('[LocationService] permission_handler result: $status');
      
      if (status == PermissionStatus.denied || status == PermissionStatus.deniedForever) {
        onError?.call('Please enable location permissions in app settings');
        return false;
      }
      
      // Also check with Geolocator
      LocationPermission geoPermission = await Geolocator.checkPermission();
      if (geoPermission == LocationPermission.denied) {
        geoPermission = await Geolocator.requestPermission();
        if (geoPermission == LocationPermission.denied || 
            geoPermission == LocationPermission.deniedForever) {
          onError?.call('Please enable location permissions');
          return false;
        }
      }
      
      debugPrint('[LocationService] All permissions granted');
      return true;
    } catch (e) {
      debugPrint('[LocationService] Failed to request permissions: $e');
      onError?.call('Failed to request permissions: $e');
      return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    debugPrint('[LocationService] Disposing...');
    stopTracking();
    onLocationUpdate = null;
    onSessionUpdate = null;
    onError = null;
  }
}
