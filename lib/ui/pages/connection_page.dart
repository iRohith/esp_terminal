import 'package:esp_terminal/services/connection_service.dart';
import 'package:esp_terminal/ui/pages/page_wrapper.dart';
import 'package:esp_terminal/ui/panels/base_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A page for managing and selecting the connection type.
///
/// Displays available connection types and allows selection via radio buttons,
/// managed by the [ConnectionService].
class ConnectionPage extends StatelessWidget {
  /// Constructs a [ConnectionPage].
  const ConnectionPage({super.key});

  @override
  /// Builds the widget tree for the connection page.
  ///
  /// Displays available connectors as radio buttons within a [BasePanel].
  Widget build(BuildContext context) {
    // Access the observable connection type from the ConnectionService.
    final ctype = ConnectionService.to.connectionType;

    // Wrap the page content in a PageWrapper for consistent structure.
    return PageWrapper(
      title: "Connections", // Set the page title.
      useScroll: false, // Disable scrolling for this page.
      panels: [
        // Create a BasePanel to house the connection type selection UI.
        BasePanel(
          id: "connection",
          // Unique identifier for this panel.
          title: "Connection",
          // Title displayed at the top of the panel.
          width: Get.width * 0.8,
          // Set the panel's width to 80% of the screen width.
          constraintHeight: false,
          // Allow the panel's height to adjust dynamically.
          child: Obx(() {
            // Get the list of available connector names from the ConnectionService.
            final ctypes = ConnectionService.to.connectors.keys.toList();
            // Build a column of ListTiles, each representing a connection type with a radio button.
            return Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center content vertically.
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center content horizontally.
              mainAxisSize:
                  MainAxisSize.min, // Shrink column to fit its children.
              children: [
                ListTile(
                  title: const Text(
                    "None",
                  ), // Display "None" as a connection option.
                  leading: Radio<String>(
                    value: "None", // Value for the "None" radio button.
                    groupValue:
                        ctype.value ??
                        "None", // Current selected value in the group.
                    onChanged: (v) => ctype.value =
                        null, // Set connection type to null when "None" is selected.
                  ),
                ),
                // Dynamically generate ListTiles for each available connector type.
                ...List.generate(
                  ctypes.length,
                  (i) => ctypes[i] != "None"
                      ? ListTile(
                          title: Text(
                            ctypes[i],
                          ), // Display the name of the connector type.
                          leading: Radio<String>(
                            value: ctypes[i],
                            // The value of this specific radio button.
                            groupValue: ctype.value,
                            // The currently selected value in the group.
                            onChanged: (v) => ctype.value =
                                v, // Update the observable connection type when selected.
                          ),
                        )
                      : const SizedBox(),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
