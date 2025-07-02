import 'dart:typed_data';

import 'package:get/get.dart';

/// Abstract base class for all communication connectors.
///
/// Defines a standardized interface for various communication methods
/// (e.g., Bluetooth Low Energy, USB) to ensure consistent interaction
/// with different hardware connection types.
abstract class BaseConnector {
  /// Initializes the connector.
  ///
  /// Performs necessary setup, such as requesting permissions or initializing
  /// native libraries.
  ///
  /// Returns `true` if initialization is successful, `false` otherwise.
  Future<bool> init();

  /// Disposes of all resources held by the connector.
  ///
  /// Releases system resources, closes streams, and unregisters listeners.
  ///
  /// Returns `true` if disposal is successful, `false` otherwise.
  Future<bool> dispose();

  /// Establishes a connection to a specific device.
  ///
  /// Handles the connection handshake and setup, which varies by connector type.
  ///
  /// Returns `true` if connection is successful, `false` if it fails.
  Future<bool> connect();

  /// Disconnects from the currently connected device.
  ///
  /// Gracefully terminates the active connection and updates status.
  ///
  /// Returns `true` if disconnection is successful.
  Future<bool> disconnect();

  /// Writes a buffer of data to the connected device.
  ///
  /// [buffer]: The data to be sent as a [Uint8List].
  /// Returns the number of bytes successfully written.
  Future<int> write(Uint8List buffer);

  /// Provides a stream of incoming data from the connected device.
  ///
  /// Emits individual bytes as they are received, allowing for continuous
  /// asynchronous data processing.
  Stream<int> read();

  /// An observable boolean indicating the current connection status.
  ///
  /// `true` if a device is actively connected, `false` otherwise.
  final connected = false.obs;
}
