# Modals: Data Structures

The `lib/modals/` directory contains the definitions for the data structures used throughout the Bluetooth Terminal application. These classes represent the format of data being exchanged and managed within the app.

## [`lib/modals/data_packet.dart`](lib/modals/data_packet.dart)

This file defines the [`DataPacket`](lib/modals/data_packet.dart) class, which is a fundamental data structure for communication with connected devices. It encapsulates a single packet of data.

*   **Properties:**
    *   [`cmd`](lib/modals/data_packet.dart:12): An integer representing the command byte of the packet. This byte indicates the type of data or command being sent or received (e.g., send a float, receive a message). Constants for common command bytes are defined in [`lib/utils/constants.dart`](lib/utils/constants.dart).
    *   [`value`](lib/modals/data_packet.dart:13): A double representing a floating-point value associated with the command. This is used for sending or receiving numerical data.
    *   [`id`](lib/modals/data_packet.dart:14): An integer identifier for the data packet. This can be used to distinguish between different variables or commands.

*   **Key Methods:**
    *   [`DataPacket(...)`](lib/modals/data_packet.dart:20): The constructor to create a new `DataPacket` instance.
    *   [`copyWith(...)`](lib/modals/data_packet.dart:27): Creates a copy of the `DataPacket` with optional changes to its properties.
    *   [`fromBuffer(Uint8List buffer, ...)`](lib/modals/data_packet.dart:40): A factory constructor to create a `DataPacket` from a byte buffer received from a device. It handles parsing the command, value, and ID from the byte array.
    *   [`toBuffer(Uint8List? buffer, ...)`](lib/modals/data_packet.dart:60): Converts the `DataPacket` instance into a byte buffer (`Uint8List`) that can be sent to a device. It handles formatting the data according to the defined packet structure.
    *   [`toJson()`](lib/modals/data_packet.dart:89) and [`fromJson(Map<String, dynamic> json)`](lib/modals/data_packet.dart:94): Methods for converting the `DataPacket` to and from a JSON map, used for saving and loading data with the [`StorageService`](lib/services/storage_service.dart).

## [`lib/modals/chart_data.dart`](lib/modals/chart_data.dart)

This file defines two classes related to charting: [`ChartVariable`](lib/modals/chart_data.dart:7) and [`ChartData`](lib/modals/chart_data.dart:39). These classes are used to configure and manage the data displayed on the charts page.

*   **[`ChartVariable`](lib/modals/chart_data.dart:7):** Represents a single variable that can be plotted on a chart.
    *   **Properties:** `id` (unique identifier, typically matching a `DataPacket` ID), `name` (display name), and `color` (the color used for the variable's line on the chart).
    *   **Key Methods:** `toJson()` and `fromJson()` for serialization.

*   **[`ChartData`](lib/modals/chart_data.dart:39):** Represents the configuration and a list of variables for a single chart.
    *   **Properties:** `name` (chart title), `minY` and `maxY` (Y-axis limits), `maxDuration` (maximum time duration displayed on the X-axis), `updateInterval` (how frequently the chart updates), and `variables` (a list of `ChartVariable` objects).
    *   **Key Methods:** `copyWith()` for creating modified copies, `toJson()` and `fromJson()` for serialization.

These classes are used by the [`ChartsPage`](lib/ui/pages/charts_page.dart) and [`ChartPanel`](lib/ui/widgets/panels/chart_panel.dart) to configure and display real-time data visually.

## [`lib/modals/slider_data.dart`](lib/modals/slider_data.dart)

This file defines the [`SliderData`](lib/modals/slider_data.dart) class, which represents the configuration for a slider control in the UI.

*   **Properties:**
    *   [`name`](lib/modals/slider_data.dart:7): The display name of the slider.
    *   [`min`](lib/modals/slider_data.dart:8): The minimum value of the slider.
    *   [`max`](lib/modals/slider_data.dart:9): The maximum value of the slider.

*   **Key Methods:** `copyWith()` for creating modified copies, `toJson()` and `fromJson()` for serialization.

`SliderData` objects are used in conjunction with `DataPacket` objects by the [`SlidersPanel`](lib/ui/widgets/panels/sliders_panel.dart) to create interactive slider controls that send numerical values to the connected device.

## [`lib/modals/variable_data.dart`](lib/modals/variable_data.dart)

This file defines the [`VariableData`](lib/modals/variable_data.dart) class, which represents a single data point or variable received from a connected device.

*   **Properties:**
    *   [`id`](lib/modals/variable_data.dart:5): A unique integer identifier for the variable, typically matching the ID in a received `DataPacket`.
    *   [`name`](lib/modals/variable_data.dart:6): The display name of the variable.
    *   [`value`](lib/modals/variable_data.dart:7): The current numerical value of the variable.

*   **Key Methods:** `copyWith()` for creating modified copies. Note that this class does not have `toJson()` and `fromJson()` methods directly, as the serialization of variables is handled within the [`StorageService`](lib/services/storage_service.dart) when saving the list of variables.

`VariableData` objects are managed by the [`DataService`](lib/services/data_service.dart) and displayed by the [`VariablesPanel`](lib/ui/widgets/panels/variables_panel.dart).

Understanding these data structures will help you interpret the data flow within the application and how information is organized for different features.

Next, let's explore the [Services: Application Logic and State Management](services.md).