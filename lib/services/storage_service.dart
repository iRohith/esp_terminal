import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service for managing persistent storage to disk using SharedPreferences.
/// A service for managing persistent storage to disk using `shared_preferences`.
///
/// This service provides a convenient and type-safe way to save and load
/// various data types (primitives, lists of strings, and JSON-serializable objects)
/// to and from the device's local storage. It leverages `SharedPreferencesAsync`
/// for asynchronous operations, preventing UI freezes.
class StorageService extends GetxService {
  /// Provides a static getter to access the [StorageService] instance using GetX's dependency injection.
  /// This is a common pattern in GetX to easily retrieve a registered service from anywhere in the app.
  static StorageService get to => Get.find();

  /// A late final instance of `SharedPreferencesAsync` which will be initialized
  /// during the `onInit` lifecycle method. This handles the actual read/write operations.
  late final SharedPreferencesAsync _prefs;

  /// Initializes the `SharedPreferencesAsync` instance.
  ///
  /// This method is called automatically by GetX when the [StorageService] is
  /// first put into memory. It ensures that the storage mechanism is ready for use.
  @override
  void onInit() {
    super.onInit();

    _prefs = SharedPreferencesAsync();
  }

  /// Clears all saved data from persistent storage.
  ///
  /// This effectively resets all application settings and stored data.
  /// Returns a `Future<void>` that completes when the operation is done.
  Future<void> clear() => _prefs.clear();

  /// Checks if a key exists in persistent storage.
  ///
  /// [key]: The string key to check for.
  /// Returns a `Future<bool>` that resolves to `true` if the key is present, `false` otherwise.
  Future<bool> contains(String key) => _prefs.containsKey(key);

  /// Removes a specific key-value pair from persistent storage.
  ///
  /// [key]: The string key of the data to remove.
  /// Returns a `Future<void>` that completes when the operation is done.
  Future<void> remove(String key) => _prefs.remove(key);

  /// Saves a [value] with a named [key] to disk.
  ///
  /// The method intelligently determines the appropriate `SharedPreferences` setter
  /// based on the runtime type of the `value`. If the `value` is a custom object
  /// that has a `toJson()` method, it will be JSON-encoded and saved as a string.
  ///
  /// [key]: The unique string identifier for the data.
  /// [value]: The data to be saved. Can be `int`, `double`, `bool`, `String`, `List<String>`,
  ///          or any object with a `toJson()` method.
  /// Returns a `Future<void>` that completes when the value is successfully saved.
  Future<void> set(String key, dynamic value) {
    if (value == null) {
      return Future.value(); // Do nothing if the value is null.
    }

    // Use the appropriate setter based on the value's type.
    if (value is int) {
      return _prefs.setInt(key, value);
    } else if (value is double) {
      return _prefs.setDouble(key, value);
    } else if (value is bool) {
      return _prefs.setBool(key, value);
    } else if (value is String) {
      return _prefs.setString(key, value);
    } else if (value is List<String>) {
      return _prefs.setStringList(key, value);
    } else {
      // For custom objects, assume they have a `toJson()` method and encode them as JSON strings.
      return _prefs.setString(key, jsonEncode(value.toJson()));
    }
  }

  /// Loads a value with the [key] from disk.
  ///
  /// This method attempts to retrieve a value from `SharedPreferences` based on the
  /// expected type of `defaultValue`. If the key is not present, or if any error
  /// occurs during retrieval or deserialization, the `defaultValue` is returned.
  /// For custom objects, it assumes a `fromJson()` factory constructor.
  ///
  /// [key]: The string key of the data to load.
  /// [defaultValue]: The default value to return if the key is not found or an error occurs.
  ///                 Its type is used to infer the expected type of the stored value.
  /// Returns a `Future<T>` that resolves to the loaded value or the `defaultValue`.
  Future<T> get<T>(String key, T defaultValue) async {
    try {
      // Use the appropriate getter based on the defaultValue's type.
      if (defaultValue is int) {
        return (await _prefs.getInt(key) as T?) ?? defaultValue;
      } else if (defaultValue is double) {
        return (await _prefs.getDouble(key) as T?) ?? defaultValue;
      } else if (defaultValue is bool) {
        return (await _prefs.getBool(key) as T?) ?? defaultValue;
      } else if (defaultValue is String) {
        return (await _prefs.getString(key) as T?) ?? defaultValue;
      } else if (defaultValue is List<String>) {
        return (await _prefs.getStringList(key) as T?) ?? defaultValue;
      } else {
        // For custom objects, decode the JSON string and use the `fromJson` factory.
        // The `(T as dynamic).fromJson` is a type-safe way to call the factory constructor.
        return (T as dynamic).fromJson(
          jsonDecode(
            (await _prefs.getString(key))!,
          ), // Decode the stored JSON string.
        );
      }
    } catch (e, st) {
      // Log any errors that occur during retrieval or deserialization.
      printError(info: "Error: $e;\nStack Trace: $st;");
      return defaultValue; // Return the default value on error.
    }
  }
}