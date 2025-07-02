import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:esp_terminal/modals/chart_data.dart';
import 'package:esp_terminal/services/data_service.dart';
import 'package:esp_terminal/services/storage_service.dart';
import 'package:esp_terminal/ui/panels/base_panel.dart';
import 'package:esp_terminal/ui/widgets/edit_form.dart';
import 'package:esp_terminal/util/constants.dart';
import 'package:esp_terminal/util/util.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';

/// A panel widget for displaying a real-time chart of data variables.
///
/// This panel extends [BasePanel] and visualizes data points received from
/// a connected device based on the provided [ChartData] configuration.
/// It handles data buffering, updates, and user interaction for editing
/// chart properties and variables.
class ChartPanel extends BasePanel<ChartData> {
  /// Observable holding the chart configuration.
  ///
  /// This `Rx<ChartData>` object from GetX makes the chart's properties reactive,
  /// so any changes to `name`, `minY`, `maxY`, `maxDuration`, `updateInterval`,
  /// or `variables` will automatically trigger a rebuild of the chart UI.
  final chartData = ChartData(name: "Chart 1", variables: []).obs;

  /// Buffer to store data points for each variable.
  ///
  /// This `RxMap<int, List<FlSpot>>` stores a list of `FlSpot` (data points for `fl_chart`)
  /// for each variable, keyed by the variable's ID. `save: false` indicates
  /// that this buffer is not persisted to disk, as it represents transient real-time data.
  late final buffer = DataService.to.get(
    "chart_$id",
    () => <int, List<FlSpot>>{}.obs,
    save: false,
  );

  /// Optional callback function to delete the chart.
  ///
  /// This function is typically provided by the parent widget (e.g., [ChartsPage])
  /// to allow the user to remove a chart from the display and storage.
  final Function(ChartData?)? deleteFn;

  /// Reference to the [DataService] for accessing application-wide data,
  /// such as the current data packet and elapsed time.
  final ds = DataService.to;

  /// Constructs a [ChartPanel].
  ///
  /// [id]: The unique identifier for this specific chart panel. This ID is used
  ///       for saving and loading its configuration from storage.
  /// [title]: The optional title displayed at the top of the panel. Defaults to "".
  /// [deleteFn]: An optional callback function to handle chart deletion.
  ChartPanel({super.key, required super.id, super.title = "", this.deleteFn})
    : super(
        constraintHeight:
            false, // Panels are not height-constrained by default.
      );

  @override
  /// Asynchronously loads the chart configuration from [StorageService].
  ///
  /// This method retrieves the [ChartData] associated with this panel's `id`.
  /// It also sets up a debounced save mechanism for `chartData` (to persist changes)
  /// and binds the `buffer` to the incoming data stream from [DataService].
  ///
  /// Returns a `Future` that resolves to the loaded [ChartData] or `null` if an error occurs.
  Future<ChartData?> loadState() async {
    final ss =
        StorageService.to; // Get the singleton instance of StorageService.

    // Set up a debounced save operation for the `chartData` observable.
    // This ensures that changes to the chart's configuration are saved to disk
    // after a short delay, preventing excessive write operations during rapid edits.
    debounce(chartData, (chartData) {
      ss.set("chart_$id", jsonEncode(chartData.toJson()));
    });

    // Bind the `buffer` (which holds the chart's data points) to the `currentPacket` stream
    // from `DataService`. This means that whenever a new data packet arrives,
    // the `map` function will process it and update the chart's data.
    buffer.bindStream(
      DataService.to.currentPacket.stream
          .map((p) {
            // Only process packets that are of type `FLOAT_RECV` (indicating a float value).
            if (p.cmd == FLOAT_RECV) {
              // Find the corresponding chart variable by its ID.
              final id = chartData.value.variables
                  .firstWhereOrNull((v) => v.id == p.id)
                  ?.id;
              // If no matching variable is found, return the current buffer without changes.
              if (id == null) return buffer;

              // If the buffer doesn't contain an entry for this variable ID, create an empty list.
              if (!buffer.containsKey(id)) {
                buffer[id] = [];
              }

              final l =
                  buffer[id]!; // Get the list of data points for this variable.
              double s = ds.seconds; // Get the current elapsed time in seconds.

              final maxDuration = chartData
                  .value
                  .maxDuration; // Max duration visible on X-axis.
              final updateInterval = chartData
                  .value
                  .updateInterval; // Interval for adding new points.

              // If the data point list is empty, pre-populate it with zero values
              // to ensure the chart starts with a continuous line.
              if (l.isEmpty) {
                l.addAll(
                  List<FlSpot>.generate(
                    (maxDuration / 0.01)
                        .toInt(), // Number of points to generate.
                    (i) => FlSpot(
                      s - maxDuration + i * 0.01,
                      0.0,
                    ), // Generate points across the max duration.
                  ),
                );
              }

              bool changed =
                  false; // Flag to indicate if the buffer has changed.

              // Add a new data point if the list is empty or if enough time has passed since the last point.
              if (l.isEmpty || s - l.last.x > updateInterval) {
                l.add(
                  FlSpot(s, p.value),
                ); // Add the new data point (time, value).
                changed = true;
              }

              // Remove old data points that have scrolled off the chart (beyond maxDuration).
              if (l.last.x - l.first.x > maxDuration) {
                final idx = l.indexWhere(
                  (v) => l.last.x - v.x < maxDuration,
                ); // Find the first visible point.
                l.removeRange(
                  0,
                  idx,
                ); // Remove all points before the first visible one.
                changed = true;
              }

              // If the buffer has changed, trigger a refresh to update the UI.
              if (changed) {
                buffer.refresh();
              }
            }

            return buffer; // Return the updated buffer.
          })
          .skipWhile(
            (_) => true,
          ), // Skip initial values until a real packet arrives.
    );

    // Retrieve the chart configuration from storage. If not found, use the default `chartData`.
    final cd = await ss.get("chart_$id", jsonEncode(chartData.toJson()));
    // Decode the JSON string and create a `ChartData` object.
    return ChartData.fromJson(jsonDecode(cd));
  }

  @override
  /// Builds the main content widget of the chart panel.
  ///
  /// This method sets up the chart's data streams, configures the `LineChart`
  /// from `fl_chart`, and provides a `GestureDetector` for editing the chart.
  ///
  /// [context]: The build context.
  /// [state]: The [ChartData] loaded by [loadState].
  /// Returns a [Widget] representing the chart panel's content.
  Widget? buildPanel(BuildContext context, ChartData? state) {
    // If state is provided, update the observable `chartData` and the panel's title.
    if (state != null) {
      chartData.value = state;

      // Use `addPostFrameCallback` to update the title after the current frame is built,
      // preventing potential "setState during build" errors.
      Get.engine.addPostFrameCallback((_) {
        title.value = chartData.value.name;
      });
    }

    // Bind the panel's title to the chart's name, so it updates reactively.
    title.bindStream(chartData.stream.map((c) => c.name));

    // An observable list to hold `LineChartBarData` objects, which define the lines on the chart.
    final lineData = <LineChartBarData>[].obs;

    // Bind `lineData` to a periodic stream that generates chart data.
    // `dynPeriodicStream` creates a stream that emits values at a dynamic interval.
    lineData.bindStream(
      dynPeriodicStream(
        () => Duration(
          milliseconds: max(
            10, // Minimum update period of 10ms.
            (chartData.value.updateInterval * 1000)
                .toInt(), // Convert seconds to milliseconds.
          ), // Set the update period based on `chartData.updateInterval`.
        ),
        () => List.generate(chartData.value.variables.length, (i) {
          // Generate `LineChartBarData` for each chart variable.
          final spots =
              buffer[chartData.value.variables[i].id] ??
              [FlSpot.zero]; // Get data points from the buffer.
          return LineChartBarData(
            spots: spots,
            // The data points for this line.
            color: chartData.value.variables[i].color,
            // Color of the line.
            dotData: const FlDotData(show: false),
            // Hide individual data point dots.
            barWidth: 2,
            // Thickness of the line.
            isCurved:
                false, // Do not curve the line (straight segments between points).
          );
        }),
      ),
    );

    return SizedBox(
      width: double.infinity, // Chart takes full available width.
      height: 250, // Fixed height for the chart area.
      child: GestureDetector(
        // Allows tapping on the chart to open the edit dialog.
        onTap: () => showAddOrEditChartDialog(
          chartData: chartData, // Pass the current chart data for editing.
          deleteFn: deleteFn, // Pass the delete function.
        ),
        child: Obx(() {
          // `Obx` rebuilds the chart when `chartData` changes.
          final limitY =
              chartData.value.minY !=
              chartData.value.maxY; // Check if Y-axis limits are applied.
          return LineChart(
            duration: const Duration(milliseconds: 10),
            // Animation duration for chart updates, making transitions smooth.
            LineChartData(
              // Configuration for the LineChart.
              minY: limitY ? chartData.value.minY : null,
              // Set minimum Y-axis value if limits are applied.
              maxY: limitY ? chartData.value.maxY : null,
              // Set maximum Y-axis value if limits are applied.
              lineTouchData: const LineTouchData(enabled: false),
              // Disable touch interactions on the chart.
              clipData: const FlClipData.all(),
              // Clip the chart to the plot area, preventing drawing outside bounds.
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              // Configure grid lines (horizontal only).
              borderData: FlBorderData(show: false),
              // Hide the chart border.
              titlesData: FlTitlesData(
                // Configure axis titles and labels.
                show: true,
                // Show titles.
                leftTitles: AxisTitles(
                  // Left Y-axis titles.
                  axisNameWidget: const Text("Values"), // Axis name.
                  sideTitles: SideTitles(
                    // Side titles (labels).
                    showTitles: true, // Show labels.
                    getTitlesWidget: // Widget builder for left side titles.
                    (value, meta) => _leftTitleWidgets(
                      value,
                      meta,
                      Get.width * 0.9,
                    ), // Custom widget for labels.
                    reservedSize: 56, // Reserved space for titles.
                  ),
                  drawBelowEverything:
                      true, // Draw titles below everything else.
                ),
                rightTitles: const AxisTitles(
                  // Right Y-axis titles (hidden).
                  sideTitles: SideTitles(
                    showTitles: false,
                  ), // Hide right axis titles.
                ),
                bottomTitles: AxisTitles(
                  // Bottom X-axis titles.
                  axisNameWidget: const Text("Time"), // Axis name.
                  sideTitles: SideTitles(
                    // Side titles (labels).
                    showTitles: true, // Show labels.
                    getTitlesWidget: // Widget builder for bottom side titles.
                    (value, meta) => _bottomTitleWidgets(
                      value,
                      meta,
                      Get.width * 0.9,
                    ), // Custom widget for labels.
                    reservedSize: 36, // Reserved space for titles.
                    interval: 1, // Interval for titles.
                  ),
                  drawBelowEverything:
                      true, // Draw titles below everything else.
                ),
                topTitles: const AxisTitles(
                  // Top X-axis titles (hidden).
                  sideTitles: SideTitles(
                    showTitles: false,
                  ), // Hide top axis titles.
                ),
              ),
              lineBarsData: lineData
                  .toList(), // The list of LineChartBarData to display.
            ),
          );
        }),
      ),
    );
  }

  /// Builds the widget for the bottom (X-axis) titles.
  ///
  /// This method customizes the appearance of the time labels on the X-axis.
  /// It hides non-integer values and scales the font size based on chart width.
  ///
  /// [value]: The numerical value of the title (representing time in seconds).
  /// [meta]: Provides metadata about the title, such as its formatted string.
  /// [chartWidth]: The current width of the chart, used for responsive font sizing.
  /// Returns a [Widget] for the bottom title.
  Widget _bottomTitleWidgets(double value, TitleMeta meta, double chartWidth) {
    if (value % 1 != 0) {
      return Container(); // Hide titles that are not whole numbers (e.g., 0.5, 1.5).
    }
    final style = TextStyle(
      // Style for the title text.
      color: Get
          .theme
          .colorScheme
          .onPrimaryContainer, // Text color from the current theme.
      fontWeight: FontWeight.normal,
      fontSize: min(
        18, // Maximum font size.
        18 *
            chartWidth /
            300, // Scale font size based on chart width for responsiveness.
      ),
    );
    return SideTitleWidget(
      // Widget to position the side title.
      meta: meta,
      space: 16, // Spacing between the title and the axis line.
      child: Text(
        "${formatDuration(value)} ",
        // Format the numerical time value into a human-readable duration string.
        style: style,
      ),
    );
  }

  /// Builds the widget for the left (Y-axis) titles.
  ///
  /// This method customizes the appearance of the value labels on the Y-axis.
  /// It scales the font size based on chart width.
  ///
  /// [value]: The numerical value of the title.
  /// [meta]: Provides metadata about the title, including its formatted string.
  /// [chartWidth]: The current width of the chart, used for responsive font sizing.
  /// Returns a [Widget] for the left title.
  Widget _leftTitleWidgets(double value, TitleMeta meta, double chartWidth) {
    final style = TextStyle(
      // Style for the title text.
      color: Get
          .theme
          .colorScheme
          .onPrimaryContainer, // Text color from the current theme.
      fontWeight: FontWeight.normal,
      fontSize: min(
        18, // Maximum font size.
        18 *
            chartWidth /
            300, // Scale font size based on chart width for responsiveness.
      ),
    );
    return SideTitleWidget(
      // Widget to position the side title.
      meta: meta,
      space: 16, // Spacing between the title and the axis line.
      child: Text(
        meta.formattedValue,
        style: style,
      ), // Use the pre-formatted value text.
    );
  }

  /// Shows a dialog for adding or editing a chart configuration.
  ///
  /// This static method presents an [EditForm] dialog that allows the user to
  /// modify chart properties like name, Y-axis limits, duration settings,
  /// and manage the variables plotted on the chart.
  ///
  /// [chartData]: An optional `Rx<ChartData>` representing the chart to be edited.
  ///              If `null`, a new chart will be added.
  /// [defaultName]: An optional default name for a new chart.
  /// [deleteFn]: An optional callback function to delete the chart.
  /// [addFn]: An optional callback function to add a new chart.
  static void showAddOrEditChartDialog({
    Rx<ChartData>? chartData,
    String? defaultName,
    Function(ChartData?)? deleteFn,
    Function(ChartData?)? addFn,
  }) {
    // Create an observable list of variables for the chart.
    // If `chartData` is provided, initialize with its variables; otherwise, start with an empty list.
    final variables = (chartData?.value.variables ?? []).obs;

    // Show the EditDialog.
    Get.dialog(
      EditForm(
        title: chartData == null ? "Add" : "Edit",
        // Dialog title based on whether adding or editing.
        submitLabel: chartData == null ? "Add" : "Save",
        // Submit button text.
        titleSuffix: chartData == null || deleteFn == null
            ? null // No delete button if adding a new chart or deleteFn is not provided.
            : IconButton(
                onPressed: () {
                  deleteFn.call(chartData.value); // Call the delete function.
                  Get.back(); // Close the dialog.
                },
                icon: const Icon(Icons.delete), // Delete icon.
              ),
        onSubmit: (data) {
          // Callback when the submit button is pressed.
          // Create or update the ChartData object from the dialog data.
          final newChartData = ChartData(
            name: data["Name"],
            // Chart name from input.
            minY: data["Y Axis Limits: "]["Min"],
            // Minimum Y-axis value.
            maxY: data["Y Axis Limits: "]["Max"],
            // Maximum Y-axis value.
            updateInterval: data["Duration: "]["Interval"],
            // Chart update interval.
            maxDuration: data["Duration: "]["Max"],
            // Maximum visible duration on X-axis.
            variables: variables, // Use the observable variables list.
          );

          if (chartData != null) {
            chartData.value = newChartData; // Update the existing chart data.
          } else {
            addFn?.call(newChartData); // Call the add function for a new chart.
          }
        },
        items: [
          // List of widgets to display in the dialog.
          FormItemData(
            // Widget for chart name input.
            FormItemType.text,
            "Name",
            data:
                chartData?.value.name ??
                (defaultName ?? "Unknown"), // Initial name.
          ),
          FormItemData(
            // Widget for Y-axis limits (a row of two number inputs).
            FormItemType.row,
            "Y Axis Limits: ",
            data: [
              FormItemData(
                // Widget for minimum Y-axis value.
                FormItemType.number,
                "Min",
                data: chartData?.value.minY ?? 0.0, // Initial minimum value.
              ),
              FormItemData(
                // Widget for maximum Y-axis value.
                FormItemType.number,
                "Max",
                data: chartData?.value.maxY ?? 0.0, // Initial maximum value.
              ),
            ],
          ),
          FormItemData(
            // Widget for duration settings (a row of two number inputs).
            FormItemType.row,
            "Duration: ",
            data: [
              FormItemData(
                // Widget for update interval.
                FormItemType.number,
                "Interval",
                data:
                    chartData?.value.updateInterval ??
                    0.001, // Initial interval.
              ),
              FormItemData(
                // Widget for maximum duration.
                FormItemType.number,
                "Max",
                data:
                    chartData?.value.maxDuration ??
                    10.0, // Initial maximum duration.
              ),
            ],
          ),
          FormItemData(
            // Custom widget for managing chart variables.
            FormItemType.custom,
            "Variables",
            validate: // Validation to ensure at least one variable is present.
            (_) =>
                variables.isEmpty ? "Minimum 1 variable required\n" : "",
            extra: Column(
              // Column to arrange the variable list and add button.
              children: [
                Obx(
                  () => SizedBox(
                    // Set the size of the variable list area.
                    width: 250,
                    height: min(
                      200, // Maximum height for the list.
                      variables.length *
                          60, // Dynamic height based on number of variables.
                    ),
                    child: Card(
                      // Card for the variable list.
                      elevation: 4,
                      child: ReorderableListView.builder(
                        // Reorderable list for variables.
                        itemCount: variables.length, // Number of variables.
                        itemBuilder: (context, index) {
                          // Builder for each variable item.
                          final item = variables[index];
                          return GestureDetector(
                            // GestureDetector to handle tap for editing a variable.
                            key: ValueKey(
                              item.id,
                            ), // Unique key for reordering.
                            onTap: () => _showAddOrEditVariableDialog(
                              // Show dialog to edit variable on tap.
                              variables,
                              index: index,
                            ),
                            child: ListTile(
                              // Display variable as a ListTile.
                              title: Text(item.name), // Variable name.
                              leading: Icon(
                                Icons.circle,
                                color: item.color,
                              ), // Circle icon with variable's color.
                            ),
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          // Callback for reordering variables.
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final varItem = variables.removeAt(
                            oldIndex,
                          ); // Remove the item from the old position.
                          variables.insert(
                            newIndex,
                            varItem,
                          ); // Insert the item at the new position.
                        },
                      ),
                    ),
                  ),
                ),

                Center(
                  // Center the add variable button.
                  child: ElevatedButton(
                    // Button to add a new variable.
                    onPressed: () => _showAddOrEditVariableDialog(
                      // Show dialog to add a new variable.
                      variables,
                    ),
                    style: ElevatedButton.styleFrom(
                      // Button styling.
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(
                        Get.context!,
                      ).colorScheme.primaryContainer,
                      elevation: 8,
                    ),
                    child: const Text("Add Variable"), // Button text.
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog for adding or editing a chart variable.
  ///
  /// This static method presents an [EditForm] dialog that allows the user to
  /// modify a variable's ID, name, and color. It also handles adding new variables
  /// and deleting existing ones.
  ///
  /// [vars]: The observable list of [ChartVariable]s that this dialog will modify.
  /// [index]: The optional index of the variable to edit within the `vars` list.
  ///          If `-1` (default), a new variable will be added.
  static void _showAddOrEditVariableDialog(
    RxList<ChartVariable> vars, {
    int index = -1,
  }) {
    // Get the variable to edit or create a new one.
    var variable = (index == -1
        ? ChartVariable(
            // Create a new variable with a default ID (0), a generated name,
            // and a random color from `COLORS_PALETTE`.
            0,
            "Var ${vars.length}",
            COLORS_PALETTE[Random().nextInt(COLORS_PALETTE.length)],
          )
        : vars[index]); // Get the existing variable if editing.

    // Create an observable for the variable's color, allowing the color picker
    // to update reactively.
    final color = variable.color.obs;

    // Show the EditDialog.
    Get.dialog(
      EditForm(
        title: index == -1 ? "Add" : "Edit",
        // Dialog title based on whether adding or editing.
        submitLabel: index == -1 ? "Add" : "Save",
        // Submit button text.
        titleSuffix:
            index !=
                -1 // Show delete button only if editing an existing variable.
            ? IconButton(
                onPressed: () {
                  vars.removeAt(index); // Remove the variable from the list.
                  Get.back(); // Close the dialog.
                },
                icon: const Icon(Icons.delete), // Delete icon.
              )
            : null,
        onSubmit: (data) {
          // Callback when the submit button is pressed.
          // Create or update the ChartVariable object from the dialog data.
          variable = ChartVariable(data["ID"], data["Name"], color.value);
          if (index == -1) {
            vars.add(variable); // Add the new variable to the list.
          } else {
            vars[index] = variable; // Update the variable in the list.
          }
        },
        items: [
          // List of widgets to display in the dialog.
          FormItemData(
            // Widget for variable ID input.
            FormItemType.id,
            "ID",
            data: variable.id, // Initial ID.
            validate: (v) {
              // Validation logic for the variable ID.
              String msg = "";

              if (v == null || v is! int || v == -1) {
                msg +=
                    "Invalid ID value: '$v'.\n"; // Check for valid integer ID.
              }

              // Check for duplicate IDs, but only if not editing the current item.
              if (index != -1 &&
                  vars.where((element) => element.id == v).length > 1) {
                msg += "ID already exists.";
              } else if (index == -1 &&
                  vars.any((element) => element.id == v)) {
                msg += "ID already exists.";
              }

              return msg; // Return validation message (empty if valid).
            },
          ),
          FormItemData(
            // Widget for variable name input.
            FormItemType.text,
            "Name",
            data: variable.name, // Initial name.
          ),
          FormItemData(
            // Custom widget for color selection.
            FormItemType.custom,
            "Color",
            extra: Row(
              // Row to arrange the color label and color picker button.
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text("Color: "), // Color label.
                Obx(
                  // Use Obx to react to color changes.
                  () => IconButton(
                    // Button to show the color picker.
                    onPressed: () => _showColorPicker(color),
                    // Show color picker on press.
                    icon: Icon(
                      Icons.circle,
                      color: color.value,
                    ), // Circle icon with the selected color.
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog for picking a color.
  ///
  /// This static method presents an `AlertDialog` containing a `ColorPicker`
  /// widget, allowing the user to select a color. The selected color is
  /// updated in the provided `Rx<Color>` observable.
  ///
  /// [color]: The observable color to be updated by the color picker.
  static void _showColorPicker(Rx<Color> color) {
    final Color prevColor = color
        .value; // Store the previous color to allow canceling and reverting.

    // Show the AlertDialog with the ColorPicker.
    Get.dialog(
      AlertDialog(
        title: const Text("Pick a color"), // Dialog title.
        content: Obx(
          // Use Obx to react to color changes within the picker, ensuring the UI updates.
          () => ColorPicker(
            // The color picker widget.
            pickerColor: color.value, // The currently selected color.
            onColorChanged: (c) => color.value =
                c, // Update the observable color when the picker value changes.
          ),
        ),
        actions: [
          // Action buttons for the dialog.
          TextButton(
            // Cancel button.
            onPressed: () {
              color.value =
                  prevColor; // Revert to the previous color on cancel.
              Get.back(); // Close the dialog.
            },
            child: const Text("Cancel"), // Button text.
          ),
          ElevatedButton(
            // OK button to confirm selection.
            onPressed: () =>
                Get.back(), // Close the dialog, keeping the selected color.
            child: const Text("Ok"), // Button text.
          ),
        ],
      ),
    );
  }
}
