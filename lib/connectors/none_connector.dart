import 'dart:typed_data';

import 'package:esp_terminal/connectors/base_connector.dart';
import 'package:get/get.dart';

/// A placeholder connector that implements the [BaseConnector] interface
/// but performs no actual connection, disconnection, reading, or writing operations.
///
/// This connector is primarily used for testing, development, or as a default
/// when no specific hardware connection is required. It simulates successful
/// operations without interacting with any external devices.
class NoneConnector extends BaseConnector {
  /// Simulates a successful connection.
  ///
  /// Sets the `connected` status to `true` immediately without any actual
  /// connection process.
  @override
  Future<bool> connect() {
    connected.value = true; // Set the connection status to true.
    return Future.value(
      true,
    ); // Return a future that immediately completes with true.
  }

  /// Simulates a successful disconnection.
  ///
  /// Sets the `connected` status to `false` immediately without any actual
  /// disconnection process.
  @override
  Future<bool> disconnect() {
    connected.value = false; // Set the connection status to false.
    return Future.value(
      true,
    ); // Return a future that immediately completes with true.
  }

  /// Simulates successful disposal of resources.
  ///
  /// This method does nothing as there are no resources to dispose of for this connector.
  @override
  Future<bool> dispose() => Future.value(true); // Immediately return true as there are no resources to dispose.

  /// Simulates successful initialization.
  ///
  /// This method does nothing as no specific setup is required for this connector.
  @override
  Future<bool> init() => Future.value(true); // Immediately return true as no initialization is required.

  /// Provides a stream that never emits any data.
  ///
  /// This is a deliberate design choice for a "none" connector, ensuring that
  /// any part of the application listening for incoming data from this connector
  /// will not receive anything. The `skipWhile((_) => true)` effectively
  /// creates an empty stream that never yields elements.
  @override
  Stream<int> read() =>
      // Create a stream that never emits data, effectively an empty stream.
      Stream<int>.periodic(1000.minutes, (_) => 0).skipWhile((_) => true);

  /// Simulates a successful write operation.
  ///
  /// Returns the length of the provided [buffer] as if all bytes were
  /// successfully written, without actually sending any data.
  @override
  Future<int> write(Uint8List buffer) => Future.value(buffer.length); // Return the buffer length, simulating a successful write.
}
