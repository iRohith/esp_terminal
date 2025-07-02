import 'package:esp_terminal/modals/data_packet.dart';
import 'package:esp_terminal/services/storage_service.dart';
import 'package:get/get.dart';

/// A service for managing application runtime state data.
/// A service for managing application runtime state data using GetX observables.
///
/// This service acts as a central repository for various application-wide
/// data points that need to be reactive (i.e., trigger UI updates when they change)
/// and potentially persist across app sessions. It integrates with [StorageService]
/// for saving and loading data to/from disk.
class DataService extends GetxService {
  /// Provides a static getter to access the [DataService] instance using GetX's dependency injection.
  /// This is a common pattern in GetX to easily retrieve a registered service from anywhere in the app.
  static DataService get to => Get.find();

  /// Reference to the [StorageService] for handling persistent data storage.
  final storageService = StorageService.to;

  /// A private map to store all reactive (Rx) state variables.
  ///
  /// Keys are string identifiers for the variables, and values are GetX `Rx` objects
  /// (e.g., `RxDouble`, `RxString`, `RxList`, `Rx<DataPacket>`).
  final _rxvarMap = <String, dynamic>{};

  /// A stopwatch used for measuring elapsed time, primarily for performance metrics.
  final _stopwatch = Stopwatch()..start();

  /// Returns the elapsed time in seconds since the stopwatch started.
  double get seconds => _stopwatch.elapsedMilliseconds * 0.001;

  /// An observable representing the current data transfer speed (e.g., KB/s).
  /// It's marked `late final` because it's initialized once using the `get` method.
  /// `save: false` indicates this value is not persisted to disk.
  late final speed = get("speed", () => 0.0.obs, save: false);

  /// An observable representing the current communication latency (e.g., milliseconds).
  /// `save: false` indicates this value is not persisted to disk.
  late final latency = get("latency", () => 0.0.obs, save: false);

  /// An observable representing the number of variables received per second.
  /// `save: false` indicates this value is not persisted to disk.
  late final varsPerSecond = get("varsPerSecond", () => 0.0.obs, save: false);

  /// An observable representing the most recently received [DataPacket].
  /// This is crucial for real-time data display and processing.
  /// `save: false` indicates this value is not persisted to disk.
  late final currentPacket = get(
    "currentPacket",
    () => DataPacket().obs,
    save: false,
  );

  /// Clears all reactive state data managed by this service.
  ///
  /// It iterates through all stored `Rx` variables, closes their streams
  /// (disposing of their resources), and then clears the internal map.
  /// This is useful for resetting the application state.
  void reset() {
    for (final rx in _rxvarMap.values) {
      rx.close(); // Close the observable stream.
    }
    _rxvarMap.clear(); // Clear the map of observables.
  }

  /// Checks if a state variable with the given [key] exists in the service.
  ///
  /// [key]: The string identifier of the state variable.
  /// Returns `true` if the key is present, `false` otherwise.
  bool contains(String key) => _rxvarMap.containsKey(key);

  /// Retrieves a reactive state variable for a given [key].
  ///
  /// If the variable already exists, it returns the existing instance.
  /// If not, it creates a new instance using the provided `ctr` (constructor function),
  /// registers it, and optionally loads its value from disk and sets up debounced saving.
  ///
  /// [key]: The unique string identifier for the state variable.
  /// [ctr]: A function that returns a new instance of the reactive type (e.g., `() => 0.0.obs`).
  /// [save]: If `true`, the variable's value will be loaded from disk on creation
  ///         and saved back to disk whenever it changes (with a debounce to prevent excessive writes).
  ///         Defaults to `true`.
  /// Returns the reactive state variable of type [RxT].
  RxT get<RxT>(String key, RxT Function() ctr, {bool save = true}) {
    // If the variable already exists in the map, return it immediately.
    if (_rxvarMap.containsKey(key)) {
      return _rxvarMap[key];
    }

    // Create a new reactive instance using the provided constructor function.
    final rx = ctr();
    // Store the new instance in the map.
    _rxvarMap[key] = rx;

    // If `save` is true, handle loading from and saving to persistent storage.
    if (save) {
      try {
        // Load saved value from disk and assign to the reactive variable when loaded.
        // `(rx as dynamic).value` is used to access the underlying value of the Rx object.
        storageService.get(key, (rx as dynamic).value).then(rx.call);

        // Set up a debounce mechanism to save the value to disk occasionally whenever it changes.
        // `debounce` from GetX prevents rapid, consecutive writes by waiting for a short pause
        // in value changes before triggering the save operation.
        debounce(rx as dynamic, (v) => storageService.set(key, v));
      } catch (_) {
        // Catch any errors during storage operations (e.g., type mismatch during deserialization).
        // The `_` indicates that the error object is intentionally ignored here.
      }
    }

    return rx;
  }

  /// Removes a state variable from the service.
  ///
  /// This disposes of the reactive variable's resources and removes it from the internal map.
  ///
  /// [key]: The string identifier of the state variable to remove.
  void remove(String key) {
    // Dispose and remove the state variable from the map.
    // `?.close()` safely calls `close()` only if the removed item is not null.
    _rxvarMap.remove(key)?.close();
  }
}
