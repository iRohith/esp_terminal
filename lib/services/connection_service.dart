import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:esp_terminal/connectors/base_connector.dart';
import 'package:esp_terminal/connectors/none_connector.dart';
import 'package:esp_terminal/connectors/test_connector.dart';
import 'package:esp_terminal/modals/data_packet.dart';
import 'package:esp_terminal/services/data_service.dart';
import 'package:esp_terminal/services/log_service.dart';
import 'package:esp_terminal/services/settings_service.dart';
import 'package:esp_terminal/util/constants.dart';
import 'package:esp_terminal/util/routes.dart';
import 'package:esp_terminal/util/util.dart';
import 'package:get/get.dart';

class ConnectionService extends GetxService {
  /// Provides a static getter to access the [ConnectionService] instance.
  static ConnectionService get to => Get.find();

  /// Reference to the [DataService] for managing application data.
  final dataService = DataService.to;

  /// Reference to the [LogService] for logging events.
  final logService = LogService.to;

  /// The currently selected connection type (e.g., "BLE", "USB", "None").
  final connectionType = SettingsService.to.connectionType;

  /// Tracks the number of bytes received from the active connection.
  int numBytesReceived = 0;

  /// A map of available connector types.
  ///
  /// Keys are connector names (e.g., "BLE", "USB"), values are functions
  /// returning a new [BaseConnector] instance.
  final Map<String, BaseConnector Function()> connectors;

  /// GetX workers for reacting to state changes.
  Worker? _connectionTypeWorker, _connectedChangedWorker;

  /// Subscription to the incoming data stream from the active connector.
  StreamSubscription<DataPacket>? _dataStream;

  /// The currently active [BaseConnector] instance.
  /// Initialized to [NoneConnector] when no specific connection is active.
  BaseConnector _activeConnector = NoneConnector();

  /// Creates a [ConnectionService] instance.
  ///
  /// [connectors]: A map providing functions to create different [BaseConnector] instances.
  ConnectionService(this.connectors);

  /// Handles changes in the selected connection type.
  ///
  /// Disposes of the current connector, initializes a new one based on the
  /// selected [type], and attempts to establish a connection.
  void _handleConnectionChange(String? type) async {
    await disposeConnector(); // Clean up current connector resources.

    // Attempt to find and instantiate the new connector.
    if ((await tryFunc(() async {
          if (type != null) {
            printInfo(info: "Connecting to: $type");
            final fn = connectors[type]!; // Get the connector factory function.
            _activeConnector = fn(); // Create a new connector instance.
          } else {
            _activeConnector =
                NoneConnector(); // Use NoneConnector if no type selected.
          }
        }, name: "Find connector")).msg !=
        "Ok") {
      printError(info: "Error with: $type");
      reset(); // Reset service on error.
      return;
    }

    // Initialize the newly selected connector.
    if ((await tryFunc(
          _activeConnector.init,
          timeout: 5.seconds, // Set a timeout for initialization.
          name: "Init connector",
        )).msg !=
        "Ok") {
      reset();
      showSnackbar("Error", "Failed to initialize connector");
      return;
    }

    _connectedChangedWorker?.dispose(); // Dispose previous connection worker.
    // Listen for changes in the active connector's connected status.
    _connectedChangedWorker = ever(_activeConnector.connected, (
      connected,
    ) async {
      if (connected) {
        _start(); // Start data processing if connected.
      } else {
        connectionType.value = "None"; // Reset connection type if disconnected.
      }
    });

    // Attempt to connect using the active connector.
    if ((await tryFunc(
          _activeConnector.connect,
          timeout: 60.seconds, // Set a longer timeout for connection.
          name: "Connect connector",
        )).msg !=
        "Ok") {
      reset();
      showSnackbar("Error", "Failed to connect");
    }
  }

  /// Starts the data reading process from the active connector.
  ///
  /// Sets up listeners for incoming data packets and manages the data stream.
  void _start() {
    // Callback for handling received DataPackets.
    void handleDataPacket(DataPacket dp) {
      dataService.currentPacket.value =
          dp; // Update current packet in DataService.
      _activeConnector.connected.value =
          true; // Confirm connector is connected.
    }

    // Callback for when the data stream completes.
    void handleDataStreamDone() {
      printInfo(info: "$connectionType Data Done");
      _activeConnector.disconnect(); // Disconnect on stream completion.
    }

    // Callback for handling errors in the data stream.
    void handleDataStreamError(Object e, StackTrace st) {
      printError(info: "error in data stream: $e\n$st");
      _activeConnector.disconnect(); // Disconnect on stream error.
    }

    _dataStream?.cancel(); // Cancel any existing data stream.
    // Set up a new subscription to the active connector's read stream,
    // transforming raw bytes into DataPacket objects.
    _dataStream = _activeConnector
        .read()
        .transform(dataPacketTransformer())
        .listen(
          handleDataPacket,
          onError: handleDataStreamError,
          onDone: handleDataStreamDone,
          cancelOnError: true, // Automatically cancel on error.
        );

    // Navigate to the home screen if a connection type is selected.
    if (connectionType.value != null) {
      Get.offAllNamed(Routes.home);
    }
  }

  /// Disposes of the current connector and its associated resources.
  ///
  /// Cleans up stream subscriptions, GetX workers, and the active connector.
  /// Provides user feedback via a snackbar for actual hardware connectors.
  Future<void> disposeConnector() async {
    await tryFunc(() async {
      _connectedChangedWorker?.dispose(); // Dispose connection change worker.
      _connectedChangedWorker = null;
      _dataStream?.cancel(); // Cancel data stream subscription.
      _dataStream = null;
      await _activeConnector.disconnect(); // Disconnect from device.
      await _activeConnector.dispose(); // Dispose connector resources.

      // Show "Disconnected" snackbar for actual connectors.
      if (_activeConnector is! NoneConnector &&
          _activeConnector is! TestConnector) {
        showSnackbar("Disconnected", "");
      }
    }, name: "disposeConnector");
  }

  /// Resets the connection service to its initial state.
  ///
  /// Closes open dialogs and sets the `connectionType` back to `null`.
  void reset() {
    // Close all open GetX dialogs.
    while (Get.isDialogOpen == true) {
      Get.back();
    }
    // Reset connection type, which triggers `_handleConnectionChange` to switch to `NoneConnector`.
    connectionType.value = null;
  }

  /// Called by GetX when the service is initialized.
  ///
  /// Sets up reactive listeners and periodic timers for monitoring connection statistics.
  @override
  void onInit() {
    super.onInit();

    // final speed = dataService.speed;
    // final latency = dataService.latency;
    // final varsPerSecond = dataService.varsPerSecond;
    //
    // int vars = 0; // Counter for variables received.
    // int lastPingMs = 0, lastUpdateMs = 0; // Timestamps for calculations.
    // final pings = <double>[]; // List to store recent ping times.
    //
    // final stopwatch = Stopwatch()..start(); // Stopwatch for elapsed time.
    //
    // // Listen for changes in the current data packet.
    // ever(dataService.currentPacket, (dp) {
    //   final ms = stopwatch.elapsedMilliseconds;
    //
    //   if (dp.cmd == FLOAT_RECV) {
    //     vars += 1; // Increment variable counter for float data.
    //   }
    //   else if (dp.cmd == PING) {
    //     pings.add(0.5 * (ms - lastPingMs)); // Calculate half round-trip time.
    //
    //     if (pings.length >= 5) {
    //       latency.value =
    //           pings.reduce((a, b) => a + b) / pings.length; // Average latency.
    //       pings.clear(); // Clear samples for next calculation.
    //     }
    //   }
    // });
    //
    // // Periodic timer to send pings and update statistics.
    // Timer.periodic(const Duration(milliseconds: 1000), (_) async {
    //   await writeDataPacket(DataPacket(cmd: PING, id: 0)); // Send ping packet.
    //   lastPingMs = stopwatch.elapsedMilliseconds; // Record ping time.
    //
    //   final s =
    //       1000.0 / (lastPingMs - lastUpdateMs); // Calculate updates per second.
    //   varsPerSecond.value = vars * s; // Calculate variables per second.
    //   speed.value =
    //       s * numBytesReceived / 1024; // Calculate data transfer speed in KB/s.
    //
    //   numBytesReceived = 0; // Reset byte counter.
    //   vars = 0; // Reset variable counter.
    //   lastUpdateMs = lastPingMs; // Update last update timestamp.
    // });

    _connectionTypeWorker?.dispose(); // Dispose previous worker.
    // Listen for connection type changes.
    _connectionTypeWorker = ever(connectionType, _handleConnectionChange);
    connectionType.refresh(); // Trigger initial handling.
  }

  /// Called by GetX when the service is closed.
  ///
  /// Ensures all resources are properly cleaned up.
  @override
  void onClose() {
    reset(); // Reset connection state.
    _connectionTypeWorker?.dispose(); // Dispose connection type worker.
    _connectionTypeWorker = null;

    super.onClose();
  }

  /// Writes a [DataPacket] to the connected device.
  ///
  /// Checks connection status, converts the packet to a byte buffer, writes it
  /// using the active connector, and logs the operation.
  ///
  /// [dp]: The [DataPacket] to be sent.
  /// Returns `true` if the entire buffer was successfully written, `false` otherwise.
  Future<bool> writeDataPacket(DataPacket dp) async {
    if (!_isConnectedAndReady()) {
      return false;
    }

    final buffer = dp.toBuffer(); // Convert DataPacket to byte buffer.
    final res = await _writeBuffer(buffer); // Write the buffer.
    _logDataPacketSendResult(dp, buffer.length, res); // Log the result.

    return res.result == buffer.length;
  }

  /// Checks if the service is connected and ready to write data.
  ///
  /// Returns `true` if a connection type is selected and the active connector
  /// is connected.
  bool _isConnectedAndReady() {
    return connectionType.value != null &&
        _activeConnector.connected.value == true;
  }

  /// Writes the given byte buffer using the current active connector.
  ///
  /// [buffer]: The [Uint8List] of bytes to write.
  /// Returns a [TryResponse] containing the number of bytes written or an error.
  Future<TryResponse<int>> _writeBuffer(Uint8List buffer) async {
    return await tryFunc<int>(() => _activeConnector.write(buffer));
  }

  /// Logs the result of sending a data packet.
  ///
  /// Avoids logging `PING` packets to keep logs clean.
  ///
  /// [dp]: The [DataPacket] that was attempted to be sent.
  /// [bufferLength]: The total length of the buffer.
  /// [result]: The [TryResponse] containing the outcome of the write operation.
  void _logDataPacketSendResult(
    DataPacket dp,
    int bufferLength,
    TryResponse<int> result,
  ) {
    if (dp.cmd == PING) {
      return; // Skip logging ping packets.
    }

    if (result.msg == "Ok") {
      final status = result.result != bufferLength
          ? "Partial(${result.result}) sent; "
          : "";
      LogService.to.logSend("$status$dp"); // Log successful or partial send.
    } else {
      LogService.to.logSend(
        "Failed => $dp; Error: ${result.msg}",
      ); // Log failed send.
    }
  }

  /// Writes a message string to the connected device.
  ///
  /// Encapsulates the message in a [DataPacket] with [MSG_SEND] command,
  /// converts it to bytes, and sends it.
  ///
  /// [msg]: The string message to send.
  /// [log]: If `true`, the send operation will be logged. Defaults to `true`.
  /// Returns `true` if the entire message was successfully written.
  Future<bool> writeMessage(String msg, {bool log = true}) async {
    // Create byte list for the message, including packet header.
    final bytes = DataPacket(
      cmd: MSG_SEND,
      id: 0,
      value: msg.length.toDouble(), // Message length in packet value.
    ).toBuffer().toList();
    bytes.addAll(utf8.encode(msg)); // Add actual message bytes.

    // Write combined bytes using the active connector.
    final res = await tryFunc<int>(
      () => _activeConnector.write(Uint8List.fromList(bytes)),
      name: "Write message",
    );

    // Log the send operation.
    if (res.result == bytes.length) {
      if (log) {
        LogService.to.logSend("Msg: $msg, Cmd: $MSG_SEND");
      }
    } else {
      LogService.to.logSend(
        "Failed => Msg: $msg, Cmd: $MSG_SEND; Error: ${res.msg}",
      );
    }

    return res.result == bytes.length;
  }

  /// Sends protected data (e.g., firmware update) to the connected device
  /// after password validation.
  ///
  /// Orchestrates password sending, validation, and then protected data transfer.
  ///
  /// [pwd]: The password string for validation.
  /// [bytes]: The [Uint8List] of protected data to send.
  /// Returns `true` if data was successfully sent after validation.
  Future<bool> sendProtected(String pwd, Uint8List? bytes) async {
    if (bytes == null) {
      showSnackbar("Error", "No file selected");
      return false;
    }

    // Send hashed password for validation.
    if (!await _sendPasswordForValidation(pwd)) {
      showSnackbar("Error", "Failed to validate password");
      return false;
    }

    // Show progress indicator during validation.
    showSnackbar(
      "Validating password...",
      "Waiting for response",
      showProgressIndicator: true,
      duration: const Duration(seconds: 10),
    );

    // Wait for device's validation response.
    final validationSuccessful = await _waitForPasswordValidationResponse(
      bytes,
    );

    return validationSuccessful;
  }

  /// Sends the hashed password to the connected device for validation.
  ///
  /// Hashes the password (SHA256) and prepends a `PASSWORD_SEND` command byte.
  ///
  /// [pwd]: The plain-text password string.
  /// Returns `true` if the password bytes were successfully sent.
  Future<bool> _sendPasswordForValidation(String pwd) async {
    // Hash password and convert to bytes.
    final pwdBytes = utf8
        .encode(sha256.convert(utf8.encode(pwd)).toString())
        .toList();
    pwdBytes.insert(0, PASSWORD_SEND); // Prepend command byte.

    // Write password bytes to active connector.
    final result = await tryFunc<int>(
      () => _activeConnector.write(Uint8List.fromList(pwdBytes)),
      name: "Send password",
    );

    return result.result == pwdBytes.length;
  }

  /// Waits for the password validation response from the connected device.
  ///
  /// Uses a `Completer` and GetX `once` worker to wait for `PASSWORD_VALID`
  /// or `PASSWORD_INVALID` packets. If valid, sends the protected [bytes].
  ///
  /// [bytes]: The [Uint8List] of protected data to send if validation is successful.
  /// Returns `true` if protected data was sent after validation, `false` otherwise.
  Future<bool> _waitForPasswordValidationResponse(Uint8List bytes) async {
    final completer = Completer<bool>(); // Signals async operation completion.
    Worker? worker; // GetX worker for single change listening.

    // Listen for the first relevant data packet.
    worker = once(
      dataService.currentPacket,
      (dp) async {
        final result = dp.cmd != PASSWORD_VALID
            ? TryResponse(-1, "Invalid password")
            : await _sendProtectedData(bytes); // Send data if password valid.

        if (result.result == bytes.length) {
          showSnackbar("Success", "Sent data");
          completer.complete(true); // Signal success.
        } else {
          showSnackbar("Error", result.msg);
          completer.complete(false); // Signal failure.
        }
        worker?.dispose(); // Dispose worker after response.
      },
      // Condition to react only to password validation commands.
      condition: () => [
        PASSWORD_VALID,
        PASSWORD_INVALID,
      ].contains(dataService.currentPacket.value.cmd),
    );

    // Wait for completer to complete with a timeout.
    return (await tryFunc(
          () => completer.future,
          showSnackBar: true,
          name: "Send protected",
          onTimeout: () {
            worker?.dispose(); // Dispose worker on timeout.
            return false;
          },
        )).result ??
        false;
  }

  /// Sends the protected data bytes to the connected device.
  ///
  /// [bytes]: The [Uint8List] of protected data to send.
  /// Returns a [TryResponse] indicating the result of the write operation.
  Future<TryResponse<int>> _sendProtectedData(Uint8List bytes) async {
    return await tryFunc<int>(
      () => _activeConnector.write(bytes),
      name: "Write protected",
    );
  }
}
