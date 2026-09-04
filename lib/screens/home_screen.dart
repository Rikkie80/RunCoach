import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/run_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/run_action_button.dart';

/// Home screen showing run history and quick start options
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunActive = ref.watch(isRunActiveProvider);
    final historyAsync = ref.watch(runHistoryProvider);
    final statsAsync = ref.watch(overallStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(runHistoryProvider);
          ref.refresh(overallStatisticsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quick action buttons
              _buildQuickActions(context, isRunActive, ref),
              const SizedBox(height: 24),
              
              // Overall statistics
              _buildOverallStats(context, statsAsync),
              const SizedBox(height: 24),
              
              // Recent runs
              _buildRecentRuns(context, historyAsync),
            ],
          ),
        ),
      ),
      floatingActionButton: RunActionButton(
        isRunActive: isRunActive,
        onStart: () async {
          final notifier = ref.read(currentRunSessionProvider.notifier);
          final success = await notifier.startRun();
          if (success) {
            context.push('/run');
          }
        },
        onResume: () async {
          final notifier = ref.read(currentRunSessionProvider.notifier);
          await notifier.resumeRun();
          context.push('/run');
        },
        onStop: () async {
          final notifier = ref.read(currentRunSessionProvider.notifier);
          final session = await notifier.stopRun();
          if (session != null) {
            context.push('/run/summary', extra: session);
          }
        },
      ),
    );
  }

  /// Build quick action buttons
  Widget _buildQuickActions(BuildContext context, bool isRunActive, WidgetRef ref) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  context,
                  icon: Icons.play_arrow,
                  label: 'Start',
                  color: Colors.green,
                  onTap: isRunActive 
                    ? null 
                    : () async {
                        final notifier = ref.read(currentRunSessionProvider.notifier);
                        final success = await notifier.startRun();
                        if (success) {
                          context.push('/run');
                        }
                      },
                ),
                _buildQuickActionButton(
                  context,
                  icon: Icons.history,
                  label: 'History',
                  color: Colors.blue,
                  onTap: () => context.push('/history'),
                ),
                _buildQuickActionButton(
                  context,
                  icon: Icons.analytics,
                  label: 'Stats',
                  color: Colors.orange,
                  onTap: () => context.push('/history'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single quick action button
  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 32),
          style: IconButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            padding: const EdgeInsets.all(12),
            disabledBackgroundColor: Colors.grey.shade200,
            disabledForegroundColor: Colors.grey.shade400,
          ),
          onPressed: onTap,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: onTap != null ? color : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build overall statistics section
  Widget _buildOverallStats(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Overall Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading statistics: $error'),
          ),
          data: (stats) {
            if (stats['totalRuns'] == 0) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.running_with_errors_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No runs yet'),
                      const SizedBox(height: 4),
                      const Text('Start your first run to see statistics here!'),
                    ],
                  ),
                ),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatCard(
                  icon: Icons.directions_run,
                  label: 'Total Runs',
                  value: stats['totalRuns'].toString(),
                  color: Colors.blue,
                ),
                StatCard(
                  icon: Icons.straighten,
                  label: 'Total Distance',
                  value: '${(stats['totalDistanceKm'] as double).toStringAsFixed(2)} km',
                  color: Colors.green,
                ),
                StatCard(
                  icon: Icons.timer,
                  label: 'Total Time',
                  value: _formatDurationHours(Duration(
                    hours: (stats['totalTimeHours'] as double).floor(),
                    minutes: ((stats['totalTimeHours'] as double) % 1 * 60).floor(),
                  )),
                  color: Colors.orange,
                ),
                StatCard(
                  icon: Icons.speed,
                  label: 'Avg Speed',
                  value: '${(stats['averageSpeedKmh'] as double).toStringAsFixed(1)} km/h',
                  color: Colors.purple,
                ),
                StatCard(
                  icon: Icons.timer,
                  label: 'Avg Pace',
                  value: _formatPace(stats['averagePaceMinKm'] as double),
                  color: Colors.red,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Build recent runs section
  Widget _buildRecentRuns(BuildContext context, AsyncValue<List<RunSession>> historyAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Runs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/history'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading history: $error'),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('No runs yet'),
                      const SizedBox(height: 4),
                      const Text('Your run history will appear here'),
                    ],
                  ),
                ),
              );
            }

            // Show last 3 runs
            final recentSessions = sessions.take(3).toList();
            
            return Column(
              children: recentSessions.map((session) => _buildRunCard(context, session)).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Build a card for a single run
  Widget _buildRunCard(BuildContext context, RunSession session) {
    final stats = RunStatistics.fromRunSession(session);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push('/run/summary', extra: session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Date and time
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(session.startTime),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      timeFormat.format(session.startTime),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Distance
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.straighten, size: 20, color: Colors.green),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.formattedDistance} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Duration
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, size: 20, color: Colors.orange),
                    const SizedBox(height: 4),
                    Text(
                      stats.formattedDuration,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Pace
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.speed, size: 20, color: Colors.purple),
                    const SizedBox(height: 4),
                    Text(
                      stats.formattedPace,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  /// Format duration for display
  String _formatDurationHours(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Format pace for display
  String _formatPace(double paceMinKm) {
    if (paceMinKm <= 0) return '--:--';
    final minutes = paceMinKm.floor();
    final seconds = ((paceMinKm - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
