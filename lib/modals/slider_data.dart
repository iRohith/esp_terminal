/// Represents the configuration data for a slider control.
///
/// Defines the slider's display name and its value range (minimum and maximum).
/// Supports serialization to and from JSON for saving and loading configurations.
class SliderData {
  /// The human-readable name of the slider, used for display in the UI.
  final String name;

  /// The minimum numerical value that the slider can represent.
  final double min;

  /// The maximum numerical value that the slider can represent.
  final double max;

  /// Constructs a [SliderData] instance.
  ///
  /// [name]: The required name of the slider.
  /// [min]: The minimum value of the slider (defaults to 0.0).
  /// [max]: The maximum value of the slider (defaults to 1.0).
  const SliderData({required this.name, this.min = 0.0, this.max = 1.0});

  /// Creates a new [SliderData] instance by copying existing values
  /// and optionally overriding specific properties.
  ///
  /// Returns a new [SliderData] instance with updated properties.
  SliderData copyWith({String? name, double? min, double? max}) {
    return SliderData(
      name: name ?? this.name,
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }

  /// Converts this [SliderData] instance into a JSON-compatible map.
  ///
  /// Used for serializing the slider configuration (e.g., for saving or transmission).
  Map<String, dynamic> toJson() {
    return {'name': name, 'min': min, 'max': max};
  }

  /// Creates a [SliderData] instance from a JSON map.
  ///
  /// Deserializes slider configurations from a JSON source, providing default
  /// values for `min` and `max` if missing.
  ///
  /// [json]: A map containing the slider's data.
  factory SliderData.fromJson(Map<String, dynamic> json) {
    return SliderData(
      name: json['name'] as String, // Extract 'name' as a string.
      // Extract 'min' as a double, providing a default of 0.0 if null.
      min: json['min']?.toDouble() ?? 0.0,
      // Extract 'max' as a double, providing a default of 1.0 if null.
      max: json['max']?.toDouble() ?? 1.0,
    );
  }
}
