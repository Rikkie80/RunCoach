import 'package:flutter/material.dart';

/// A widget for displaying statistics with different sizes
class StatDisplay extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? unit;
  final StatSize size;

  const StatDisplay._({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.unit,
    required this.size,
  });

  /// Large stat display
  factory StatDisplay.large({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? unit,
  }) {
    return StatDisplay._(
      icon: icon,
      label: label,
      value: value,
      color: color,
      unit: unit,
      size: StatSize.large,
    );
  }

  /// Medium stat display
  factory StatDisplay.medium({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? unit,
  }) {
    return StatDisplay._(
      icon: icon,
      label: label,
      value: value,
      color: color,
      unit: unit,
      size: StatSize.medium,
    );
  }

  /// Small stat display
  factory StatDisplay.small({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? unit,
  }) {
    return StatDisplay._(
      icon: icon,
      label: label,
      value: value,
      color: color,
      unit: unit,
      size: StatSize.small,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(size);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: config.iconSize, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: config.valueSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (unit != null)
          Text(
            unit!,
            style: TextStyle(
              fontSize: config.unitSize,
              color: Colors.grey.shade600,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: config.labelSize,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Get configuration based on size
  _StatConfig _getConfig(StatSize size) {
    switch (size) {
      case StatSize.large:
        return const _StatConfig(
          iconSize: 32,
          valueSize: 28,
          unitSize: 14,
          labelSize: 12,
        );
      case StatSize.medium:
        return const _StatConfig(
          iconSize: 24,
          valueSize: 20,
          unitSize: 12,
          labelSize: 10,
        );
      case StatSize.small:
        return const _StatConfig(
          iconSize: 20,
          valueSize: 16,
          unitSize: 10,
          labelSize: 10,
        );
    }
  }
}

/// Size options for stat display
enum StatSize {
  large,
  medium,
  small,
}

/// Configuration for stat display
class _StatConfig {
  final double iconSize;
  final double valueSize;
  final double unitSize;
  final double labelSize;

  const _StatConfig({
    required this.iconSize,
    required this.valueSize,
    required this.unitSize,
    required this.labelSize,
  });
}
