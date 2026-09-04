import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/run_provider.dart';
import '../models/run_session.dart';
import '../widgets/stat_card.dart';

/// Screen showing run history with filtering and sorting options
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _filter = 'all';
  String _sortBy = 'date_desc';
  
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(runHistoryProvider);
    final statsAsync = ref.watch(overallStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Overall statistics
          _buildOverallStats(context, statsAsync),
          const Divider(height: 1),
          
          // History list
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error loading history: $error'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.refresh(runHistoryProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text('No runs yet'),
                        const SizedBox(height: 4),
                        const Text('Your completed runs will appear here'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Start Your First Run'),
                        ),
                      ],
                    ),
                  );
                }

                // Apply filtering and sorting
                final filteredSessions = _applyFilters(sessions);
                final sortedSessions = _applySorting(filteredSessions);

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(runHistoryProvider);
                    ref.refresh(overallStatisticsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: sortedSessions.length,
                    itemBuilder: (context, index) {
                      return _buildRunCard(context, sortedSessions[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build overall statistics section
  Widget _buildOverallStats(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading statistics: $error'),
      ),
      data: (stats) {
        if (stats['totalRuns'] == 0) {
          return const SizedBox(height: 1);
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceEvenly,
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
                value: _formatDurationHours(stats['totalTimeHours'] as double),
                color: Colors.orange,
              ),
              StatCard(
                icon: Icons.speed,
                label: 'Avg Speed',
                value: '${(stats['averageSpeedKmh'] as double).toStringAsFixed(1)} km/h',
                color: Colors.purple,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build a card for a single run
  Widget _buildRunCard(BuildContext context, RunSession session) {
    final stats = RunStatistics.fromRunSession(session);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => context.push('/run/summary', extra: session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Date
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
                  
                  // Stats
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(Icons.straighten, '${stats.formattedDistance} km', Colors.green),
                        _buildStatItem(Icons.timer, stats.formattedDuration, Colors.blue),
                        _buildStatItem(Icons.speed, stats.formattedPace, Colors.purple),
                      ],
                    ),
                  ),
                  
                  // Arrow
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              
              // Additional info
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${session.locationPoints.length} location points',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a stat item for the run card
  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Show filter dialog
  Future<void> _showFilterDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Runs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('All Runs'),
                value: 'all',
                groupValue: _filter,
                onChanged: (value) {
                  setState(() => _filter = value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('This Month'),
                value: 'month',
                groupValue: _filter,
                onChanged: (value) {
                  setState(() => _filter = value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('This Week'),
                value: 'week',
                groupValue: _filter,
                onChanged: (value) {
                  setState(() => _filter = value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('Longer than 5km'),
                value: 'long',
                groupValue: _filter,
                onChanged: (value) {
                  setState(() => _filter = value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('Shorter than 5km'),
                value: 'short',
                groupValue: _filter,
                onChanged: (value) {
                  setState(() => _filter = value!);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Show sort dialog
  Future<void> _showSortDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Runs'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Date (Newest First)'),
                value: 'date_desc',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('Date (Oldest First)'),
                value: 'date_asc',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('Distance (Longest First)'),
                value: 'distance_desc',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('Distance (Shortest First)'),
                value: 'distance_asc',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('Speed (Fastest First)'),
                value: 'speed_desc',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('Speed (Slowest First)'),
                value: 'speed_asc',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Apply filters to sessions
  List<RunSession> _applyFilters(List<RunSession> sessions) {
    final now = DateTime.now();
    
    switch (_filter) {
      case 'month':
        return sessions.where((session) {
          return session.startTime.year == now.year &&
                 session.startTime.month == now.month;
        }).toList();
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return sessions.where((session) => session.startTime.isAfter(weekAgo)).toList();
      case 'long':
        return sessions.where((session) => session.totalDistanceKm >= 5).toList();
      case 'short':
        return sessions.where((session) => session.totalDistanceKm < 5).toList();
      default:
        return sessions;
    }
  }

  /// Apply sorting to sessions
  List<RunSession> _applySorting(List<RunSession> sessions) {
    switch (_sortBy) {
      case 'date_asc':
        sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
        return sessions;
      case 'distance_desc':
        sessions.sort((a, b) => b.totalDistanceKm.compareTo(a.totalDistanceKm));
        return sessions;
      case 'distance_asc':
        sessions.sort((a, b) => a.totalDistanceKm.compareTo(b.totalDistanceKm));
        return sessions;
      case 'speed_desc':
        sessions.sort((a, b) => b.averageSpeedKmh.compareTo(a.averageSpeedKmh));
        return sessions;
      case 'speed_asc':
        sessions.sort((a, b) => a.averageSpeedKmh.compareTo(b.averageSpeedKmh));
        return sessions;
      default: // date_desc
        sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
        return sessions;
    }
  }

  /// Format duration for display
  String _formatDurationHours(double totalTimeHours) {
    final hours = totalTimeHours.floor();
    final minutes = ((totalTimeHours - hours) * 60).floor();
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
