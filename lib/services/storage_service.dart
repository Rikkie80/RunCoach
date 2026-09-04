import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/run_session.dart';

/// Service for storing and retrieving run sessions
class StorageService {
  static final StorageService _instance = StorageService._internal();
  
  factory StorageService() => _instance;
  
  StorageService._internal();

  String? _storagePath;
  final String _fileName = 'run_sessions.json';

  /// Initialize storage service
  Future<bool> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _storagePath = directory.path;
      return true;
    } catch (e) {
      print('Failed to initialize storage: $e');
      return false;
    }
  }

  /// Get the storage file path
  String get _filePath => path.join(_storagePath ?? '', _fileName);

  /// Save a run session
  Future<bool> saveRunSession(RunSession session) async {
    try {
      if (_storagePath == null) {
        await initialize();
      }

      final sessions = await _loadAllSessions();
      
      // Remove existing session with same ID if it exists
      sessions.removeWhere((s) => s.id == session.id);
      
      // Add the new session
      sessions.add(session);
      
      // Sort by start time (newest first)
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      // Save all sessions
      await _saveAllSessions(sessions);
      
      return true;
    } catch (e) {
      print('Failed to save run session: $e');
      return false;
    }
  }

  /// Delete a run session
  Future<bool> deleteRunSession(String sessionId) async {
    try {
      if (_storagePath == null) {
        await initialize();
      }

      final sessions = await _loadAllSessions();
      final initialCount = sessions.length;
      
      sessions.removeWhere((s) => s.id == sessionId);
      
      if (sessions.length == initialCount) {
        return false; // Session not found
      }
      
      await _saveAllSessions(sessions);
      return true;
    } catch (e) {
      print('Failed to delete run session: $e');
      return false;
    }
  }

  /// Get all run sessions
  Future<List<RunSession>> getAllRunSessions() async {
    try {
      if (_storagePath == null) {
        await initialize();
      }
      return await _loadAllSessions();
    } catch (e) {
      print('Failed to load run sessions: $e');
      return [];
    }
  }

  /// Get a specific run session by ID
  Future<RunSession?> getRunSession(String sessionId) async {
    try {
      final sessions = await getAllRunSessions();
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      print('Failed to get run session: $e');
      return null;
    }
  }

  /// Get statistics for all runs
  Future<Map<String, dynamic>> getOverallStatistics() async {
    try {
      final sessions = await getAllRunSessions();
      
      if (sessions.isEmpty) {
        return {
          'totalRuns': 0,
          'totalDistanceKm': 0.0,
          'totalTimeHours': 0.0,
          'averageDistanceKm': 0.0,
          'averageSpeedKmh': 0.0,
          'averagePaceMinKm': 0.0,
        };
      }

      double totalDistance = 0;
      Duration totalDuration = Duration.zero;
      double totalSpeed = 0;
      int runCount = 0;

      for (final session in sessions) {
        totalDistance += session.totalDistanceKm;
        totalDuration += session.duration;
        totalSpeed += session.averageSpeedKmh;
        runCount++;
      }

      final totalTimeHours = totalDuration.inMilliseconds / (1000 * 60 * 60);
      final averageDistance = totalDistance / runCount;
      final averageSpeed = totalSpeed / runCount;
      final averagePace = runCount > 0 ? 60 / averageSpeed : 0;

      return {
        'totalRuns': runCount,
        'totalDistanceKm': totalDistance,
        'totalTimeHours': totalTimeHours,
        'averageDistanceKm': averageDistance,
        'averageSpeedKmh': averageSpeed,
        'averagePaceMinKm': averagePace,
      };
    } catch (e) {
      print('Failed to get overall statistics: $e');
      return {
        'totalRuns': 0,
        'totalDistanceKm': 0.0,
        'totalTimeHours': 0.0,
        'averageDistanceKm': 0.0,
        'averageSpeedKmh': 0.0,
        'averagePaceMinKm': 0.0,
      };
    }
  }

  /// Load all sessions from file
  Future<List<RunSession>> _loadAllSessions() async {
    final file = File(_filePath);
    
    if (!await file.exists()) {
      return [];
    }

    try {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content) as List<dynamic>;
      
      return jsonData.map((json) => RunSession.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Failed to parse run sessions: $e');
      return [];
    }
  }

  /// Save all sessions to file
  Future<bool> _saveAllSessions(List<RunSession> sessions) async {
    try {
      final jsonData = sessions.map((s) => s.toJson()).toList();
      final content = jsonEncode(jsonData);
      
      final file = File(_filePath);
      await file.writeAsString(content);
      
      return true;
    } catch (e) {
      print('Failed to save all sessions: $e');
      return false;
    }
  }

  /// Export sessions to a backup file
  Future<bool> exportToBackup() async {
    try {
      if (_storagePath == null) {
        await initialize();
      }

      final sessions = await getAllRunSessions();
      final jsonData = sessions.map((s) => s.toJson()).toList();
      final content = jsonEncode(jsonData);
      
      final backupPath = path.join(_storagePath!, 'runcoach_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      final backupFile = File(backupPath);
      await backupFile.writeAsString(content);
      
      return true;
    } catch (e) {
      print('Failed to export backup: $e');
      return false;
    }
  }

  /// Import sessions from a backup file
  Future<bool> importFromBackup(String filePath) async {
    try {
      if (_storagePath == null) {
        await initialize();
      }

      final backupFile = File(filePath);
      if (!await backupFile.exists()) {
        return false;
      }

      final content = await backupFile.readAsString();
      final jsonData = jsonDecode(content) as List<dynamic>;
      
      final importedSessions = jsonData.map(
        (json) => RunSession.fromJson(json as Map<String, dynamic>)
      ).toList();

      // Merge with existing sessions
      final existingSessions = await _loadAllSessions();
      existingSessions.addAll(importedSessions);
      
      // Remove duplicates by ID
      final uniqueSessions = <RunSession>{};
      for (final session in existingSessions) {
        uniqueSessions.add(session);
      }
      
      await _saveAllSessions(uniqueSessions.toList());
      
      return true;
    } catch (e) {
      print('Failed to import backup: $e');
      return false;
    }
  }

  /// Clear all data
  Future<bool> clearAllData() async {
    try {
      if (_storagePath == null) {
        await initialize();
      }

      final file = File(_filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      return true;
    } catch (e) {
      print('Failed to clear data: $e');
      return false;
    }
  }
}
