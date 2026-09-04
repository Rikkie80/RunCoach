import 'package:path/path.dart' as path;

/// Represents a single GPS location point during a run
class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? altitude;
  final double? speed;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.altitude,
    this.speed,
  });

  /// Calculate distance from another location point in meters
  double distanceTo(LocationPoint other) {
    const double earthRadius = 6371000; // meters
    final double lat1 = latitude * (3.141592653589793 / 180);
    final double lon1 = longitude * (3.141592653589793 / 180);
    final double lat2 = other.latitude * (3.141592653589793 / 180);
    final double lon2 = other.longitude * (3.141592653589793 / 180);

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1) * Math.cos(lat2) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    final double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'accuracy': accuracy,
    'altitude': altitude,
    'speed': speed,
  };

  /// Create from JSON
  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      accuracy: json['accuracy'] as double?,
      altitude: json['altitude'] as double?,
      speed: json['speed'] as double?,
    );
  }

  @override
  String toString() => 'LocationPoint(lat: $latitude, lon: $longitude, time: $timestamp)';
}

/// Represents a complete running session
class RunSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<LocationPoint> locationPoints;
  
  // Calculated metrics
  double get totalDistanceMeters {
    if (locationPoints.length < 2) return 0;
    double distance = 0;
    for (int i = 1; i < locationPoints.length; i++) {
      distance += locationPoints[i - 1].distanceTo(locationPoints[i]);
    }
    return distance;
  }

  double get totalDistanceKm => totalDistanceMeters / 1000;

  Duration get duration {
    if (endTime == null) {
      return DateTime.now().difference(startTime);
    }
    return endTime!.difference(startTime);
  }

  double get averageSpeedKmh {
    final totalDistance = totalDistanceKm;
    final totalHours = duration.inMilliseconds / (1000 * 60 * 60);
    if (totalHours <= 0) return 0;
    return totalDistance / totalHours;
  }

  double get averagePaceMinKm {
    final avgSpeed = averageSpeedKmh;
    if (avgSpeed <= 0) return 0;
    return 60 / avgSpeed;
  }

  double get maxSpeedKmh {
    double maxSpeed = 0;
    for (final point in locationPoints) {
      if (point.speed != null && point.speed! > maxSpeed) {
        maxSpeed = point.speed!;
      }
    }
    return maxSpeed;
  }

  /// Get pace for current speed in min/km
  static double speedToPace(double speedKmh) {
    if (speedKmh <= 0) return 0;
    return 60 / speedKmh;
  }

  /// Get current speed from most recent location points
  double get currentSpeedKmh {
    if (locationPoints.length < 2) return 0;
    final last = locationPoints.last;
    if (last.speed != null) return last.speed! * 3.6; // m/s to km/h
    
    // Calculate from last two points
    final secondLast = locationPoints[locationPoints.length - 2];
    final distance = secondLast.distanceTo(last);
    final timeDiff = last.timestamp.difference(secondLast.timestamp).inMilliseconds / 1000; // seconds
    if (timeDiff <= 0) return 0;
    return (distance / timeDiff) * 3.6; // m/s to km/h
  }

  /// Get current pace in min/km
  double get currentPaceMinKm => speedToPace(currentSpeedKmh);

  /// Check if run is active (not ended)
  bool get isActive => endTime == null;

  /// Create a new active run session
  RunSession.newSession() : 
    id = DateTime.now().millisecondsSinceEpoch.toString(),
    startTime = DateTime.now(),
    endTime = null,
    locationPoints = [];

  /// Add a new location point to the session
  void addLocationPoint(LocationPoint point) {
    locationPoints.add(point);
  }

  /// End the run session
  void endSession() {
    endTime = DateTime.now();
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'locationPoints': locationPoints.map((p) => p.toJson()).toList(),
  };

  /// Create from JSON
  factory RunSession.fromJson(Map<String, dynamic> json) {
    final session = RunSession.newSession();
    session.id = json['id'] as String;
    session.startTime = DateTime.parse(json['startTime'] as String);
    session.endTime = json['endTime'] != null 
        ? DateTime.parse(json['endTime'] as String) 
        : null;
    
    final points = (json['locationPoints'] as List<dynamic>).map(
      (p) => LocationPoint.fromJson(p as Map<String, dynamic>)
    ).toList();
    
    // Use reflection to set the final field (not ideal but works for this use case)
    // In production, we'd use a different approach
    session.locationPoints.clear();
    session.locationPoints.addAll(points);
    
    return session;
  }

  @override
  String toString() => 'RunSession(id: $id, start: $startTime, end: $endTime, distance: ${totalDistanceKm.toStringAsFixed(2)} km, duration: $duration)';
}

/// Statistics for displaying run information
class RunStatistics {
  final double distanceKm;
  final Duration duration;
  final double averageSpeedKmh;
  final double averagePaceMinKm;
  final double maxSpeedKmh;

  RunStatistics({
    required this.distanceKm,
    required this.duration,
    required this.averageSpeedKmh,
    required this.averagePaceMinKm,
    required this.maxSpeedKmh,
  });

  /// Format duration as HH:MM:SS
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'.substring(0, 8);
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'.substring(0, 5);
  }

  /// Format pace as MM:SS
  String get formattedPace {
    final minutes = averagePaceMinKm.floor();
    final seconds = ((averagePaceMinKm - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format speed
  String get formattedSpeed => averageSpeedKmh.toStringAsFixed(1);

  /// Format distance
  String get formattedDistance => distanceKm.toStringAsFixed(2);

  /// Create from a run session
  factory RunStatistics.fromRunSession(RunSession session) {
    return RunStatistics(
      distanceKm: session.totalDistanceKm,
      duration: session.duration,
      averageSpeedKmh: session.averageSpeedKmh,
      averagePaceMinKm: session.averagePaceMinKm,
      maxSpeedKmh: session.maxSpeedKmh,
    );
  }
}
