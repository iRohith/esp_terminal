import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:searchable_listview/searchable_listview.dart';

/// A dialog widget for selecting a device from a searchable list.
///
/// This dialog is typically used to present a list of available devices
/// (e.g., Bluetooth, USB) to the user and allow them to select one to connect to.
/// It includes a search bar for filtering the device list and displays a
/// connection indicator when a device is being connected.
class SelectDeviceDialog extends StatelessWidget {
  /// The title displayed at the top of the dialog. Defaults to "Select Device".
  final String name;

  /// An observable list of devices to display.
  ///
  /// Each device is represented as a tuple `(String, String)`, where the first
  /// string is typically the device name and the second string is the device address or identifier.
  /// The use of `RxList` from GetX makes the list reactive, so changes to the
  /// list (e.g., new devices being discovered) will automatically update the UI.
  final RxList<(String, String)> devices;

  /// A callback function executed when a device is tapped for connection.
  ///
  /// The function receives the name and address/identifier of the selected device.
  final Function(String, String) connectCallback;

  /// Constructs a [SelectDeviceDialog].
  ///
  /// [devices] and [connectCallback] are required. [name] is optional.
  const SelectDeviceDialog({
    super.key,
    this.name = "Select Device",
    required this.devices,
    required this.connectCallback,
  });

  @override
  /// Builds the main [AlertDialog] widget for the device selection dialog.
  ///
  /// Sets up the title, content (containing the searchable device list),
  /// and action buttons (Cancel). It uses an `Obx` widget to reactively
  /// update the list when the `devices` observable changes.
  ///
  /// [context]: The build context.
  /// Returns an [AlertDialog] widget.
  Widget build(BuildContext context) {
    // An observable string to track which device is currently attempting to connect.
    // This is used to display a CircularProgressIndicator next to the connecting device.
    final connecting = "".obs;

    return AlertDialog(
      title: Text(name), // Display the dialog title.
      content: Container(
        // Container to constrain the size of the searchable list.
        width: 250, // Fixed width for the content area.
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.5,
        ), // Maximum height relative to screen height.
        child: Obx(() {
          // `Obx` rebuilds the SearchableList when the `devices` observable changes.
          return SearchableList<(String, String)>.sliver(
            // Use SearchableList.sliver for better performance with potentially long lists.
            // ignore: invalid_use_of_protected_member
            initialList: devices.value,
            // The list of devices to display, from the observable.
            keyboardAction: TextInputAction.none,
            // Prevent the keyboard from showing a "done" button.
            itemBuilder: (item) => ListTile(
              // Builder for each device item in the list.
              title: Text(item.$1), // Display the device name as the title.
              subtitle: Text(
                item.$2,
              ), // Display the device address/identifier as the subtitle.
              trailing: Obx(
                // `Obx` rebuilds the trailing widget when the `connecting` observable changes.
                () => connecting.value == item.$1 + item.$2
                    // If this device is currently connecting, show a progress indicator.
                    ? const CircularProgressIndicator()
                    // Otherwise, show an empty SizedBox.
                    : const SizedBox(),
              ),
              onTap: () {
                // On tapping a device item:
                // Check if no device is currently connecting.
                if (connecting.value.isEmpty) {
                  // Set the `connecting` observable to the current device's identifier
                  // to show the progress indicator.
                  connecting.value = item.$1 + item.$2;
                  // Call the provided connect callback with the device details.
                  connectCallback(item.$1, item.$2);
                }
              },
            ),
            filter: (value) => devices
                // Filter the devices list based on the search input value.
                .where(
                  (e) =>
                      // Check if the device name or address contains the search value (case-insensitive).
                      e.$1.toLowerCase().contains(value.toLowerCase()) ||
                      e.$2.toLowerCase().contains(value.toLowerCase()),
                )
                .toList(),
            // Convert the filtered iterable back to a list.
            inputDecoration: InputDecoration(
              // Decoration for the search input field.
              labelText: "Search", // Label text for the search field.
              border:
                  const OutlineInputBorder(), // Border style for the search field.
            ),
          )..sliverScrollEffect = false; // Disable the default sliver scroll effect.
        }),
      ),
      actions: [
        // Action buttons for the dialog.
        TextButton(
          // Cancel button.
          onPressed: () async {
            // Close the dialog and return `false` to indicate cancellation.
            Get.back(result: false);
          },
          child: const Text("Cancel"), // Button text.
        ),
      ],
    );
  }
}
