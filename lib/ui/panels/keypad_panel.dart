import 'dart:convert';

import 'package:esp_terminal/modals/data_packet.dart';
import 'package:esp_terminal/services/connection_service.dart';
import 'package:esp_terminal/services/storage_service.dart';
import 'package:esp_terminal/ui/panels/base_panel.dart';
import 'package:esp_terminal/ui/widgets/edit_form.dart';
import 'package:esp_terminal/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A panel widget for displaying a keypad with customizable buttons.
///
/// This panel extends [BasePanel] and provides a grid of buttons that can be
/// configured to send specific [DataPacket]s when pressed. It supports
/// predefined labelled buttons, a custom message sending feature, and
/// editable custom buttons that can be added, edited, and deleted.
class KeypadPanel extends BasePanel<List<(String, DataPacket)>> {
  /// Flag indicating whether custom keys can be added, edited, or deleted.
  ///
  /// If `true`, an "Add" button appears in the grid, and long-pressing
  /// existing custom keys opens an edit/delete dialog. If `false`, only
  /// the predefined and existing custom keys are displayed and are not editable.
  final bool editable;

  /// List of predefined labelled buttons.
  ///
  /// This is a list of lists, where each inner list represents a row of buttons.
  /// Each button is defined as a tuple `(String, DataPacket)`, where the `String`
  /// is the button's label and the `DataPacket` is the data to send when pressed.
  final List<List<(String, DataPacket)>> labelledButtons;

  /// Whether to enable the message sending feature.
  ///
  /// If `true`, a text field and "Send" button are displayed, allowing the user
  /// to send arbitrary text messages via the connection.
  final bool enableSendMessageButton;

  /// Observable list of custom keypad keys.
  ///
  /// Each element is a tuple `(String, DataPacket)`, representing the button's
  /// label and the data packet to send. This list is observable, meaning changes
  /// to it will automatically update the UI. It is also persisted to storage.
  final keys = <(String, DataPacket)>[].obs;

  /// Constructs a [KeypadPanel].
  ///
  /// [id]: The unique identifier for this specific keypad panel. This ID is used
  ///       for saving and loading its configuration from storage.
  /// [title]: The optional title displayed at the top of the panel. Defaults to "Keypad".
  /// [constraintHeight]: Whether the panel's height should be constrained. Defaults to `true`.
  /// [showTitle]: Whether to display the panel's title. Defaults to `false`.
  /// [editable]: Flag to enable/disable adding, editing, and deleting custom keys. Defaults to `true`.
  /// [enableSendMessageButton]: Whether to show the message sending feature. Defaults to `true`.
  /// [labelledButtons]: A required list of predefined button rows.
  KeypadPanel({
    super.key,
    required super.id,
    super.title = "Keypad",
    super.constraintHeight = true,
    super.showTitle = false,
    this.editable = true,
    this.enableSendMessageButton = true,
    required this.labelledButtons,
  });

  @override
  /// Asynchronously loads the custom keypad keys from [StorageService].
  ///
  /// This method retrieves the list of `(String, DataPacket)` tuples associated
  /// with this panel's `id`. If no saved state is found, it generates a default
  /// list of keys. It also sets up a debounced save mechanism for the `keys`
  /// observable to persist changes to storage.
  ///
  /// Returns a `Future` that resolves to the loaded list of keys or `null` if an error occurs.
  Future<List<(String, DataPacket)>?> loadState() async {
    final ss =
        StorageService.to; // Get the singleton instance of StorageService.
    // Determine the default number of custom keys based on the panel's ID.
    // Panels with "home" in their ID have fewer default keys.
    final int numKeys = id.contains("home") ? 3 : 8;

    // Set up a debounced save operation for the `keys` observable.
    // This ensures that changes to the custom keys are saved to disk after a
    // short delay, preventing excessive write operations during rapid edits.
    debounce(keys, (keys) {
      ss.set(
        "keys_$id",
        // Map the list of (String, DataPacket) tuples to a list of strings
        // for storage. The format is "label.-;-.json_encoded_data_packet".
        keys.map((v) => "${v.$1}.-;-.${jsonEncode(v.$2.toJson())}").toList(),
      );
    });

    // Retrieve the list of key strings from storage. If not found, generate
    // a default list of key strings.
    final keyList = await ss.get(
      "keys_$id",
      List.generate(
        numKeys,
        // Generate default key strings in the format "K X.-;-.{default_data_packet}".
        (i) =>
            "K ${i + 1}.-;-.${jsonEncode(DataPacket(cmd: FLOAT_SEND, id: i, value: 0.0).toJson())}",
      ),
    );

    // Map the loaded list of strings back to a list of (String, DataPacket) tuples.
    // It splits each string at ".-;-."; the first part is the label, and the
    // second part is the JSON-encoded DataPacket, which is then decoded.
    return keyList.map((v) {
      final i = v.indexOf(".-;-."); // Find the separator.
      return (
        v.substring(0, i), // Extract the label.
        DataPacket.fromJson(
          jsonDecode(v.substring(i + 5)),
        ), // Decode the DataPacket JSON.
      );
    }).toList();
  }

  @override
  /// Builds the main content widget of the keypad panel.
  ///
  /// This method sets up the layout for the predefined labelled buttons,
  /// the optional message sending feature, and the grid of custom keypad buttons.
  /// It uses an `Obx` widget to reactively update the custom button grid
  /// when the `keys` list changes.
  ///
  /// [context]: The build context.
  /// [state]: The list of `(String, DataPacket)` tuples loaded by [loadState].
  /// Returns a [Widget] representing the keypad panel's content.
  Widget? buildPanel(BuildContext context, List<(String, DataPacket)>? state) {
    // If state is provided and not empty, update the observable `keys` list.
    if (state != null && state.isNotEmpty) {
      keys.clear(); // Clear existing default keys.
      keys.addAll(state); // Add the loaded keys.
    }

    return Padding(
      // Add padding around the content.
      padding: const EdgeInsets.all(8.0),
      child: Column(
        // Arrange panel elements vertically.
        spacing: 8, // Vertical spacing between elements.
        children: [
          // Build rows of predefined labelled buttons.
          ...labelledButtons.map((b) => _buildLabelledButtons(b)),

          // Build the send message button row if enabled.
          if (enableSendMessageButton) _buildSendMessageButton(),

          // Build the custom ID buttons grid.
          Obx(
            // `Obx` rebuilds the grid when the `keys` observable list changes.
            () => GridView.builder(
              shrinkWrap: true,
              // Take minimum space in the main axis.
              physics: NeverScrollableScrollPhysics(),
              // Disable scrolling within the grid.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Number of columns in the grid.
                childAspectRatio: 1.4, // Aspect ratio of each grid item.
                crossAxisSpacing: 8, // Horizontal spacing between items.
                mainAxisSpacing: 8, // Vertical spacing between items.
              ),
              itemCount: keys.length + (editable ? 1 : 0),
              // Total number of items: custom keys + optional add button.
              itemBuilder: (ctx, index) => ElevatedButton(
                // The button widget for each grid item.
                onPressed: () {
                  // On short press:
                  if (index == keys.length) {
                    // If it's the last item and editable, show the add item dialog.
                    _showAddOrEditItemDialog(index, keys);
                  } else {
                    // Otherwise, send the DataPacket associated with the key.
                    ConnectionService.to.writeDataPacket(keys[index].$2);
                  }
                },
                onLongPress: () => _showAddOrEditItemDialog(index, keys),
                // On long press: Show the edit item dialog for the corresponding key.
                style: ElevatedButton.styleFrom(
                  // Button styling.
                  elevation: 8, // Shadow depth.
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners.
                  ),
                ),
                child:
                    // Display an add icon if it's the last item and editable,
                    // otherwise build the content for a regular key button.
                    editable && index == keys.length
                    ? const Icon(Icons.add)
                    : _buildKeyGridItem(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a row of predefined labelled buttons.
  ///
  /// This method creates a [Row] containing [ElevatedButton]s for each
  /// `(String, DataPacket)` tuple in the provided `buttons` list.
  /// Short pressing sends the associated [DataPacket], and long pressing
  /// opens an edit dialog with name change disabled.
  ///
  /// [buttons] is the list of (String, [DataPacket]) tuples for the buttons in this row.
  /// Returns a [Widget] containing the row of buttons.
  Widget _buildLabelledButtons(List<(String, DataPacket)> buttons) {
    return Row(
      // Arrange buttons horizontally.
      mainAxisAlignment:
          MainAxisAlignment.center, // Center the buttons in the row.
      spacing: 8, // Horizontal spacing between buttons.
      children: List.generate(
        buttons.length, // Number of buttons in this row.
        (i) => ElevatedButton(
          onPressed: () => ConnectionService.to.writeDataPacket(buttons[i].$2),
          // Send the DataPacket on press.
          onLongPress: () =>
              _showAddOrEditItemDialog(i, buttons, disableNameChange: true),
          // Show edit dialog on long press, with name change disabled for predefined buttons.
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
          child: Text(buttons[i].$1), // Button text (the label).
        ),
      ),
    );
  }

  /// Builds the widget for sending a custom message.
  ///
  /// This method creates a [Row] containing a [TextField] for entering the
  /// message and an [ElevatedButton] to send it. The message is sent
  /// using [ConnectionService.writeMessage].
  ///
  /// Returns a [Widget] for the send message feature.
  Widget _buildSendMessageButton() {
    final TextEditingController msgController = TextEditingController(
      text: "",
    ); // Controller for the message text field, initialized as empty.

    return Row(
      // Arrange the text field and button horizontally.
      mainAxisAlignment:
          MainAxisAlignment.center, // Center the elements in the row.
      spacing: 8, // Horizontal spacing between elements.
      children: [
        SizedBox(
          // Set the width of the text field.
          width: 200,
          child: TextField(
            // Text field for entering the message.
            controller: msgController, // Link the controller to the text field.
            decoration: const InputDecoration(
              // Input field decoration.
              labelText: "Message", // Label text displayed above the input.
              border: OutlineInputBorder(), // Border style for the input field.
            ),
          ),
        ),

        // Button to send the message.
        ElevatedButton(
          onPressed: () async {
            // Write the message using the ConnectionService and clear the text field if successful.
            if (await ConnectionService.to.writeMessage(msgController.text)) {
              msgController
                  .clear(); // Clear the text field after successful sending.
            }
          },
          style: ElevatedButton.styleFrom(
            // Button styling.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners.
            ),
            backgroundColor: Theme.of(
              Get.context!,
            ).colorScheme.primaryContainer, // Background color from theme.
            elevation: 8, // Shadow depth.
          ),
          child: const Text("Send"), // Button text.
        ),
      ],
    );
  }

  /// Builds the content widget for a single custom keypad button in the grid.
  ///
  /// This method creates a [Column] displaying the button's name (label)
  /// and the details of the associated [DataPacket] (ID and Value).
  ///
  /// [index]: The index of the key in the `keys` list.
  /// Returns a [Widget] representing the content of the button.
  Widget _buildKeyGridItem(int index) {
    final (name, dp) =
        keys[index]; // Get the name and DataPacket for the key at the given index.

    return Column(
      // Arrange button content vertically.
      mainAxisAlignment: MainAxisAlignment.center, // Center content vertically.
      children: [
        Text(
          // Button name.
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ), // Style for the name.
          textAlign: TextAlign.center, // Center the text horizontally.
          overflow: TextOverflow.fade, // Fade text if it overflows.
          maxLines: 1, // Limit the name to one line.
        ),
        Text(
          // DataPacket details (ID and Value).
          (" ID: 0x${dp.id.toRadixString(16).toUpperCase()}\n" // Display ID in hexadecimal.
              "Val: ${dp.value.toStringAsFixed(3)}"),
          // Display value with 3 decimal places.
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ), // Style for the details.
          textAlign: TextAlign.center, // Center the text horizontally.
          overflow: TextOverflow.fade, // Fade text if it overflows.
          maxLines: 2, // Limit the details to two lines.
        ),
      ],
    );
  }

  /// Shows a dialog for adding or editing a custom keypad button.
  ///
  /// This method presents an [EditForm] dialog that allows the user to
  /// modify a button's name, ID, and value. It handles both adding new
  /// buttons (when `index` is -1 or equal to the list length) and editing
  /// existing ones. It also provides a delete option for editable keys.
  ///
  /// [index]: The index of the key to edit in the `keys` list. If equal to
  ///          `keys.length`, a new key will be added.
  /// [keys]: The list of `(String, DataPacket)` tuples to modify.
  /// [disableNameChange]: If `true`, the name field in the dialog is disabled.
  ///                      Used for predefined labelled buttons.
  void _showAddOrEditItemDialog(
    int index,
    List<(String, DataPacket)> keys, {
    bool disableNameChange = false,
  }) {
    // Get the existing name and DataPacket if editing, otherwise initialize as null.
    final (name, dp) = index < keys.length ? keys[index] : (null, null);

    Get.dialog(
      // Show the EditDialog.
      EditForm(
        title: dp == null ? "Add" : "Edit",
        // Dialog title based on whether adding or editing.
        submitLabel: dp == null ? "Add" : "Save",
        // Submit button text.
        titleSuffix:
            // Show delete button only if editing an existing key and the panel is editable.
            dp == null || !editable
            ? null
            : IconButton(
                onPressed: () {
                  keys.removeAt(index); // Remove the key from the list.
                  Get.back(); // Close the dialog.
                },
                icon: const Icon(Icons.delete), // Delete icon.
              ),
        onSubmit: (data) {
          // Callback when the submit button is pressed.
          final newName =
              data["Name"]; // Get the new name from the dialog data.
          // Create a new DataPacket from the dialog data.
          final newDp = DataPacket(
            cmd: FLOAT_SEND, // Keypad buttons always send FLOAT_SEND commands.
            id: data["ID"]!, // Get the ID from the dialog data.
            value: data["Value"]!, // Get the value from the dialog data.
          );

          if (dp == null) {
            // If adding a new key, add the new tuple to the list.
            keys.add((newName, newDp));
          } else {
            // If editing an existing key, update the tuple at the specified index.
            keys[index] = (newName, newDp);
          }
        },
        items: [
          // List of widgets to display in the dialog.
          FormItemData(
            FormItemType.id, // Form item type for ID input.
            "ID", // Label for the ID input.
            data:
                dp?.id, // Initial data for the ID input (existing ID or null).
          ),
          FormItemData(
            FormItemType.text, // Form item type for text input (Name).
            "Name", // Label for the Name input.
            data:
                name ?? "Unknown", // Initial name (existing name or "Unknown").
            extra: disableNameChange
                ? "disabled"
                : null, // Disable name change if specified.
          ),
          FormItemData(
            FormItemType.number, // Form item type for number input (Value).
            "Value", // Label for the Value input.
            data: dp
                ?.value, // Initial data for the Value input (existing value or null).
          ),
        ],
      ),
    );
  }
}
