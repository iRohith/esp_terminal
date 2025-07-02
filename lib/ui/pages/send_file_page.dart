import 'dart:io';

import 'package:esp_terminal/services/connection_service.dart';
import 'package:esp_terminal/services/log_service.dart';
import 'package:esp_terminal/ui/pages/page_wrapper.dart';
import 'package:esp_terminal/ui/panels/base_panel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A page dedicated to sending files to the connected device, potentially with password protection.
///
/// This page provides UI elements for selecting a file, entering a password,
/// and initiating the file transfer process. It leverages [ConnectionService]
/// for the actual data transmission.
class SendFilePage extends StatelessWidget {
  /// Constructs a [SendFilePage].
  const SendFilePage({super.key});

  @override
  /// Builds the widget tree for the send file page.
  ///
  /// It includes a file picker, a password input field, and a send button,
  /// all wrapped within a [PageWrapper] for consistent layout.
  ///
  /// [context]: The build context for the widget.
  /// Returns a [Widget] representing the send file page.
  Widget build(BuildContext context) {
    // An observable string to display the name of the selected file.
    final fileName = "".obs;

    // A controller for the password input text field.
    final TextEditingController pwdController = TextEditingController(text: "");
    // A nullable Uint8List to store the bytes of the selected file.
    Uint8List? bytes;
    // A boolean flag to prevent multiple send operations while one is in progress.
    bool sending = false;

    return PageWrapper(
      title: "Send File", // Page title.
      panels: [
        BasePanel(
          id: "send_file", // Unique ID for the panel.
          title: "Send File", // Panel title.
          constraintHeight: false, // Do not constrain the panel height.
          child: SizedBox(
            height: 600, // Fixed height for the content area.
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center content vertically.
              spacing: 8, // Vertical spacing between children.
              children: [
                ElevatedButton(
                  // Button to trigger file selection.
                  onPressed: () async => bytes = await _pickFile(fileName),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Get.theme.colorScheme.primaryContainer,
                    foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
                    elevation: 8,
                  ),
                  child: const Text("Select file"), // Button text.
                ),

                Obx(
                  () =>
                      // Display the selected file name if available, otherwise an empty box.
                      fileName.value.isNotEmpty
                      ? Text("File: ${fileName.value}")
                      : const SizedBox(),
                ),

                const Divider(), // A visual separator.

                SizedBox(
                  width: 250, // Fixed width for the password input field.
                  child: ValueBuilder<bool?>(
                    initialValue:
                        true, // Initial state: password text is obscured.
                    builder: (obscureText, updateFn) => TextField(
                      controller: pwdController,
                      // Link to the password text controller.
                      decoration: InputDecoration(
                        labelText: "Password",
                        // Label for the input field.
                        border: const OutlineInputBorder(),
                        // Visual border.
                        suffixIcon: IconButton(
                          // Icon button to toggle password visibility.
                          icon: Icon(
                            obscureText! // Use `!` to assert non-nullability after initialValue.
                                ? Icons
                                      .visibility // Show icon if text is obscured.
                                : Icons.visibility_off,
                            // Hide icon if text is visible.
                            color: Colors.grey,
                          ),
                          onPressed: () => updateFn(
                            !obscureText,
                          ), // Toggle obscureText state.
                        ),
                      ),
                      obscureText: obscureText, // Control text obscuring.
                    ),
                  ),
                ),

                ElevatedButton(
                  // Button to send the selected file.
                  onPressed: () async {
                    if (sending) {
                      return; // Prevent multiple send attempts.
                    }
                    sending = true; // Set sending flag to true.
                    // Call the ConnectionService to send the protected file.
                    await ConnectionService.to.sendProtected(
                      pwdController.text, // The password entered by the user.
                      bytes, // The bytes of the selected file.
                    );
                    sending =
                        false; // Reset sending flag after operation completes.
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Get.theme.colorScheme.primaryContainer,
                    foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
                    elevation: 8,
                  ),
                  child: const Text("Send"), // Button text.
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Asynchronously picks a file from the device's file system.
  ///
  /// Uses `file_picker` plugin to open a file selection dialog.
  /// Reads the selected file's bytes and updates the `fileName` observable.
  /// Logs the operation and handles potential errors during file reading.
  ///
  /// [fileName]: An `Rx<String>` observable to update with the selected file's name.
  /// Returns a `Future` that resolves to `Uint8List` containing the file's bytes, or `null` if no file was selected or an error occurred.
  Future<Uint8List?> _pickFile(Rx<String> fileName) async {
    final logService =
        LogService.to; // Get the LogService instance for logging.
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(); // Open file picker dialog.

    if (result != null) {
      try {
        // If a file was selected, read its contents.
        File file = File(
          result.files.single.path!,
        ); // Get the file object from the result.
        final bytes = file
            .readAsBytesSync(); // Read all bytes from the file synchronously.
        fileName.value =
            result.files.single.name; // Update the observable file name.

        logService.logSys(
          "Opened file: ${fileName.value}",
        ); // Log successful file opening.
        return bytes; // Return the file bytes.
      } catch (e) {
        // Catch any errors during file reading.
        if (kDebugMode) {
          print(e); // Print error to console in debug mode.
        }

        logService.logSys(
          "Failed to read file; Error: $e",
        ); // Log the error to system log.
        fileName.value = ""; // Clear the file name on error.
      }
    }
    return null; // Return null if no file was selected or an error occurred.
  }
}
