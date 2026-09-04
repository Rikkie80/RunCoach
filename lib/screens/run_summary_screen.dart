import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/run_session.dart';
import '../widgets/stat_card.dart';
import 'package:share_plus/share_plus.dart';

/// Screen showing summary of a completed run
class RunSummaryScreen extends StatelessWidget {
  final RunSession? session;

  const RunSummaryScreen({super.key, this.session});

  @override
  Widget build(BuildContext context) {
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Run Summary')),
        body: const Center(
          child: Text('No run data available'),
        ),
      );
    }

    final stats = RunStatistics.fromRunSession(session!);
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareRunSummary(context, session!, stats),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date and time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today, size: 48, color: Colors.green),
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(session!.startTime),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Started at ${timeFormat.format(session!.startTime)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    if (session!.endTime != null)
                      Text(
                        'Ended at ${timeFormat.format(session!.endTime!)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Main statistics
            const Text(
              'Run Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatCard(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: '${stats.formattedDistance} km',
                  color: Colors.green,
                  isLarge: true,
                ),
                StatCard(
                  icon: Icons.timer,
                  label: 'Duration',
                  value: stats.formattedDuration,
                  color: Colors.blue,
                  isLarge: true,
                ),
                StatCard(
                  icon: Icons.speed,
                  label: 'Avg Speed',
                  value: '${stats.formattedSpeed} km/h',
                  color: Colors.purple,
                ),
                StatCard(
                  icon: Icons.timer,
                  label: 'Avg Pace',
                  value: stats.formattedPace,
                  color: Colors.orange,
                ),
                StatCard(
                  icon: Icons.speed,
                  label: 'Max Speed',
                  value: '${session!.maxSpeedKmh.toStringAsFixed(1)} km/h',
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Additional details
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildDetailRow('Total Location Points', session!.locationPoints.length.toString()),
                    const Divider(height: 1),
                    _buildDetailRow('Start Time', timeFormat.format(session!.startTime)),
                    if (session!.endTime != null) ...[
                      const Divider(height: 1),
                      _buildDetailRow('End Time', timeFormat.format(session!.endTime!)),
                    ],
                    const Divider(height: 1),
                    _buildDetailRow('Session ID', session!.id.substring(0, 8)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/history'),
                  icon: const Icon(Icons.history),
                  label: const Text('View History'),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home),
                  label: const Text('Go Home'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(value),
        ],
      ),
    );
  }

  /// Share run summary
  Future<void> _shareRunSummary(BuildContext context, RunSession session, RunStatistics stats) async {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    final text = '''
🏃‍♂️ Run Summary

Date: ${dateFormat.format(session.startTime)}
Time: ${timeFormat.format(session.startTime)} - ${session.endTime != null ? timeFormat.format(session.endTime!) : 'Now'}

📊 Statistics:
• Distance: ${stats.formattedDistance} km
• Duration: ${stats.formattedDuration}
• Average Speed: ${stats.formattedSpeed} km/h
• Average Pace: ${stats.formattedPace}/km
• Max Speed: ${session.maxSpeedKmh.toStringAsFixed(1)} km/h

Shared via Run Coach
''';

    try {
      await Share.share(text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }
}
