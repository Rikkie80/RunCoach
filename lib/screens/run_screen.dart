import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../providers/run_provider.dart';
import '../models/run_session.dart';
import '../widgets/stat_display.dart';
import '../services/audio_feedback_service.dart';

/// Screen for active run tracking
class RunScreen extends ConsumerStatefulWidget {
  const RunScreen({super.key});

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends ConsumerState<RunScreen> {
  Timer? _updateTimer;
  DateTime? _lastMilestoneAnnouncement;
  double? _lastAnnouncedDistance;

  @override
  void initState() {
    super.initState();
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Update UI every second
      if (mounted) {
        setState(() {});
      }
      
      // Check for milestone announcements
      final session = ref.read(currentRunSessionProvider);
      if (session != null) {
        final distanceKm = session.totalDistanceKm;
        final distanceInt = distanceKm.floor();
        
        // Announce at each kilometer
        if (_lastAnnouncedDistance == null || 
            distanceInt > _lastAnnouncedDistance!.floor()) {
          final audioService = ref.read(audioFeedbackServiceProvider);
          audioService.announceDistance(distanceKm);
          audioService.announceMilestone(distanceKm);
          _lastAnnouncedDistance = distanceKm;
        }
        
        // Announce time every 5 minutes
        final now = DateTime.now();
        if (_lastMilestoneAnnouncement == null ||
            now.difference(_lastMilestoneAnnouncement!).inMinutes >= 5) {
          final audioService = ref.read(audioFeedbackServiceProvider);
          audioService.announceTime(session.duration);
          audioService.announceSpeed(session.averageSpeedKmh);
          _lastMilestoneAnnouncement = now;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentRunSessionProvider);
    final isPaused = session != null && !ref.read(locationServiceProvider).isTracking;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Run'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: isPaused ? null : () => _pauseRun(),
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () => _stopRun(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.2),
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
      body: session == null 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Main stats display
                Expanded(
                  child: _buildStatsDisplay(session),
                ),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (isPaused)
                        ElevatedButton.icon(
                          onPressed: () => _resumeRun(),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Resume'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _pauseRun(),
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      
                      ElevatedButton.icon(
                        onPressed: () => _stopRun(),
                        icon: const Icon(Icons.stop),
                        label: const Text('End Run'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Build the stats display
  Widget _buildStatsDisplay(RunSession session) {
    final stats = RunStatistics.fromRunSession(session);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Primary stats (large)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatDisplay.large(
                icon: Icons.straighten,
                label: 'Distance',
                value: '${stats.formattedDistance} km',
                color: Colors.green,
                unit: 'km',
              ),
              StatDisplay.large(
                icon: Icons.timer,
                label: 'Time',
                value: stats.formattedDuration,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Secondary stats (medium)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatDisplay.medium(
                icon: Icons.speed,
                label: 'Current Speed',
                value: '${session.currentSpeedKmh.toStringAsFixed(1)} km/h',
                color: Colors.purple,
              ),
              StatDisplay.medium(
                icon: Icons.timer,
                label: 'Current Pace',
                value: _formatPace(session.currentPaceMinKm),
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Additional stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatDisplay.small(
                icon: Icons.speed,
                label: 'Avg Speed',
                value: '${stats.formattedSpeed} km/h',
                color: Colors.purple,
              ),
              StatDisplay.small(
                icon: Icons.timer,
                label: 'Avg Pace',
                value: stats.formattedPace,
                color: Colors.orange,
              ),
              StatDisplay.small(
                icon: Icons.speed,
                label: 'Max Speed',
                value: '${session.maxSpeedKmh.toStringAsFixed(1)} km/h',
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Progress indicators
          _buildProgressIndicators(session),
          
          // Location info
          if (session.locationPoints.isNotEmpty)
            _buildLocationInfo(session),
        ],
      ),
    );
  }

  /// Build progress indicators
  Widget _buildProgressIndicators(RunSession session) {
    final distanceKm = session.totalDistanceKm;
    
    // Milestone progress
    List<Widget> milestones = [];
    
    // 5k milestone
    if (distanceKm < 5) {
      milestones.add(_buildMilestoneProgress('5K', distanceKm, 5));
    } else if (distanceKm < 10) {
      milestones.add(_buildMilestoneProgress('10K', distanceKm, 10));
    } else if (distanceKm < 21.1) {
      milestones.add(_buildMilestoneProgress('Half Marathon', distanceKm, 21.1));
    } else if (distanceKm < 42.2) {
      milestones.add(_buildMilestoneProgress('Marathon', distanceKm, 42.2));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Next Milestone',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (milestones.isNotEmpty) milestones.first,
      ],
    );
  }

  /// Build milestone progress indicator
  Widget _buildMilestoneProgress(String milestone, double currentDistance, double targetDistance) {
    final progress = (currentDistance / targetDistance).clamp(0.0, 1.0);
    final percentage = (progress * 100).toStringAsFixed(0);
    final remaining = (targetDistance - currentDistance).toStringAsFixed(2);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(milestone),
                Text('$remaining km to go'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: Colors.green,
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text('$percentage%'),
          ],
        ),
      ),
    );
  }

  /// Build location info display
  Widget _buildLocationInfo(RunSession session) {
    final lastPoint = session.locationPoints.last;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Info',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Latitude:', style: TextStyle(color: Colors.grey)),
                    Text(lastPoint.latitude.toStringAsFixed(6)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Longitude:', style: TextStyle(color: Colors.grey)),
                    Text(lastPoint.longitude.toStringAsFixed(6)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Accuracy:', style: TextStyle(color: Colors.grey)),
                    Text('${lastPoint.accuracy?.toStringAsFixed(1) ?? 'N/A'} m'),
                  ],
                ),
              ],
            ),
            if (lastPoint.altitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Altitude: ${lastPoint.altitude!.toStringAsFixed(1)} m'),
              ),
          ],
        ),
      ),
    );
  }

  /// Pause the run
  Future<void> _pauseRun() async {
    final notifier = ref.read(currentRunSessionProvider.notifier);
    await notifier.pauseRun();
    
    if (mounted) {
      setState(() {});
    }
  }

  /// Resume the run
  Future<void> _resumeRun() async {
    final notifier = ref.read(currentRunSessionProvider.notifier);
    await notifier.resumeRun();
    
    if (mounted) {
      setState(() {});
    }
  }

  /// Stop the run
  Future<void> _stopRun() async {
    // Show confirmation dialog
    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Run'),
        content: const Text('Are you sure you want to end your run?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Run'),
          ),
        ],
      ),
    );

    if (shouldStop == true) {
      final notifier = ref.read(currentRunSessionProvider.notifier);
      final session = await notifier.stopRun();
      
      if (session != null && mounted) {
        context.push('/run/summary', extra: session);
      }
    }
  }

  /// Format pace for display
  String _formatPace(double paceMinKm) {
    if (paceMinKm <= 0) return '--:--';
    final minutes = paceMinKm.floor();
    final seconds = ((paceMinKm - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
