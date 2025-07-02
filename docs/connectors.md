# Connectors: Handling Different Connection Types

The `lib/connectors/` directory is responsible for managing the communication with external devices. The application is designed to support various connection types (like Bluetooth, USB, WebSocket) through a common interface. This makes it easier to add support for new protocols in the future.

## [`lib/connectors/base_connector.dart`](lib/connectors/base_connector.dart)

This file defines the abstract base class, [`BaseConnector`](lib/connectors/base_connector.dart). This class acts as a contract for all specific connector implementations. It outlines the essential methods that any connector must provide:

*   [`init()`](lib/connectors/base_connector.dart:15): Initializes the connector. This might involve requesting permissions, setting up internal resources, or initializing third-party libraries. It should return `true` if initialization is successful.
*   [`dispose()`](lib/connectors/base_connector.dart:22): Cleans up any resources used by the connector when it's no longer needed. This is important to prevent memory leaks. It should return `true` if disposal is successful.
*   [`connect()`](lib/connectors/base_connector.dart:29): Establishes a connection to a device. The specific implementation will handle the details of discovering and connecting to devices for that protocol. It should return `true` if the connection is successful.
*   [`disconnect()`](lib/connectors/base_connector.dart:36): Closes the connection to the currently connected device. It should return `true` if the disconnection is successful.
*   [`write(Uint8List buffer)`](lib/connectors/base_connector.dart:42): Sends data to the connected device. It takes a `Uint8List` (a list of bytes) as input and should return the number of bytes successfully written.
*   [`read()`](lib/connectors/base_connector.dart:47): Provides a `Stream<int>` of incoming data from the connected device. The stream emits individual bytes as integers.
*   [`connected`](lib/connectors/base_connector.dart:52): An observable boolean (`RxBool`) that indicates the current connection status of the connector.

Any new connector type you add must extend this `BaseConnector` class and implement all these methods.

## Specific Connector Implementations

The `lib/connectors/` directory contains files for each supported connection type. These files implement the `BaseConnector` interface for their respective protocols.

*   [`lib/connectors/ble_connector.dart`](lib/connectors/ble_connector.dart): Handles communication over Bluetooth Low Energy (BLE).
*   [`lib/connectors/bt_connector.dart`](lib/connectors/bt_connector.dart): Handles communication over Classic Bluetooth. This is typically only available on Android.
*   [`lib/connectors/mock_connector.dart`](lib/connectors/mock_connector.dart): A mock connector used for testing or when no physical connection is available. It simulates sending and receiving data.
*   [`lib/connectors/usb_connector.dart`](lib/connectors/usb_connector.dart): Handles communication over USB.
*   [`lib/connectors/ws_cloud_connector.dart`](lib/connectors/ws_cloud_connector.dart): Handles communication over WebSocket to a cloud relay.
*   [`lib/connectors/ws_local_connector.dart`](lib/connectors/ws_local_connector.dart): Handles communication over WebSocket to a local server.

Each of these files will contain the specific logic and use relevant libraries for their protocol (e.g., a Bluetooth library for BLE/BT Classic, a USB library for USB, a WebSocket library for WS).

## How Connectors are Used

The [`ConnectionService`](lib/services/connection_service.dart) is responsible for selecting and managing the active connector. It holds a map of available connector types and their factory functions. When a user selects a connection type on the [`ConnectionPage`](lib/ui/pages/connection_page.dart), the `ConnectionService` creates an instance of the corresponding connector, initializes it, attempts to connect, and then starts listening to its `read()` stream for incoming data.

## Modifying or Adding Connectors

*   **Modifying an Existing Connector:** If you need to change how a specific connection type works (e.g., modify the data sending logic for BLE), you would modify the corresponding file in `lib/connectors/`.
*   **Adding a New Connector:** To add support for a new protocol:
    1.  Create a new file in `lib/connectors/` (e.g., `serial_connector.dart`).
    2.  Define a class that extends `BaseConnector` and implement all the required methods using a suitable third-party library for the protocol.
    3.  Register your new connector in the `initConnectors()` function in [`lib/main.dart`](lib/main.dart) by adding an entry to the `ConnectionService.to.connectors` map.

Understanding the `BaseConnector` interface and how the `ConnectionService` manages connectors is key to working with this part of the application.

Next, let's explore the [Modals: Data Structures](modals.md) used in the application.