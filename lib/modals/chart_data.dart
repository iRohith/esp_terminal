import 'package:flutter/material.dart';

/// Represents a single variable that can be displayed on a chart.
///
/// Holds essential properties for a data series: unique identifier,
/// human-readable name, and color for visual representation.
class ChartVariable {
  /// Unique integer identifier for this chart variable.
  ///
  /// Crucial for distinguishing data series, especially from external sources.
  final int id;

  /// Display name of the variable, shown on chart legend or labels.
  final String name;

  /// Color used to draw the line or points for this variable on the chart.
  final Color color;

  /// Constructs a [ChartVariable] instance.
  const ChartVariable(this.id, this.name, this.color);

  /// Creates a new [ChartVariable] instance by copying existing values
  /// and optionally overriding specific properties.
  ///
  /// This is a common pattern for creating modified copies of immutable objects.
  /// Returns a new [ChartVariable] instance with updated properties.
  ChartVariable copyWith({int? id, Color? color, String? name}) {
    return ChartVariable(id ?? this.id, name ?? this.name, color ?? this.color);
  }

  /// Converts this [ChartVariable] instance into a JSON-compatible map.
  ///
  /// Used for serializing the object (e.g., for saving configurations).
  /// The color is converted to its ARGB integer representation.
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': color.toARGB32()};
  }

  /// Creates a [ChartVariable] instance from a JSON map.
  ///
  /// Used for deserializing the object (e.g., when loading configurations).
  /// Parses the JSON map and reconstructs a [ChartVariable] object.
  factory ChartVariable.fromJson(Map<String, dynamic> json) {
    return ChartVariable(
      json['id'] as int, // Extract 'id' as an integer.
      json['name'] as String, // Extract 'name' as a string.
      Color(
        json['color'] as int,
      ), // Reconstruct Color from its ARGB integer value.
    );
  }
}

/// Represents the complete configuration and data structure for a chart.
///
/// Encapsulates properties defining chart appearance and behavior, including
/// title, axis ranges, update intervals, and data variables.
class ChartData {
  /// Display name or title of the chart.
  final String name;

  /// Minimum value displayed on the Y-axis of the chart.
  final double minY;

  /// Maximum value displayed on the Y-axis of the chart.
  final double maxY;

  /// Maximum time duration (in seconds) visible on the X-axis.
  ///
  /// Data points older than this duration will scroll off the chart.
  final double maxDuration;

  /// Interval (in seconds) at which the chart's data is updated and redrawn.
  ///
  /// A smaller interval means more frequent updates and smoother real-time display.
  final double updateInterval;

  /// List of [ChartVariable] instances defining which data series are plotted.
  ///
  /// Each [ChartVariable] specifies an ID, name, and color.
  final List<ChartVariable> variables;

  /// Constructs a [ChartData] instance.
  const ChartData({
    required this.name,
    required this.variables,
    this.maxDuration = 10,
    this.updateInterval = 0.001,
    this.minY = 0.0,
    this.maxY = 1.0,
  });

  /// Creates a new [ChartData] instance by copying existing values
  /// and optionally overriding specific properties.
  ///
  /// Useful for modifying chart configurations without altering the original object.
  /// Returns a new [ChartData] instance with updated properties.
  ChartData copyWith({
    String? name,
    List<ChartVariable>? variables,
    double? maxDuration,
    double? updateInterval,
    double? minY,
    double? maxY,
  }) {
    return ChartData(
      name: name ?? this.name,
      variables: variables ?? this.variables,
      maxDuration: maxDuration ?? this.maxDuration,
      updateInterval: updateInterval ?? this.updateInterval,
      minY: minY ?? this.minY,
      maxY: maxY ?? this.maxY,
    );
  }

  /// Converts this [ChartData] instance into a JSON-compatible map.
  ///
  /// Used for serializing the chart configuration (e.g., for saving or transmission).
  /// Converts the list of [ChartVariable]s into their JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'maxDuration': maxDuration,
      'updateInterval': updateInterval,
      'minY': minY,
      'maxY': maxY,
      'variables': variables
          .map((v) => v.toJson())
          .toList(), // Convert each variable to JSON.
    };
  }

  /// Creates a [ChartData] instance from a JSON map.
  ///
  /// Used for deserializing chart configurations from a JSON source.
  /// Safely parses the map, providing default values if properties are missing.
  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      name: json['name'] as String,
      // Extract 'name' as a string.
      // Parse numerical values, providing default fallbacks if null.
      maxDuration: json['maxDuration']?.toDouble() ?? 10.0,
      updateInterval: json['updateInterval']?.toDouble() ?? 0.01,
      minY: json['minY']?.toDouble() ?? 0.0,
      maxY: json['maxY']?.toDouble() ?? 1.0,
      // Reconstruct the list of [ChartVariable] objects from their JSON representation.
      variables: (json['variables'] as List)
          .map((v) => ChartVariable.fromJson(v))
          .toList(),
    );
  }
}
