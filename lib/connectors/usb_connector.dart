import 'dart:async';

import 'package:esp_terminal/connectors/base_connector.dart';
import 'package:esp_terminal/ui/widgets/select_device_dialog.dart';
import 'package:esp_terminal/util/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:get/get.dart';

/// Implements a connector for USB serial devices.
///
/// This class extends [BaseConnector] and manages USB serial communication,
/// including port discovery, connection, and data transfer using `flutter_libserialport`.
class UsbConnector extends BaseConnector {
  /// The currently connected USB serial port.
  ///
  /// This is `null` if no port is connected.
  SerialPort? _connectedPort;

  /// Subscription for the periodic scan of available USB ports.
  ///
  /// Used to update the list of devices dynamically and can be cancelled.
  StreamSubscription? _scanSubscription;

  /// Observable list of available USB devices.
  ///
  /// Each item is a tuple of (port name, device description).
  final devices = <(String, String)>[].obs;

  /// Initializes the USB connector by populating the initial list of available serial ports.
  ///
  /// Sets up a periodic scan to detect new or removed USB devices, ensuring the UI
  /// always displays an up-to-date list of connectable devices.
  /// Returns `true` on successful initialization.
  @override
  Future<bool> init() async {
    // Retrieve all currently available serial ports on the system.
    for (final port in await SerialPort.availablePorts) {
      // Add each port to the observable devices list.
      // The second element of the tuple (device description) is often empty for USB serial ports.
      devices.add((port, ""));
    }

    // Set up a periodic stream to scan for new or removed serial ports every 2 seconds.
    // This keeps the `devices` list updated in real-time.
    _scanSubscription =
        Stream.periodic(
          2.seconds, // Interval for scanning.
          (_) => SerialPort.availablePorts, // Function to get current ports.
        ).listen((results) async {
          // Process the results of the latest scan.
          for (final port in await results) {
            // Check if the newly found port is already in our list.
            final idx = devices.indexWhere((v) => v.$1 == port);

            // If the port is new, add it to the list.
            if (idx == -1) {
              devices.add((port, ""));
            } else {
              // If the port already exists, update its entry.
              // This handles cases where a device might be re-enumerated or its properties change.
              devices[idx] = (port, "");
            }
          }
        });

    // Log the number of discovered ports for debugging purposes.
    printInfo(info: "Ports length: ${devices.length}");

    return true; // Initialization successful.
  }

  /// Disposes of the USB connector's resources.
  ///
  /// Cancels the periodic scan subscription to prevent memory leaks and
  /// ensures no further port scanning occurs. Returns `true` on successful disposal.
  @override
  Future<bool> dispose() async {
    // Cancel the periodic scan subscription to stop monitoring for new USB devices.
    _scanSubscription?.cancel();
    return true; // Indicate successful disposal.
  }

  /// Initiates the connection process to a USB serial device.
  ///
  /// Displays a dialog for the user to select an available USB device.
  /// Upon selection, it attempts to open the serial port and configure its baud rate.
  /// Returns `true` if connection is successful, `false` otherwise.
  @override
  Future<bool> connect() async {
    try {
      // Display a dialog to allow the user to select a USB device from the `devices` list.
      // The `connected.value` will be updated based on the dialog's outcome.
      connected.value =
          true ==
          await Get.dialog(
            SelectDeviceDialog(
              name: "USB device", // Title of the selection dialog.
              devices: devices, // List of available USB devices.
              connectCallback: (p, _) async {
                // This callback is executed when the user selects a device.
                try {
                  // Create a SerialPort instance using the selected port path.
                  final conn = SerialPort(p);

                  // Attempt to open the serial port for both reading and writing.
                  // `tryFunc` is used to safely execute this operation and handle potential native errors.
                  String msg = (await tryFunc(
                    conn.openReadWrite,
                    name: "USB openReadWrite",
                  )).msg;
                  // If the port could not be opened, throw an exception.
                  if (msg != "Ok") {
                    throw Exception(msg);
                  }

                  // Attempt to retrieve the current configuration of the serial port.
                  // If fetching the config fails (e.g., port not fully initialized), use a default configuration.
                  final cfg =
                      (await tryFunc(
                        () => conn.config,
                        name: "USB Get Config",
                      )).result ??
                      SerialPortConfig();

                  // Set the baud rate for the serial port to 115200.
                  // This is a common baud rate for communication with microcontrollers.
                  // Mismatched baud rates will lead to corrupted data.
                  msg = (await tryFunc(
                    () => conn.setConfig(cfg..baudRate = 115200),
                    name: "USB Set Config",
                  )).msg;
                  // If setting the configuration fails, throw an exception.
                  if (msg != "Ok") {
                    throw Exception(msg);
                  }

                  // Store the successfully connected port instance.
                  _connectedPort = conn;
                  // Close the dialog and return `true` to indicate a successful connection.
                  Get.back(result: true);
                } catch (e, st) {
                  // Catch and log any errors that occur during the connection attempt within the dialog.
                  printError(info: "USB Connect Callback error: $e\n$st");
                  // Close the dialog and return `false` to indicate a failed connection.
                  Get.back(result: false);
                }
              },
            ),
          );
      return connected
          .value; // Return the final connection status (true if connected, false otherwise).
    } catch (e, st) {
      // Catch and log any errors that occur during the overall connection process,
      // for example, if the dialog itself fails to open.
      printError(info: "USB connect error: $e\n$st");
      return false; // Indicate that the connection process failed.
    }
  }

  /// Disconnects from the currently connected USB serial device.
  ///
  /// Gracefully closes the serial port, disposes of native resources,
  /// and updates the connection status. Returns `true` on successful disconnection.
  @override
  Future<bool> disconnect() async {
    try {
      // Close the serial port to stop data flow.
      _connectedPort?.close();
      // Dispose of the serial port's native resources to release system handles.
      _connectedPort?.dispose();
      // Clear the reference to the connected port.
      _connectedPort = null;
      // Update the observable connection status to false.
      connected.value = false;
      return true; // Indicate successful disconnection.
    } catch (e, st) {
      // Catch and log any errors that occur during the disconnection process.
      printError(info: "USB dispose error: $e\n$st");
      return false; // Indicate that disconnection failed.
    }
  }

  /// Provides a stream for reading incoming data from the USB serial device.
  ///
  /// Creates a [SerialPortReader] for the connected port and returns a stream
  /// that emits individual bytes as integers. The `expand` method flattens
  /// incoming `Uint8List` chunks into a continuous stream of single bytes.
  /// Returns a [Stream<int>] where each integer is a received byte.
  @override
  Stream<int> read() {
    // Log a message indicating that data reading has started.
    printInfo(info: "Connected... Reading...");
    // Display a snackbar notification to the user confirming successful connection.
    showSnackbar("Connected", "Successfully connected to USB device.");

    // Create a SerialPortReader instance to read data from the active serial port.
    // The `!` asserts that `_connectedPort` is not null, as `read()` is only called when connected.
    SerialPortReader reader = SerialPortReader(_connectedPort!);
    // Return a stream that transforms incoming `Uint8List` chunks into a stream of individual bytes.
    // This is useful for processing data byte-by-byte, even if the underlying serial port
    // delivers data in larger blocks.
    return reader.stream.expand<int>((v) => v);
  }

  /// Writes a buffer of data to the USB serial device.
  ///
  /// Sends the provided [Uint8List] (raw bytes) to the connected USB serial port.
  /// This is the primary method for sending commands or data to the hardware.
  /// [buffer]: The data to be sent as a list of 8-bit unsigned integers.
  /// Returns the number of bytes successfully written, or -1 on error.
  @override
  Future<int> write(Uint8List buffer) async {
    try {
      // Write the entire byte buffer to the connected serial port.
      // The `!` operator asserts that `_connectedPort` is not null.
      return _connectedPort!.write(buffer);
    } catch (e, st) {
      // Catch and log any errors that occur during the write operation.
      printError(info: "USB Write error: $e\n$st");
      return -1; // Return -1 to indicate that the write operation failed.
    }
  }
}
