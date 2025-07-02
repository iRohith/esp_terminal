import 'package:esp_terminal/ui/panels/base_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// A panel widget for displaying application logs.
///
/// This panel extends [BasePanel] and provides a scrollable text area
/// to display log messages, along with "Copy" and "Clear" buttons.
class LogPanel extends BasePanel<Null> {
  /// The observable list of log messages to display.
  ///
  /// This list is typically managed by a [LogService] and its changes
  /// automatically update the UI.
  final RxList<String> log;

  /// Constructs a [LogPanel].
  ///
  /// [id]: The unique identifier for this specific log panel.
  /// [log]: The observable list of log messages to display.
  /// [title]: The optional title displayed at the top of the panel. Defaults to "Log".
  /// [constraintHeight]: Whether the panel's height should be constrained. Defaults to `false`.
  LogPanel({
    super.key,
    required this.log,
    super.title = "Log",
    super.constraintHeight = false,
    required super.id,
  });

  @override
  /// Builds the main content widget of the log panel.
  ///
  /// This method sets up a [TextField] to display the log messages
  /// and provides "Copy" and "Clear" buttons for user interaction.
  ///
  /// [context]: The build context.
  /// [state]: This panel does not load any specific state, so it's `null`.
  /// Returns a [Widget] representing the log panel's content.
  Widget buildPanel(BuildContext context, Null state) {
    // Controller for the TextField, initialized with current log messages joined by newlines.
    final TextEditingController txtController = TextEditingController(
      text: log.join("\n"),
    );

    // Set up an interval to update the TextField's content whenever the `log` list changes.
    // This ensures the displayed log is always up-to-date with a slight debounce.
    interval(
      log,
      (v) => txtController.text = v.join("\n"),
      time: const Duration(milliseconds: 100),
    );

    return Column(
      // Arrange log display and buttons vertically.
      children: [
        Container(
          // Container for the log display area.
          width: double.infinity, // Take full available width.
          height: 250, // Fixed height for the log display.
          padding: const EdgeInsets.all(8), // Padding around the text field.
          child: TextField(
            // Text field to display log messages.
            controller: txtController,
            // Link the controller.
            readOnly: true,
            // Make the text field read-only.
            decoration: const InputDecoration(border: OutlineInputBorder()),
            // Add an outline border.
            maxLines: null,
            // Allow unlimited lines.
            expands: true,
            // Allow the text field to expand vertically.
            textAlignVertical: TextAlignVertical.top, // Align text to the top.
          ),
        ),

        Row(
          // Row for "Copy" and "Clear" buttons.
          mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the end.
          spacing: 8, // Horizontal spacing between buttons.
          children: [
            ElevatedButton(
              // "Copy" button.
              onPressed: () {
                // Copy the current log text to the clipboard.
                Clipboard.setData(ClipboardData(text: txtController.text));
                // Show a snackbar notification.
                Get.snackbar("Copied", "Log copied to clipboard");
              },
              style: ElevatedButton.styleFrom(
                // Button styling.
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners.
                ),
                backgroundColor: Get
                    .theme
                    .colorScheme
                    .primaryContainer, // Background color from theme.
                foregroundColor: Get
                    .theme
                    .colorScheme
                    .onPrimaryContainer, // Text/icon color from theme.
                elevation: 8, // Shadow depth.
              ),
              child: const Text("Copy"), // Button text.
            ),

            ElevatedButton(
              // "Clear" button.
              onPressed: () => log.clear(), // Clear all log messages.
              style: ElevatedButton.styleFrom(
                // Button styling.
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners.
                ),
                backgroundColor: Get
                    .theme
                    .colorScheme
                    .primaryContainer, // Background color from theme.
                foregroundColor: Get
                    .theme
                    .colorScheme
                    .onPrimaryContainer, // Text/icon color from theme.
                elevation: 8, // Shadow depth.
              ),
              child: const Text("Clear"), // Button text.
            ),
          ],
        ),
      ],
    );
  }
}
