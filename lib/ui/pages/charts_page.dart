import 'dart:convert';

import 'package:esp_terminal/modals/chart_data.dart';
import 'package:esp_terminal/services/storage_service.dart';
import 'package:esp_terminal/ui/pages/page_wrapper.dart';
import 'package:esp_terminal/ui/panels/chart_panel.dart';
import 'package:esp_terminal/util/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A page that displays multiple charts for visualizing data.
///
/// Loads chart configurations from storage, displays them using [ChartPanel]
/// widgets, and allows adding new charts.
class ChartsPage extends StatelessWidget {
  /// Constructs a [ChartsPage].
  ChartsPage({super.key});

  /// An observable list of chart IDs.
  ///
  /// Each ID represents a unique chart configuration stored in [StorageService].
  /// The `obs` makes this list reactive, triggering UI updates when charts are added or removed.
  final charts = <String>[].obs;

  /// Asynchronously loads chart configurations from [StorageService].
  ///
  /// Retrieves chart IDs, ensures a default chart exists if none are found,
  /// and sets up a debounced save mechanism for changes to the `charts` list.
  ///
  /// Returns a `Future` resolving to a `List<String>` of chart IDs.
  Future<List<String>> loadState() async {
    final ss =
        StorageService.to; // Get the singleton instance of StorageService.

    // Set up a debounced save operation for the `charts` list.
    // This prevents excessive write operations to disk during rapid changes
    // by saving only after a short delay.
    debounce(charts, (charts) {
      ss.set("charts", charts);
    });

    // Retrieve the list of chart IDs from storage. If no list is found,
    // default to a list containing "chart_default" to ensure at least one chart exists.
    final chartList = await ss.get("charts", ["chart_default"]);

    // Check if the default chart configuration ("chart_chart_default") exists in storage.
    // If it does not exist, create a new default chart configuration and save it.
    if (!(await ss.contains("chart_chart_default"))) {
      await ss.set(
        "chart_chart_default",
        jsonEncode(
          ChartData(
            name: "Chart 1", // Assign a default name for the first chart.
            minY: 0, // Set the default minimum Y-axis value.
            maxY: 0, // Set the default maximum Y-axis value.
            variables: [
              // Define default variables to be displayed on the chart.
              ChartVariable(
                0x3, // Example ID for a variable.
                "V motor",
                // Display name for the variable (e.g., Motor Voltage).
                Colors.red, // Color for the variable's line on the chart.
              ),
              ChartVariable(
                0x5, // Another example ID.
                "I motor",
                // Display name for the second variable (e.g., Motor Current).
                Colors.green, // Color for the second variable's line.
              ),
            ],
          ).toJson(), // Convert the ChartData object to JSON format for storage.
        ),
      );
    }

    return chartList; // Return the loaded (or newly created default) list of chart IDs.
  }

  @override
  /// Builds the widget tree for the charts page.
  ///
  /// Uses a [FutureBuilder] to asynchronously load chart data from storage.
  /// The UI is rendered only after the data is available.
  ///
  /// [context]: The build context.
  /// Returns a [Widget] representing the charts page.
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadState(), // Initiate loading of chart data.
      builder: (_, v) => v.data == null
          ? const SizedBox() // Display an empty box or loading indicator while data is loading.
          : SizedBox(
              width: double
                  .infinity, // Ensure the content takes the full available width.
              child: _buildPage(
                v.data!, // Build the page content once data is successfully loaded.
              ),
            ),
    );
  }

  /// Builds the main content of the charts page.
  ///
  /// Initializes the `charts` observable list with the loaded state,
  /// constructs the UI using a [PageWrapper] and a list of [ChartPanel] widgets,
  /// and provides a button to add new charts.
  ///
  /// [state]: The initial list of chart IDs loaded from storage.
  /// Returns a [Widget] representing the charts page content.
  Widget _buildPage(List<String> state) {
    charts.clear(); // Clear any existing chart IDs from the observable list.
    charts.addAll(
      state,
    ); // Populate the observable list with the loaded chart IDs.

    return Obx(() {
      // `Obx` from GetX ensures that this widget rebuilds whenever the `charts` observable list changes.
      return PageWrapper(
        title: "Charts",
        // Set the page title displayed in the app bar.
        extraWidget: ElevatedButton(
          // Define an "Add chart" button.
          onPressed: () => ChartPanel.showAddOrEditChartDialog(
            addFn: (c) {
              // Callback function executed when a new chart is added via the dialog.
              final id =
                  generateRandomId(); // Generate a unique ID for the new chart.
              charts.add(id); // Add the new chart ID to the observable list.
              // Save the new chart's configuration to storage using its unique ID.
              StorageService.to.set("chart_$id", jsonEncode(c!.toJson()));
            },
            defaultName:
                "Chart ${charts.length + 1}", // Suggest a default name for the new chart (e.g., "Chart 2").
          ),
          style: ElevatedButton.styleFrom(
            // Apply styling to the button for a rounded rectangle shape.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // Set background and foreground colors from the current theme.
            backgroundColor: Get.theme.colorScheme.primaryContainer,
            foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
            elevation: 8, // Add a shadow for visual depth.
          ),
          child: const Text("Add chart"), // Set the button text.
        ),
        // Dynamically generate a list of ChartPanel widgets based on the `charts` observable list.
        panels: List.generate(charts.length, (i) {
          return ChartPanel(
            id: charts[i], // Pass the unique chart ID to each ChartPanel.
            deleteFn: (_) {
              // Callback function for deleting a chart.
              // Remove the chart's configuration from storage using its ID.
              StorageService.to.remove("chart_${charts[i]}");
              // Remove the chart ID from the observable list, which triggers a UI update.
              charts.removeAt(i);
            },
          );
        }),
      );
    });
  }
}
