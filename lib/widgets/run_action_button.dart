import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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
    debugPrint('[RunActionButton] Building - isRunActive: $isRunActive');
    debugPrint('[RunActionButton] onStart: ${onStart != null}');
    debugPrint('[RunActionButton] onStop: ${onStop != null}');
    
    return FloatingActionButton(
      onPressed: () {
        debugPrint('[RunActionButton] FAB pressed - isRunActive: $isRunActive');
        if (isRunActive) {
          debugPrint('[RunActionButton] Calling onStop');
          onStop?.call();
        } else {
          debugPrint('[RunActionButton] Calling onStart');
          onStart?.call();
        }
      },
      backgroundColor: _getBackgroundColor(),
      foregroundColor: _getForegroundColor(),
      child: _getIcon(),
      tooltip: _getTooltip(),
      elevation: 4,
      shape: const CircleBorder(),
    );
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
