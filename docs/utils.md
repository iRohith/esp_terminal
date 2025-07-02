# Utils: Helper Functions and Constants

The `lib/utils/` directory contains various utility classes, functions, and constants that are used across the application. These components provide common functionalities and definitions that don't fit into the specific domains of connectors, modals, services, or UI.

## [`lib/utils/constants.dart`](lib/utils/constants.dart)

This file defines application-wide constants. Using constants helps in maintaining consistency and makes the code easier to read and modify.

*   **Purpose:** Stores fixed values used throughout the application, such as command bytes for communication, limits for logs, packet size, and a color palette for charts.
*   **Key Constants:**
    *   `ON_SEND`, `OFF_SEND`, `MODE_SEND`, `UP_SEND`, `DOWN_SEND`: Command bytes for sending specific control signals.
    *   `FLOAT_SEND`, `MSG_SEND`, `FILE_SEND`, `PASSWORD_SEND`, `PING`: Command bytes for sending different types of data or requests.
    *   `FLOAT_RECV`, `MSG_RECV`, `PASSWORD_VALID`, `PASSWORD_INVALID`: Command bytes for receiving different types of data or responses.
    *   `MAX_LOG_LINES`: The maximum number of lines to keep in the application logs.
    *   `PACKET_SIZE`: The standard size of a data packet in bytes.
    *   `COLORS_PALETTE`: A predefined list of colors used for charting.

*   **Modifying:** If you need to add new command types, change limits, or modify the color palette, you would update this file.

## [`lib/utils/permission_handler.dart`](lib/utils/permission_handler.dart)

This file contains a utility class for handling application permissions, particularly for Bluetooth and location access on different platforms.

*   **Purpose:** Provides methods to check and request necessary permissions for the application to function correctly, especially on mobile platforms.
*   **Key Methods:**
    *   [`areBtPermissionsGranted()`](lib/utils/permission_handler.dart:38): Checks if the required Bluetooth permissions are granted and requests them if necessary. It handles the differences in permission requirements across Android versions and iOS.
    *   `_permissionStatus`: A private getter to get the current status of Bluetooth and Location permissions.
    *   `isMobilePlatform`: A getter to check if the current platform is Android or iOS.
    *   `requiresLocationPermission`: A getter to check if location permission is required for Bluetooth operations on the current platform/Android version.
    *   `requiresExplicitAndroidBluetoothPermissions`: A getter to check if explicit Bluetooth Connect and Scan permissions are required on the current Android version (SDK 31+).

*   **Internal Working:** The class uses the `permission_handler` and `device_info_plus` packages to interact with the operating system's permission system and get device information. It checks the platform and Android SDK version to determine which specific permissions are needed and requests them accordingly.

*   **Modifying:** If permission requirements change in future operating system versions or if you need to handle permissions for other functionalities, you would modify this class.

## [`lib/utils/routes.dart`](lib/utils/routes.dart)

This file defines the named routes used for navigation within the application using GetX.

*   **Purpose:** Provides a centralized place to define the string identifiers for each navigable page in the application. This improves code readability and maintainability compared to using hardcoded strings for routes.
*   **Key Properties:** Static constant strings for each page route (e.g., `home`, `variables`, `settings`).

*   **Modifying:** When adding a new page to the application, you should define a new static constant for its route in this file.

## [`lib/utils/util.dart`](lib/utils/util.dart)

This file contains a collection of general-purpose utility functions used across the application.

*   **Purpose:** Provides helper functions for common tasks that don't fit into other specific categories.
*   **Key Functions:**
    *   [`showSnackbar(String title, String message, ...)`](lib/utils/util.dart:12) and [`closeSnackbar()`](lib/utils/util.dart:32): Functions for displaying and closing snackbar messages using GetX.
    *   [`formatDuration(double seconds)`](lib/utils/util.dart:41): Formats a duration in seconds into a human-readable string (e.g., "1h 30m 15s").
    *   [`durationAccumulate(...)`](lib/utils/util.dart:61): A `StreamTransformer` used for accumulating data points over time for charting purposes. It takes a stream of double values and outputs a stream of lists of `FlSpot` objects, managing a buffer to keep track of data within a specified duration.
    *   [`dataPacketTransformer()`](lib/utils/util.dart:101): A `StreamTransformer` used in the [`ConnectionService`](lib/services/connection_service.dart) to transform a raw stream of bytes (`Stream<int>`) received from a device into a stream of `DataPacket` objects. It handles the parsing of the byte stream according to the defined packet structure.
    *   [`TryResponse<T>`](lib/utils/util.dart:171): A simple class to wrap the result and a message from operations that might fail.
    *   [`tryFunc<T>(FutureOr<T>? Function() fn, ...)`](lib/utils/util.dart:178): A helper function to safely execute an asynchronous function with a timeout and error handling. It returns a `TryResponse` indicating success or failure.

*   **Internal Working:** These functions provide various helper functionalities, from UI feedback (snackbars) to data processing (stream transformers) and robust function execution (`tryFunc`). The stream transformers are particularly important for handling the continuous flow of data from connected devices.

*   **Modifying:** You would add new general utility functions to this file or modify existing ones as needed. For example, if the data packet structure changes, you would need to update `dataPacketTransformer()`.

Understanding these utility components will help you grasp how common tasks are handled and how data streams are processed within the application.

Next, let's look at [Key Areas for Development](key_areas_for_development.md).