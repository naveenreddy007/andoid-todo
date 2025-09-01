import 'package:flutter/material.dart';
import '../../domain/entities/priority.dart';

class PriorityColors {
  static const Map<Priority, Color> colors = {
    Priority.low: Colors.green,
    Priority.medium: Colors.orange,
    Priority.high: Colors.red,
    Priority.urgent: Colors.purple,
  };

  static Color getColor(Priority priority) {
    return colors[priority] ?? Colors.grey;
  }

  static Color getBackgroundColor(Priority priority) {
    final color = getColor(priority);
    return color.withOpacity(0.1);
  }

  static Color getBorderColor(Priority priority) {
    final color = getColor(priority);
    return color.withOpacity(0.3);
  }
}