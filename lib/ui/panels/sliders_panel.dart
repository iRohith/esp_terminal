import 'dart:convert';

import 'package:esp_terminal/modals/data_packet.dart';
import 'package:esp_terminal/modals/slider_data.dart';
import 'package:esp_terminal/services/connection_service.dart';
import 'package:esp_terminal/services/data_service.dart';
import 'package:esp_terminal/services/storage_service.dart';
import 'package:esp_terminal/ui/panels/base_panel.dart';
import 'package:esp_terminal/ui/widgets/edit_form.dart';
import 'package:esp_terminal/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A panel widget for displaying a list of customizable sliders.
///
/// This panel extends [BasePanel] and provides a list of sliders that can be
/// configured to send specific [DataPacket]s with a floating-point value
/// when their value changes. It supports editable sliders that can be added,
/// edited, and deleted.
class SlidersPanel extends BasePanel<List<(SliderData, DataPacket)>> {
  /// Flag indicating whether custom sliders can be added, edited, or deleted.
  ///
  /// If `true`, an "Add slider" button is displayed, and the edit button
  /// for each slider allows deletion. If `false`, only the existing sliders
  /// are displayed and are not editable.
  final bool editable;

  /// Observable list of custom sliders.
  ///
  /// Each element is a tuple `(SliderData, DataPacket)`, where the `SliderData`
  /// defines the slider's properties (name, min, max) and the `DataPacket`
  /// specifies the data to send when the slider's value changes. This list
  /// is observable, meaning changes to it will automatically update the UI.
  /// It is also persisted to storage.
  final sliders = <(SliderData, DataPacket)>[].obs;

  /// Constructs a [SlidersPanel].
  ///
  /// [id]: The unique identifier for this specific sliders panel. This ID is used
  ///       for saving and loading its configuration from storage.
  /// [title]: The optional title displayed at the top of the panel. Defaults to "Sliders".
  /// [constraintHeight]: Whether the panel's height should be constrained. Defaults to `true`.
  /// [showTitle]: Whether to display the panel's title. Defaults to `false`.
  /// [editable]: Flag to enable/disable adding, editing, and deleting custom sliders. Defaults to `true`.
  SlidersPanel({
    super.key,
    required super.id,
    super.title = "Sliders",
    super.constraintHeight = true,
    super.showTitle = false,
    this.editable = true,
  });

  @override
  /// Asynchronously loads the custom slider configurations from [StorageService].
  ///
  /// This method retrieves the list of `(SliderData, DataPacket)` tuples associated
  /// with this panel's `id`. If no saved state is found, it generates a default
  /// list of sliders. It also sets up a debounced save mechanism for the `sliders`
  /// observable to persist changes to storage.
  ///
  /// Returns a `Future` that resolves to the loaded list of sliders or `null` if an error occurs.
  Future<List<(SliderData, DataPacket)>?> loadState() async {
    final ss =
        StorageService.to; // Get the singleton instance of StorageService.

    // Set up a debounced save operation for the `sliders` observable.
    // This ensures that changes to the slider configurations are saved to disk after a
    // short delay, preventing excessive write operations during rapid edits.
    debounce(sliders, (sliders) {
      ss.set(
        "sliders_$id",
        // Map the list of (SliderData, DataPacket) tuples to a list of strings
        // for storage. The format is "json_encoded_slider_data.-;-.json_encoded_data_packet".
        sliders
            .map(
              (v) =>
                  "${jsonEncode(v.$1.toJson())}.-;-.${jsonEncode(v.$2.toJson())}",
            )
            .toList(),
      );
    });

    // Retrieve the list of slider strings from storage. If not found, generate
    // a default list of slider strings.
    final slidersList = await ss.get(
      "sliders_$id",
      [
            // Default slider configurations.
            (
              SliderData(name: "V motor", max: 220),
              DataPacket(cmd: FLOAT_SEND, id: 0x00),
            ),
            (
              SliderData(name: "I_m limit", max: 25),
              DataPacket(cmd: FLOAT_SEND, id: 0x01),
            ),
          ]
          .map(
            // Map default tuples to the storage string format.
            (v) =>
                "${jsonEncode(v.$1.toJson())}.-;-.${jsonEncode(v.$2.toJson())}",
          )
          .toList(),
    );

    // Map the loaded list of strings back to a list of (SliderData, DataPacket) tuples.
    // It splits each string at ".-;-."; the first part is the JSON-encoded SliderData,
    // and the second part is the JSON-encoded DataPacket. Both are then decoded.
    return slidersList.map((v) {
      final i = v.indexOf(".-;-."); // Find the separator.
      return (
        SliderData.fromJson(
          jsonDecode(v.substring(0, i)),
        ), // Decode the SliderData JSON.
        DataPacket.fromJson(
          jsonDecode(v.substring(i + 5)),
        ), // Decode the DataPacket JSON.
      );
    }).toList();
  }

  @override
  /// Builds the main content widget of the sliders panel.
  ///
  /// This method sets up the layout for the list of custom sliders and the
  /// optional "Add slider" button. It uses an `Obx` widget to reactively
  /// update the list of sliders when the `sliders` list changes.
  ///
  /// [context]: The build context.
  /// [state]: The list of `(SliderData, DataPacket)` tuples loaded by [loadState].
  /// Returns a [Widget] representing the sliders panel's content.
  Widget? buildPanel(
    BuildContext context,
    List<(SliderData, DataPacket)>? state,
  ) {
    // If state is provided and not empty, update the observable `sliders` list.
    if (state != null && state.isNotEmpty) {
      sliders.clear(); // Clear existing default sliders.
      sliders.addAll(state); // Add the loaded sliders.
    }

    return Padding(
      padding: const EdgeInsets.all(8.0), // Add padding around the content.
      child: Obx(
        // `Obx` rebuilds the Column when the `sliders` observable list changes.
        () => Column(
          spacing: 8, // Vertical spacing between slider widgets.
          children: [
            // Generate individual slider widgets for each slider in the list.
            ...List.generate(sliders.length, (i) => _buildSlider(i)),
            if (editable)
              // Button to add a new slider if the panel is editable.
              ElevatedButton(
                onPressed: () => _showAddOrEditItemDialog(
                  sliders.length,
                ), // Show add dialog on press.
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
                child: const Text("Add slider"), // Button text.
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a single slider widget.
  ///
  /// This method creates a [Row] containing the slider's name button, the
  /// [Slider] widget, a [TextField] to display/edit the value, and an
  /// edit button. It uses `DataService.to.get` to manage the state of the
  /// slider value and text field, ensuring they persist across panel rebuilds.
  /// Debounce logic is used to synchronize changes between the text field,
  /// slider, and sending [DataPacket]s.
  ///
  /// [index]: The index of the slider in the `sliders` list.
  /// Returns a [Widget] containing the slider, its label, value display, and edit button.
  Widget _buildSlider(int index) {
    final (sd, dp) =
        sliders[index]; // Get the SliderData and DataPacket for the slider at the given index.
    // Get or create observable variables for the slider's value and text display
    // using DataService to persist their state. The keys are unique per slider
    // based on panel ID and DataPacket ID.
    final slider = DataService.to.get(
      "slider_${id}_${dp.id}_slider",
      () => sd
          .min
          .obs, // Initialize slider value with the minimum value from SliderData.
    );
    final textValue = DataService.to.get(
      "slider_${id}_${dp.id}_textValue",
      () => sd.min
          .toStringAsFixed(3)
          .obs, // Initialize text value with the minimum value formatted to 3 decimal places.
    );

    // Controller for the text field displaying the slider value.
    final TextEditingController controller = TextEditingController(
      text: textValue
          .value, // Initialize the controller's text with the current textValue.
    );

    // Debounce updates from the text field to the slider value.
    // This prevents rapid updates while the user is typing, only updating
    // the slider value after a short pause (1 second) in typing.
    debounce(textValue, (tv) {
      final v = double.tryParse(tv); // Attempt to parse the text as a double.
      if (v != null) {
        // If parsing is successful, update the slider value, clamping it
        // within the defined min and max range.
        slider.value = v.clamp(sd.min, sd.max);
      }
    }, time: 1.seconds); // Debounce time of 1 second.

    // Listen to changes in the text field and update the textValue observable.
    // This keeps the textValue observable in sync with the text field's content.
    controller.addListener(() => textValue.value = controller.text);

    // Debounce updates from the slider value to sending the DataPacket.
    // This prevents sending a DataPacket for every small change in the slider
    // value, only sending after a short pause (0.5 seconds) in sliding.
    debounce(slider, (v) {
      // Only send the DataPacket if the value is within the defined range.
      if (sd.min <= v && v <= sd.max) {
        // Send a copy of the original DataPacket with the updated value.
        ConnectionService.to.writeDataPacket(dp.copyWith(value: v));
      }
    }, time: 0.5.seconds); // Debounce time of 0.5 seconds.

    return Row(
      // Arrange slider components horizontally.
      children: [
        // Button displaying the slider name.
        // On press, it sends the current clamped slider value and updates
        // the slider and text field to reflect the clamped value.
        ElevatedButton(
          onPressed: () {
            final v = slider.value.clamp(
              sd.min,
              sd.max,
            ); // Clamp the current slider value.
            ConnectionService.to.writeDataPacket(
              dp.copyWith(value: v),
            ); // Send the DataPacket.
            slider.value = v; // Update the slider value to the clamped value.
            controller.text = v.toStringAsFixed(
              3,
            ); // Update the text field with the clamped value.
          },
          style: ElevatedButton.styleFrom(
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
          child: Text(
            sd.name, // Display the slider's name.
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ), // Style for the name.
          ),
        ),

        // Expanded widget containing the slider.
        Expanded(
          child: ObxValue(
            // Use ObxValue to react to changes in the slider value observable,
            // rebuilding only the Slider widget when the value changes.
            (sliderValue) => Slider(
              min: sd.min,
              // Minimum value of the slider.
              max: sd.max,
              // Maximum value of the slider.
              value: sliderValue.value,
              // Current value of the slider, from the observable.
              onChanged: (v) {
                // On slider value change:
                // Update the text field with the new value formatted to 3 decimal places.
                controller.text = v.toStringAsFixed(3);
                // Update the observable slider value by parsing the text field's content.
                // This triggers the debounce logic to send the DataPacket.
                sliderValue.value = double.parse(controller.text);
              },
            ),
            slider, // The observable slider value that ObxValue is watching.
          ),
        ),

        // SizedBox containing the text field for displaying/editing the slider value.
        SizedBox(
          width: 70, // Fixed width for the text field.
          child: TextField(
            controller: controller, // Link the controller to the text field.
            keyboardType:
                TextInputType.number, // Configure keyboard for numbers.
            decoration: const InputDecoration(
              border: OutlineInputBorder(), // Border style for the input field.
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Spacing between the text field and the edit button.
        // IconButton to show the edit dialog for this slider.
        IconButton(
          onPressed: () =>
              _showAddOrEditItemDialog(index), // Show edit dialog on press.
          icon: const Icon(Icons.edit), // Edit icon.
        ),
      ],
    );
  }

  /// Shows a dialog for adding or editing a slider configuration.
  ///
  /// This method presents an [EditForm] dialog that allows the user to
  /// modify a slider's name, ID, minimum value, and maximum value. It handles
  /// both adding new sliders (when `index` is equal to the list length) and
  /// editing existing ones. It also provides a delete option for editable sliders.
  ///
  /// [index]: The index of the slider to edit in the `sliders` list. If equal to
  ///          `sliders.length`, a new slider will be added.
  void _showAddOrEditItemDialog(int index) {
    // Get the existing SliderData and DataPacket if editing, otherwise initialize as null.
    final (sd, dp) = index < sliders.length ? sliders[index] : (null, null);

    Get.dialog(
      // Show the EditDialog.
      EditForm(
        title: sd == null ? "Add" : "Edit",
        // Dialog title based on whether adding or editing.
        submitLabel: sd == null ? "Add" : "Save",
        // Submit button text.
        titleSuffix:
            // Show delete button only if editing an existing slider and the panel is editable.
            dp == null || !editable
            ? null
            : IconButton(
                onPressed: () {
                  sliders.removeAt(index); // Remove the slider from the list.
                  Get.back(); // Close the dialog.
                },
                icon: const Icon(Icons.delete), // Delete icon.
              ),
        onSubmit: (data) {
          // Callback when the submit button is pressed.
          // Create or update the SliderData and DataPacket from the dialog data.
          final newSd = SliderData(
            name: data["Name"]!, // Get the new name from the dialog data.
            min:
                data["Min"]!, // Get the new minimum value from the dialog data.
            max:
                data["Max"]!, // Get the new maximum value from the dialog data.
          );
          // Create a new DataPacket with the FLOAT_SEND command and the new ID.
          final newDp = DataPacket(cmd: FLOAT_SEND, id: data["ID"]!);

          if (dp == null) {
            // If adding a new slider, add the new tuple to the list.
            sliders.add((newSd, newDp));
          } else {
            // If editing an existing slider, update the tuple at the specified index.
            sliders[index] = (newSd, newDp);
          }
        },
        items: [
          // List of widgets to display in the dialog.
          FormItemData(
            FormItemType.id, // Form item type for ID input.
            "ID", // Label for the ID input.
            data:
                dp?.id ??
                0, // Initial data for the ID input (existing ID or default 0).
          ),
          FormItemData(
            FormItemType.text, // Form item type for text input (Name).
            "Name", // Label for the Name input.
            data:
                sd?.name ??
                "S ${sliders.length + 1}", // Initial name (existing name or generated name).
          ),
          FormItemData(
            FormItemType.number, // Form item type for number input (Min).
            "Min", // Label for the minimum value input.
            data:
                sd?.min ??
                0.0, // Initial data for the minimum value input (existing min or default 0.0).
          ),
          FormItemData(
            FormItemType.number, // Form item type for number input (Max).
            "Max", // Label for the maximum value input.
            data:
                sd?.max ??
                0.0, // Initial data for the maximum value input (existing max or default 0.0).
          ),
        ],
      ),
    );
  }
}
