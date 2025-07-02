import 'dart:async';
import 'dart:typed_data';

import 'package:esp_terminal/connectors/base_connector.dart';
import 'package:esp_terminal/services/data_service.dart';
import 'package:esp_terminal/util/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_socket/web_socket.dart';

/// Implements a connector for WebSocket connections to cloud services.
///
/// This class extends [BaseConnector] and enables communication with a remote
/// server over WebSockets for data exchange or control.
class WSCloudConnector extends BaseConnector {
  /// Observable string storing the WebSocket URL for cloud connection.
  ///
  /// Retrieves the URL from [DataService] or defaults to a sample URL.
  final wsurl = DataService.to.get(
    "websocket_cloud_url",
    // () => "wss://sampleesp32.onrender.com/ws".obs,
    () => "wss://espterminal.azurewebsites.net/ws".obs
  );

  /// The WebSocket instance used for communication.
  ///
  /// This is `null` until a connection is successfully established.
  WebSocket? ws;

  /// Initializes the WebSocket cloud connector.
  ///
  /// No specific initialization is required as the connection is established
  /// dynamically in the `connect` method. Returns `true`.
  @override
  Future<bool> init() async {
    return true;
  }

  /// Disposes of the WebSocket connection and resources.
  ///
  /// Closes the WebSocket connection and nullifies the instance to prevent
  /// resource leaks. Returns `true` on successful disposal.
  @override
  Future<bool> dispose() async {
    // Close the WebSocket connection if it is currently open.
    ws?.close();
    // Clear the WebSocket instance to release resources.
    ws = null;
    return true; // Indicate that disposal was successful.
  }

  /// Establishes a connection to the WebSocket cloud service.
  ///
  /// Presents a dialog for the user to confirm or edit the WebSocket URL.
  /// Upon confirmation, attempts to connect and sends an initial "client" message.
  /// Returns `true` if connection is successful, `false` otherwise.
  @override
  Future<bool> connect() async {
    try {
      // Create a TextEditingController to manage the input field for the WebSocket URL.
      final ctrl = TextEditingController(text: wsurl.value);
      // Update the observable `wsurl` whenever the text in the controller changes,
      // ensuring synchronization with the stored URL in `DataService`.
      ctrl.addListener(() => wsurl.value = ctrl.text);
      // An observable boolean to track the connection status for UI feedback (e.g., loading indicator).
      final connecting = false.obs;

      // Display an AlertDialog to the user to confirm or modify the WebSocket URL.
      // The `connected.value` will be set based on the dialog's result.
      connected.value =
          true ==
          await Get.dialog(
            AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("WebSocket"),
                  // Dialog title.
                  // Show a CircularProgressIndicator if `connecting.value` is true.
                  Obx(
                    () => connecting.value
                        ? const CircularProgressIndicator()
                        : const SizedBox(),
                  ),
                ],
              ),
              content: TextField(
                controller: ctrl, // Bind the text field to the controller.
                decoration: const InputDecoration(
                  labelText: "URL", // Label for the input field.
                  border: OutlineInputBorder(), // Visual border for the input.
                ),
                keyboardType: TextInputType.url, // Suggest URL keyboard.
                maxLines: 1, // Single line input.
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    try {
                      connecting.value = true; // Set connecting status to true.
                      // Attempt to establish the WebSocket connection.
                      ws = await WebSocket.connect(Uri.parse(wsurl.value));
                      // Send an initial "client" message to the server for identification.
                      ws!.sendText("client");
                      // Close the dialog with a true result, indicating successful connection.
                      Get.back(result: true);
                    } catch (e, st) {
                      // Catch and log any errors during the connection attempt.
                      printError(info: "WS Connect Dialog error: $e\n$st");
                      // Close the dialog with a false result due to error.
                      Get.back(result: false);
                      // Clear the WebSocket instance on error to prevent using a broken connection.
                      ws = null;
                    } finally {
                      // Ensure connecting status is reset regardless of success or failure.
                      connecting.value = false;
                    }
                  },
                  child: const Text("Ok"), // Button to initiate connection.
                ),

                TextButton(
                  onPressed: () async {
                    // Close the dialog with a false result, indicating cancellation.
                    Get.back(result: false);
                  },
                  child: const Text("Cancel"), // Button to cancel connection.
                ),
              ],
            ),
          );
      // Ensure connecting status is reset after the dialog closes.
      connecting.value = false;
      return connected.value; // Return the final connection status.
    } catch (e, st) {
      // Catch and log any errors that occur before or during the dialog presentation.
      printError(info: "WS connect error: $e\n$st");
      return false; // Indicate that the overall connection process failed.
    }
  }

  /// Disconnects from the currently connected WebSocket cloud service.
  ///
  /// Attempts to close the WebSocket connection and updates the observable
  /// connection status. Returns `true` if disconnection is successful.
  @override
  Future<bool> disconnect() async {
    try {
      // Close the WebSocket connection if it's open.
      ws?.close();
      // Clear the WebSocket instance.
      ws = null;
      // Update the observable connection status to false.
      connected.value = false;
      return true; // Indicate successful disconnection.
    } catch (e, st) {
      // Catch and log any errors that occur during the disconnection process.
      printError(info: "WS dispose error: $e\n$st");
      return false; // Indicate that disconnection failed.
    }
  }

  /// Provides a stream for reading incoming data from the WebSocket cloud service.
  ///
  /// Listens to the WebSocket's event stream, processing text and binary data.
  /// Handles non-"Ok" text messages as errors and binary data as raw bytes.
  /// The `expand` method flattens `Uint8List` chunks into a stream of individual bytes.
  /// Returns a [Stream<int>] where each integer is a received byte.
  @override
  Stream<int> read() {
    // Log a message indicating that data reading has started.
    printInfo(info: "Connected... Reading...");
    // Display a snackbar notification to the user confirming successful connection.
    showSnackbar("Connected", "Successfully connected to WebSocket cloud.");

    // An empty Uint8List used as a default return for unhandled cases or when no data is yielded.
    final empty = Uint8List(0);

    // Listen to the WebSocket's event stream and transform each event into a `Uint8List`.
    return ws!.events
        .map<Uint8List>((e) {
          // Process different types of WebSocket events.
          switch (e) {
            case TextDataReceived(text: final text):
              // If a text message is received and it's not "Ok", treat it as an error signal.
              // This assumes "Ok" is a specific status message, and other text indicates an issue.
              if (text != "Ok") {
                return Uint8List.fromList([-1]); // Signal an error.
              }
              break; // If text is "Ok", no data is yielded.
            case BinaryDataReceived(data: final data):
              // If binary data is received, return it directly as this is the primary data channel.
              return data;
            case CloseReceived(code: final code, reason: final reason):
              // If the WebSocket connection is closed, log the reason and signal an error.
              printInfo(info: "WS Closed: $code; $reason");
              return Uint8List.fromList([-1]); // Signal disconnection/error.
          }
          return empty; // For any other event type or unhandled text data, return an empty list.
        })
        .expand(
          (e) => e,
        ); // Flatten the stream of `Uint8List` chunks into a stream of individual bytes.
    // This is useful for byte-by-byte processing, even if data arrives in blocks.
  }

  /// Writes a buffer of data to the WebSocket cloud service.
  ///
  /// Sends the provided [Uint8List] (raw bytes) as binary data over the
  /// WebSocket connection. This is the primary method for sending commands
  /// or data to the remote cloud service.
  /// [buffer]: The data to be sent as a list of 8-bit unsigned integers.
  /// Returns the number of bytes successfully sent, or -1 on error.
  @override
  Future<int> write(Uint8List buffer) async {
    try {
      // Send the entire byte buffer as binary data over the WebSocket.
      ws!.sendBytes(buffer);
      return buffer.length; // Return the number of bytes successfully sent.
    } catch (e, st) {
      // Catch and log any errors that occur during the write operation.
      printError(info: "WS Write error: $e\n$st");
      return -1; // Indicate that the write operation failed.
    }
  }
}
