import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:esp_terminal/connectors/base_connector.dart';
import 'package:esp_terminal/modals/data_packet.dart';
import 'package:esp_terminal/util/constants.dart';

/// A mock connector for testing purposes, extending the [BaseConnector].
///
/// This connector simulates a device connection and data exchange without
/// relying on actual hardware. It's invaluable for developing and testing
/// the application's UI and data handling logic independently of physical devices.
/// It can simulate sending various data packets and responding to specific
/// commands like password verification and ping requests.
class TestConnector extends BaseConnector {
  /// A simulated password hash. This is a SHA256 hash of the string "12345678".
  ///
  /// It's used to simulate a password verification process, where the application
  /// sends a password, and the "device" (this connector) checks if it matches
  /// this pre-defined hash.
  late final String _pwd = sha256.convert(utf8.encode("12345678")).toString();

  /// A buffer to hold data that is "pending" to be sent back to the application
  /// in response to a write operation.
  ///
  /// This simulates a device sending a response after receiving a command.
  /// Data added to this list will be yielded by the `read()` stream.
  final List<int> _pending = [];

  /// A stopwatch used to track elapsed time for simulating data generation patterns.
  ///
  /// This helps in creating time-based data variations, such as sine waves
  /// that evolve over time.
  final _stopwatch = Stopwatch();

  /// Initializes the test connector.
  ///
  /// This method does nothing specific as no actual hardware initialization
  /// is required for a mock connector. It immediately returns `true`,
  /// indicating it's always ready for simulated operations.
  @override
  Future<bool> init() {
    return Future.value(true);
  }

  /// Simulates connecting to a test device.
  ///
  /// When called, it resets and starts an internal stopwatch and sets the
  /// `connected` status to `true`. This simulates an instant and successful connection,
  /// allowing the `read()` stream to start generating data.
  @override
  Future<bool> connect() {
    _stopwatch.reset(); // Reset the stopwatch to 0.
    _stopwatch.start(); // Start the stopwatch to measure elapsed time.
    connected.value = true; // Update the observable connection status.
    return Future.value(true); // Indicate successful connection.
  }

  /// Simulates disconnecting from the test device.
  ///
  /// Sets the `connected` status to `false`, simulating an instant disconnection.
  /// This will cause the `read()` stream to stop generating data.
  @override
  Future<bool> disconnect() {
    connected.value = false; // Update the observable connection status.
    return Future.value(true); // Indicate successful disconnection.
  }

  /// Disposes of the test connector resources.
  ///
  /// This method does nothing specific as there are no external resources
  /// to clean up for this mock connector. It immediately returns `true`.
  @override
  Future<bool> dispose() {
    return Future.value(true);
  }

  /// Provides a stream of simulated incoming data from the test device.
  ///
  /// This method uses an `async*` generator to continuously yield simulated
  /// data packets as long as the connector is in a connected state. It generates
  /// random and patterned floating-point values, encapsulates them into `DataPacket`s,
  /// and then yields each byte of the packet.
  ///
  /// A novice developer can observe this stream to see how the application
  /// processes incoming data from a connected device, without needing actual hardware.
  ///
  /// Returns a [Stream<int>] where each integer represents a single byte of the simulated data.
  @override
  Stream<int> read() async* {
    final Random random =
        Random(); // Random number generator for simulated values.
    Uint8List buffer = Uint8List(
      PACKET_SIZE,
    ); // Buffer to hold the serialized data packet. `PACKET_SIZE` is a constant defining the size of a data packet.

    int i = 1; // Counter for simulating different data patterns and packet IDs.
    double x =
        0.0; // Variable for sine/cosine calculations, evolving over time.

    final DataPacket dp = DataPacket(
      cmd: 0,
      id: 0,
    ); // DataPacket object to be populated and sent. This represents the structure of data exchanged with the device.

    // Loop indefinitely, simulating continuous data transmission while connected.
    while (connected.value) {
      var val = random.nextDouble(); // Default: a random double value.

      // Simulate different data patterns based on the counter 'i'.
      // This adds variety to the simulated data for testing purposes,
      // allowing developers to test how the UI handles different data inputs.
      if (i == 0x3) {
        val = sin(
          x,
        ); // Simulate a sine wave, useful for testing chart visualizations.
      } else if (i == 0x5) {
        val =
            0.5 *
            (val * 0.3 +
                0.3 *
                    (1 + cos(x * 5))); // Simulate a more complex wave pattern.
      }

      // Populate the DataPacket with simulated command, ID, and value.
      dp.cmd =
          FLOAT_RECV; // Command indicating a float value is being received. `FLOAT_RECV` is a constant.
      dp.id = i++; // Increment the packet ID for each new packet.
      dp.value = val; // Assign the simulated value.

      dp.toBuffer(
        buffer: buffer,
      ); // Serialize the DataPacket into the byte buffer. This converts the structured data into raw bytes for transmission.

      // Yield each byte of the simulated data packet to the stream.
      // This simulates receiving data byte by byte from a serial connection.
      for (int i = 0; i < PACKET_SIZE; ++i) {
        yield buffer[i];
      }

      // If there's any pending data (e.g., responses to write operations), yield it.
      // This simulates the device sending a response back to the application.
      if (_pending.isNotEmpty) {
        for (int b in _pending) {
          yield b;
        }
        _pending.clear(); // Clear the pending buffer after yielding.
      }

      // Reset counter and update 'x' for the next cycle of data generation.
      // This ensures the simulated patterns repeat and evolve over time,
      // providing a dynamic data stream for testing.
      if (i > 10) {
        final ms = _stopwatch
            .elapsedMilliseconds; // Get elapsed milliseconds since connection.
        i = 1; // Reset packet ID counter.
        x =
            2 *
            pi *
            (ms * 0.001) /
            5; // Update 'x' based on elapsed time for wave simulation.
        await Future.delayed(
          const Duration(milliseconds: 10),
        ); // Simulate a small delay between packets to control data rate.
      }
    }

    yield -1; // When disconnected, yield -1 to signal the end of the stream or an error.
  }

  /// Simulates writing data to the test device.
  ///
  /// This method processes incoming data (simulating commands sent from the app
  /// to a device) and generates appropriate responses that are added to the
  /// `_pending` buffer, which will then be "read" by the application.
  /// It specifically handles simulated password verification and ping commands,
  /// demonstrating how the "device" would react to different commands.
  ///
  /// [buffer]: The data (command and payload) sent from the application to the simulated device.
  /// Returns the number of bytes "written" (processed), which is the length of the input buffer.
  @override
  Future<int> write(Uint8List buffer) async {
    final cmd = buffer[0]; // Extract the command byte from the incoming buffer.
    // The first byte of the packet is typically used as a command identifier in this protocol.

    // Simulate response for a password send command.
    if (cmd == PASSWORD_SEND) {
      // Introduce a delay to simulate network latency or device processing time.
      // This makes the simulated response more realistic for UI testing.
      Future.delayed(const Duration(seconds: 3), () {
        // Extract the password hash from the buffer (bytes 1 to 65).
        // `allowMalformed: true` is used for robustness in decoding, in case of malformed data.
        final receivedPwdHash = utf8.decode(
          buffer.sublist(1, 65),
          allowMalformed: true,
        );

        // Check if the provided password hash matches the simulated correct password.
        if (_pwd == receivedPwdHash) {
          // If valid, add a PASSWORD_VALID packet to the pending buffer.
          // This packet will be "read" by the application, signaling successful authentication.
          _pending.addAll(DataPacket(cmd: PASSWORD_VALID, id: 0).toBuffer());
        } else {
          // If invalid, add a PASSWORD_INVALID packet to the pending buffer.
          // This signals failed authentication to the application.
          _pending.addAll(DataPacket(cmd: PASSWORD_INVALID, id: 0).toBuffer());
        }
      });
    } else if (cmd == PING) {
      // Simulate response for a ping command.
      // Introduce a small delay to simulate a quick response time.
      Future.delayed(const Duration(milliseconds: 10), () {
        // Add the received ping packet (up to PACKET_SIZE) back to pending.
        // This simulates an echo response for a ping, confirming connectivity.
        _pending.addAll(buffer.take(PACKET_SIZE));
      });
    }

    return buffer
        .length; // Return the number of bytes "written" (processed) by this mock connector.
  }
}
