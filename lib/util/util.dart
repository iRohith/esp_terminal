import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:esp_terminal/modals/data_packet.dart';
import 'package:esp_terminal/services/connection_service.dart';
import 'package:esp_terminal/services/log_service.dart';
import 'package:esp_terminal/util/constants.dart';
import 'package:get/get.dart';

/// Closes the currently open GetX snackbar, if any.
///
/// This is wrapped in a try-catch to prevent errors if no snackbar is open.
Future<void> closeSnackbar() async {
  try {
    await Get.closeCurrentSnackbar();
  } catch (_) {
    // Ignore errors if no snackbar is open.
  }
}

/// Formats a duration in seconds into a human-readable string (e.g., "1h 30m 15s").
///
/// [seconds]: The duration in seconds (double).
/// Returns a formatted string representing the duration.
String formatDuration(double seconds) {
  // Calculate hours, minutes, and remaining seconds.
  int hours = (seconds / 3600).floor();
  int minutes = ((seconds % 3600) / 60).floor();
  int secs = (seconds % 60).floor();

  List<String> parts = [];

  // Add hours if greater than 0.
  if (hours > 0) {
    parts.add('${hours}h');
  }
  // Add minutes if greater than 0.
  if (minutes > 0) {
    parts.add('${minutes}m');
  }
  // Include seconds if there are any, or if the total duration is less than a minute.
  if (secs > 0 || parts.isEmpty) {
    parts.add('${secs}s');
  }

  // Join the parts with a space.
  return parts.join(' ');
}

/// Generates a cryptographically secure random ID using SHA-256 hashing.
///
/// This ensures a high degree of uniqueness for generated IDs.
/// Returns a unique string ID.
String generateRandomId() {
  // Create a cryptographically secure random number generator.
  final random = Random.secure();

  // Generate a list of 16 random bytes.
  final randomBytes = List<int>.generate(16, (i) => random.nextInt(256));

  // Encode the random bytes into a base64 URL-safe string.
  final randomString = base64Url.encode(randomBytes);

  // Hash the random string using SHA-256 to create a unique ID.
  final bytes = utf8.encode(randomString);
  final digest = sha256.convert(bytes);

  // Return the hexadecimal representation of the hash.
  return digest.toString();
}

/// Creates a periodic stream where the period can be dynamically determined by a function.
///
/// This is useful for scenarios where the interval between stream events needs to change
/// based on some condition or calculation.
///
/// [period]: A function that returns the [Duration] for the next interval.
/// [fn]: A function that returns the value to be emitted by the stream.
/// Returns a [Stream] that emits values periodically based on the `period` function.
Stream<T> dynPeriodicStream<T>(Duration Function() period, T Function() fn) {
  int listenerCount = 0;
  bool startedListening = false;

  // Create a StreamController to manage the stream.
  final ctrl = StreamController<T>(
    // When the first listener subscribes, increment the count and mark as started.
    onListen: () {
      listenerCount++;
      startedListening = true;
    },
    // When a listener cancels its subscription, decrement the count.
    onCancel: () {
      listenerCount--;
    },
  );

  // Recursive function to emit values and schedule the next emission.
  void run() {
    // Add the value from the provided function to the stream.
    ctrl.add(fn());

    // If listening has started and there are no more listeners, close the stream.
    if (startedListening && listenerCount == 0) {
      ctrl.close();
    } else {
      // Schedule the next emission after the duration returned by the period function.
      Future.delayed(period(), run);
    }
  }

  // Start the first emission.
  run();

  // Return the stream managed by the controller.
  return ctrl.stream;
}

/// A [StreamTransformer] that converts a stream of integer bytes into a stream of [DataPacket] objects.
///
/// This transformer handles the byte-level parsing of incoming data based on defined command bytes
/// and packet structures, including special handling for message packets and BT Classic data.
StreamTransformer<int, DataPacket> dataPacketTransformer() {
  // Get instances of necessary services.
  final cs = ConnectionService.to;
  final ls = LogService.to;

  // Define the command bytes that indicate the start of a packet.
  final cmds = [FLOAT_RECV, PASSWORD_VALID, PASSWORD_INVALID, MSG_RECV, PING];

  // Buffer to store incoming bytes until a complete packet is formed.
  Uint8List buffer = Uint8List(1024);
  // Index for the current position in the buffer.
  int i = 0;
  // The current command byte being processed. Initialized to -1 (no command).
  int cmd = -1;

  // Stores the last received byte, used for detecting packet end markers (0xFF 0xFF).
  int lastByte = 0;
  // Buffer specifically for message packets, whose length is determined by the packet value.
  Uint8List? msgBuf;

  // Return a StreamTransformer with custom handlers for data, error, and done events.
  return StreamTransformer<int, DataPacket>.fromHandlers(
    handleData: (data, sink) {
      // If data is -1, it indicates the end of the stream, so close the sink.
      if (data == -1) {
        sink.close();
        return;
      }

      // Increment the count of received bytes in the ConnectionService.
      cs.numBytesReceived += 1;

      // Check if we are currently processing a known command packet.
      if (cmds.contains(cmd)) {
        // Special handling for message packets (MSG_RECV).
        if (cmd == MSG_RECV && msgBuf != null) {
          // If the message buffer is not full, add the current byte.
          if (i < msgBuf!.length) {
            msgBuf![i++] = data;

            // If the message buffer is now full, process the message.
            if (i == msgBuf!.length) {
              // Convert the bytes to a string and log it.
              final msg = String.fromCharCodes(msgBuf!);
              ls.logRecv(msg);
              // Optionally show a snackbar (commented out).
              // showSnackbar("Message received", msg);

              // Reset message buffer and command state.
              msgBuf = null;
              cmd = -1;
              i = 0;
            }
          }
        }
        // Check for the packet end marker (0xFF 0xFF).
        else if (data == 0xFF && lastByte == 0xFF) {
          // If the end marker is found, parse the buffered bytes into a DataPacket.
          final dp = DataPacket.fromBuffer(buffer);
          // Add the parsed DataPacket to the output stream.
          sink.add(dp);
          // Reset command state and buffer index.
          cmd = -1;
          i = 0;

          // If the parsed packet is a message packet (MSG_RECV) and has a valid length,
          // set up the message buffer for the incoming message bytes.
          if (dp.cmd == MSG_RECV && 0 < dp.value && dp.value < 1024) {
            cmd = dp.cmd;
            msgBuf = Uint8List(dp.value.toInt());
          }
        }
        // If the buffer is full before finding an end marker, reset the state (packet error).
        else if (i >= buffer.length) {
          cmd = -1;
          i = 0;
        }
        // Otherwise, add the current byte to the buffer.
        else {
          buffer[i++] = data;

          // Special handling for BT Classic: packets are fixed size (6 bytes after command).
          if (cs.connectionType.value == "BT Classic" && i == 6) {
            // Parse the fixed-size packet and add it to the output stream.
            sink.add(DataPacket.fromBuffer(buffer));
            // Reset command state and buffer index.
            cmd = -1;
            i = 0;
          }
        }
      }
      // If the current byte is a known command byte and we are not currently processing a command,
      // it indicates the start of a new packet.
      else if (cmds.contains(data)) {
        // Set the current command and add it as the first byte in the buffer.
        cmd = data;
        i = 0;
        buffer[i++] = cmd;
      }

      // Update the last received byte.
      lastByte = data;
    },
  );
}

/// A simple class to hold the result and a message from a function execution,
/// typically used with the `tryFunc` extension.
class TryResponse<T> {
  /// The result of the function execution, or null if an error occurred.
  final T? result;

  /// A message describing the outcome of the execution (e.g., "Ok", "Timeout", "Error").
  final String msg;

  /// Creates a new [TryResponse] instance.
  const TryResponse(this.result, this.msg);
}

/// Extension methods for the `dynamic` type, providing utility functions.
extension UtilExt on dynamic {
  /// Displays a GetX snackbar with the given title and message.
  ///
  /// This method is an extension on `dynamic` to allow easy access from any object.
  /// It first closes any existing snackbar before showing the new one.
  ///
  /// [title]: The title of the snackbar.
  /// [message]: The message content of the snackbar.
  /// [duration]: The duration for which the snackbar is displayed (defaults to 2 seconds).
  /// [showProgressIndicator]: Whether to show a progress indicator (defaults to false).
  /// Returns a [Future] that completes when the snackbar is shown.
  Future<void> showSnackbar(
    String title,
    String message, {
    Duration duration = const Duration(seconds: 2),
    bool showProgressIndicator = false,
  }) async {
    try {
      // Log the snackbar message.
      GetDynamicUtils(this).printInfo(info: "$title: $message");
      // Close any existing snackbar.
      await closeSnackbar();
      // Show the new snackbar using GetX.
      Get.snackbar(
        title.trim(),
        message.trim(),
        duration: duration,
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: showProgressIndicator,
        animationDuration: const Duration(milliseconds: 200),
      );
    } catch (_) {
      // Ignore errors if snackbar cannot be shown.
    }
  }

  /// Executes a function within a try-catch block with an optional timeout.
  ///
  /// This method provides a safe way to execute asynchronous or synchronous functions,
  /// handling potential errors and timeouts gracefully. It returns a [TryResponse]
  /// indicating the result or the error message.
  ///
  /// [fn]: The function to execute. Can be a [Future] or a synchronous function.
  /// [timeout]: The maximum duration to wait for the function to complete (defaults to 10 seconds).
  /// [name]: An optional name for the function, used in logging and error messages.
  /// [showSnackBar]: Whether to show a snackbar on timeout or error (defaults to false).
  /// [onTimeout]: An optional function to execute if a timeout occurs.
  /// Returns a [Future] that completes with a [TryResponse] containing the result of the function or an error message.
  Future<TryResponse<T>> tryFunc<T>(
    FutureOr<T>? Function() fn, {
    Duration timeout = const Duration(seconds: 10),
    String name = "",
    bool showSnackBar = false,
    Function()? onTimeout,
  }) async {
    // Log the start of the function execution if a name is provided.
    if (name.isNotEmpty) {
      GetDynamicUtils(this).printInfo(info: "tryFunc: $name");
    }
    try {
      // Execute the function.
      final fnRes = fn();
      // If the result is a Future, wait for it with a timeout. Otherwise, use the direct result.
      final result = fnRes is T
          ? fnRes
          : await (fnRes as Future<T>).timeout(timeout);
      // Return a successful response with the result.
      return TryResponse(result, "Ok");
    } on TimeoutException {
      // Handle timeout exception.
      if (onTimeout != null) {
        try {
          // Execute the onTimeout callback if provided.
          onTimeout();
        } catch (e, st) {
          // Log any errors occurring within the onTimeout callback.
          GetDynamicUtils(this).printError(info: "onTimeout error: $e\n$st");
        }
      }

      // Create a timeout message and log it.
      final msg = "$name timeout";
      GetDynamicUtils(this).printError(info: msg);
      // Show a snackbar if requested.
      if (showSnackBar) {
        tryFunc(() => showSnackbar("Error", msg));
      }
      // Return a response indicating timeout.
      return TryResponse(null, msg);
    } catch (e, st) {
      // Handle any other exceptions.
      // Log the error.
      GetDynamicUtils(this).printError(info: "$name error: $e\n$st");
      // Return a response indicating the error.
      return TryResponse(null, "Error: $e\n$st");
    }
  }
}
