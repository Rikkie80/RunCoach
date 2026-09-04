import 'package:flutter/material.dart';

/// A floating action button for run actions (start/stop)
class RunActionButton extends StatelessWidget {
  final bool isRunActive;
  final VoidCallback? onStart;
  final VoidCallback? onResume;
  final VoidCallback? onStop;

  const RunActionButton({
    super.key,
    required this.isRunActive,
    this.onStart,
    this.onResume,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _getOnPressed(),
      backgroundColor: _getBackgroundColor(),
      foregroundColor: _getForegroundColor(),
      child: _getIcon(),
      tooltip: _getTooltip(),
      elevation: 4,
      shape: const CircleBorder(),
    );
  }

  /// Get the onPressed callback
  VoidCallback? _getOnPressed() {
    if (isRunActive) {
      return onStop ?? onStop;
    }
    return onStart ?? onResume;
  }

  /// Get the background color
  Color _getBackgroundColor() {
    if (isRunActive) {
      return Colors.red;
    }
    return const Color(0xFF4CAF50); // Green
  }

  /// Get the foreground color
  Color _getForegroundColor() {
    return Colors.white;
  }

  /// Get the icon
  Widget _getIcon() {
    if (isRunActive) {
      return const Icon(Icons.stop, size: 32);
    }
    return const Icon(Icons.play_arrow, size: 32);
  }

  /// Get the tooltip
  String _getTooltip() {
    if (isRunActive) {
      return 'End Run';
    }
    return 'Start Run';
  }
}
