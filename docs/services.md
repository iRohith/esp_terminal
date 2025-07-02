# Services: Application Logic and State Management

The `lib/services/` directory contains the core application logic and state management components, implemented as GetX Services. These services are initialized once and are accessible throughout the application, making it easy to share data and functionality.

## [`lib/services/connection_service.dart`](lib/services/connection_service.dart)

The [`ConnectionService`](lib/services/connection_service.dart) is arguably the most central service, responsible for managing the connection to external devices.

*   **Purpose:** Handles selecting a connection type, establishing and maintaining the connection, sending data packets, and receiving incoming data streams.
*   **Key Properties:**
    *   [`connectors`](lib/services/connection_service.dart:31): An observable map (`RxMap`) storing available connector types and factory functions to create their instances.
    *   [`connectionType`](lib/services/connection_service.dart:38): An observable string (`RxString`) indicating the currently selected connection type.
    *   [`connected`](lib/services/connection_service.dart:41): An observable boolean (`RxBool`) indicating whether a device is currently connected.
    *   [`currentPacket`](lib/services/connection_service.dart:44): An observable `DataPacket` (`Rx<DataPacket>`) holding the most recently received data packet.
    *   [`numBytesReceived`](lib/services/connection_service.dart:47): An observable integer (`RxInt`) tracking the total number of bytes received.
*   **Key Methods:**
    *   [`onInit()`](lib/services/connection_service.dart:57): Called when the service is initialized. It sets up a GetX worker (`ever`) to react to changes in `connectionType`, triggering the connection process.
    *   [`onClose()`](lib/services/connection_service.dart:135): Called when the service is closed. It resets the connection state and disposes of workers.
    *   [`start()`](lib/services/connection_service.dart:148): Starts listening for incoming data from the active connector's `read()` stream. It uses a `StreamTransformer` (`dataPacketTransformer` from [`lib/utils/util.dart`](lib/utils/util.dart)) to convert the raw byte stream into `DataPacket` objects.
    *   [`reset()`](lib/services/connection_service.dart:182): Resets the connection service to its initial state, disconnecting any active connection and closing dialogs.
    *   [`disposeConnector()`](lib/services/connection_service.dart:193): Disposes of the current connector instance, canceling its data stream and disconnecting.
    *   [`writeDataPacket(DataPacket dp)`](lib/services/connection_service.dart:221): Sends a `DataPacket` to the connected device by converting it to bytes and writing to the active connector.
    *   [`writeMessage(String msg, {bool log = true})`](lib/services/connection_service.dart:255): Sends a string message to the connected device, encapsulating it in a `DataPacket`.
    *   [`sendProtected(String pwd, Uint8List? bytes)`](lib/services/connection_service.dart:295): Sends data with password protection. It first sends a hashed password for validation and then sends the actual data if the password is valid.

*   **Internal Working:** The `ConnectionService` uses GetX workers to react to changes in the selected connection type and the connected status of the active connector. It dynamically creates and manages the appropriate `BaseConnector` instance. The incoming byte stream from the connector is transformed into `DataPacket` objects using a custom `StreamTransformer`, and the latest packet is made available through the `currentPacket` observable.

*   **Modifying:** To change how connections are handled, you would primarily modify this service. This includes adding support for new connector types (by registering them in `initConnectors`), changing the connection logic, or modifying how data is sent and received.

## [`lib/services/data_service.dart`](lib/services/data_service.dart)

The [`DataService`](lib/services/data_service.dart) is responsible for managing application data, particularly the variables received from connected devices and general application state variables.

*   **Purpose:** Stores and provides access to observable variables, both those received from devices (keyed by integer ID) and general application state variables (keyed by string). It also handles persisting these variables using the `StorageService`.
*   **Key Properties:**
    *   `_variables`: A private map (`Map<int, RxDouble>`) storing observable double values for device variables, keyed by their integer ID.
    *   `_rxvars`: A private map (`Map<String, dynamic>`) storing general application state variables, keyed by string.
*   **Key Methods:**
    *   [`getVar<T>(String key, T defaultValue, {bool save = false})`](lib/services/data_service.dart:41): Retrieves or creates an observable variable with a given string key and default value. It supports saving the variable's value to persistent storage if `save` is true.
    *   [`removeAllVarsWithPrefix<T>(String prefix)`](lib/services/data_service.dart:88): Removes all observable variables whose keys start with a given prefix. This is used, for example, to clear variables associated with a specific slider when the slider is removed.
    *   [`getVariable(int id)`](lib/services/data_service.dart:104): Retrieves or creates an observable double variable for a given device variable ID. This is used to access the current value of a variable received from the connected device.
    *   [`hasVariable(int id)`](lib/services/data_service.dart:119): Checks if a variable with the given ID exists.
    *   [`reset()`](lib/services/data_service.dart:124): Resets the stored device variables.
    *   [`onInit()`](lib/services/data_service.dart:129): Sets up a GetX worker (`ever`) to react to incoming `DataPacket`s from the `ConnectionService`. If a packet has the `FLOAT_RECV` command, it updates the corresponding device variable using `getVariable()`.

*   **Internal Working:** The `DataService` uses maps to store observable variables. When a `FLOAT_RECV` packet is received, the service finds or creates the corresponding `RxDouble` for the variable ID and updates its value. The `getVar` method provides a generic way to manage and optionally persist other application state variables.

*   **Modifying:** To add new types of application state variables or change how device variables are managed, you would modify this service.

## [`lib/services/log_service.dart`](lib/services/log_service.dart)

The [`LogService`](lib/services/log_service.dart) is responsible for managing and storing application logs.

*   **Purpose:** Provides observable lists for different types of logs (sent messages, received messages, and system events) and methods for adding messages to these logs. It also limits the size of each log to prevent excessive memory usage.
*   **Key Properties:**
    *   [`sendLog`](lib/services/log_service.dart:14): An observable list (`RxList<String>`) for messages sent by the application.
    *   [`recvLog`](lib/services/log_service.dart:17): An observable list (`RxList<String>`) for messages received by the application.
    *   [`sysLog`](lib/services/log_service.dart:20): An observable list (`RxList<String>`) for system-level messages and events.
*   **Key Methods:**
    *   [`LogService()`](lib/services/log_service.dart:25): The constructor sets up a GetX worker (`ever`) to print the latest system log message to the console.
    *   [`logSend(String msg)`](lib/services/log_service.dart:34): Adds a message to the `sendLog`.
    *   [`logRecv(String msg)`](lib/services/log_service.dart:47): Adds a message to the `recvLog`.
    *   [`logSys(String msg)`](lib/services/log_service.dart:60): Adds a message to the `sysLog`.

*   **Internal Working:** The `LogService` simply maintains observable lists of strings for each log type. When a message is added, it's appended to the list, and if the list exceeds the maximum size (`MAX_LOG_LINES` from [`lib/utils/constants.dart`](lib/utils/constants.dart)), the oldest message is removed.

*   **Modifying:** To change how logging works (e.g., add more log types, change the log format, or integrate with a remote logging service), you would modify this service.

## [`lib/services/settings_service.dart`](lib/services/settings_service.dart)

The [`SettingsService`](lib/services/settings_service.dart) manages application settings and tracks connection statistics.

*   **Purpose:** Handles user preferences like dark mode, persists settings using `StorageService`, and monitors connection performance metrics (speed, latency, variables per second) by listening to incoming data packets.
*   **Key Properties:**
    *   [`isDarkMode`](lib/services/settings_service.dart:26): An observable boolean (`RxBool`) indicating whether dark mode is enabled. Its initial value is loaded from storage.
    *   [`speed`](lib/services/settings_service.dart:30): An observable double (`RxDouble`) representing the data transfer speed in KB/s.
    *   [`latency`](lib/services/settings_service.dart:33): An observable double (`RxDouble`) representing the connection latency in milliseconds.
    *   [`varsPerSecond`](lib/services/settings_service.dart:36): An observable double (`RxDouble`) representing the rate of variable updates per second.
*   **Key Methods:**
    *   [`SettingsService()`](lib/services/settings_service.dart:44): The constructor initializes settings from storage and sets up listeners for connection type changes, incoming data packets, and dark mode preference changes. It also sets up a periodic timer to send ping packets for latency calculation.
    *   [`reset()`](lib/services/settings_service.dart:145): Resets the settings to their default values (currently only dark mode).

*   **Internal Working:** The `SettingsService` uses GetX workers and a periodic timer to update connection statistics based on incoming `DataPacket`s (specifically `PING` and `FLOAT_RECV` commands). It calculates speed, latency, and variable update rates. It also uses `StorageService` to load and save the `isDarkMode` setting and the last connected `connectionType`.

*   **Modifying:** To add new settings, change how statistics are calculated, or modify how settings are persisted, you would modify this service.

## [`lib/services/storage_service.dart`](lib/services/storage_service.dart)

The [`StorageService`](lib/services/storage_service.dart) is responsible for managing persistent storage using the `shared_preferences` package.

*   **Purpose:** Provides methods for initializing `shared_preferences`, resetting storage, and loading/saving various data structures used in the application, such as variables, keypad configurations, sliders, and chart data.
*   **Key Properties:**
    *   [`prefs`](lib/services/storage_service.dart:23): An instance of `SharedPreferences`.
*   **Key Methods:**
    *   [`init()`](lib/services/storage_service.dart:26): Initializes the service by getting an instance of `SharedPreferences`. This is an asynchronous operation and is awaited in [`lib/main.dart`](lib/main.dart).
    *   [`reset()`](lib/services/storage_service.dart:33): Clears all data from `SharedPreferences`.
    *   [`loadVariables(String key, {int numDefaultVars = 8})`](lib/services/storage_service.dart:43) and [`saveVariables(String key, List<VariableData> variables)`](lib/services/storage_service.dart:88): Load and save lists of `VariableData`.
    *   [`loadKeypad(String key, {int numDefaultKeys = 8})`](lib/services/storage_service.dart:108) and [`saveKeypad(String key, List<(String, DataPacket)> buttons)`](lib/services/storage_service.dart:148): Load and save lists of keypad button configurations (tuples of String and `DataPacket`).
    *   [`loadSliders(String key)`](lib/services/storage_service.dart:172) and [`saveSliders(String key, List<(SliderData, DataPacket)> sliders)`](lib/services/storage_service.dart:214): Load and save lists of slider configurations (tuples of `SliderData` and `DataPacket`).
    *   [`loadCharts(String key)`](lib/services/storage_service.dart:236) and [`saveCharts(String key, List<ChartData> charts)`](lib/services/storage_service.dart:266): Load and save lists of `ChartData`.

*   **Internal Working:** The `StorageService` uses `shared_preferences` to store data as key-value pairs. For complex data structures like lists of variables, charts, or sliders, it serializes them to JSON strings before saving and deserializes them when loading. It also includes logic to provide default data if loading from storage fails.

*   **Modifying:** To persist new types of data or change how existing data is stored, you would modify this service, adding new load and save methods as needed.

Understanding the responsibilities and interactions of these services is crucial for comprehending the application's overall logic and data flow.

Next, let's explore the [User Interface: Pages and Widgets](ui.md).