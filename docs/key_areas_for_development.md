# Key Areas for Development

This section outlines common development tasks you might undertake and points you to the relevant parts of the codebase. Understanding the project structure and core concepts (especially GetX and Services) is essential before attempting these modifications.

## 1. Adding Support for a New Communication Protocol

If you need the application to communicate over a new type of connection (e.g., Serial Port, TCP/IP):

*   **Create a New Connector:**
    *   Go to the [`lib/connectors/`](lib/connectors/) directory.
    *   Create a new Dart file (e.g., `serial_connector.dart`).
    *   Define a class that extends [`BaseConnector`](lib/connectors/base_connector.dart).
    *   Implement all the abstract methods (`init`, `dispose`, `connect`, `disconnect`, `write`, `read`) using a suitable third-party Flutter package for your protocol. You'll need to find and add this package to your `pubspec.yaml` file.
    *   Ensure your `read()` method returns a `Stream<int>` of raw bytes and your `write()` method accepts `Uint8List`. The application's data handling logic will process these bytes into `DataPacket`s.

*   **Register the New Connector:**
    *   Open [`lib/main.dart`](lib/main.dart).
    *   In the `initConnectors()` function, add an entry to the `ConnectionService.to.connectors` map. The key should be a descriptive name for the connector (e.g., "Serial Port"), and the value should be a factory function that returns an instance of your new connector class.

*   **Update UI (Optional):**
    *   The [`ConnectionPage`](lib/ui/pages/connection_page.dart) should automatically list your new connector type because it iterates over the `ConnectionService.to.connectors.keys`.
    *   If your new connector requires specific configuration or device selection UI (beyond a simple list), you might need to modify the `ConnectionPage` or create a custom dialog similar to [`SelectDeviceDialog`](lib/ui/widgets/select_device_dialog.dart).

## 2. Handling New Data Variables or Commands

If your connected device sends new types of data or you need to send new commands:

*   **Define New Constants:**
    *   Open [`lib/utils/constants.dart`](lib/utils/constants.dart).
    *   Define new constant integer values for any new command bytes used by your device.

*   **Update Data Packet Transformation:**
    *   Open [`lib/utils/util.dart`](lib/utils/util.dart).
    *   Modify the `dataPacketTransformer()` function to correctly parse incoming byte streams that include your new command bytes. You'll need to understand the byte format of your device's data packets.

*   **Update Data Service (for incoming variables):**
    *   Open [`lib/services/data_service.dart`](lib/services/data_service.dart).
    *   If the new data represents a variable you want to display or use in the UI, ensure the `onInit()` worker correctly handles the new command byte (if it's a `FLOAT_RECV` type) or add new logic to process other data types. The `getVariable()` method can be used to get or create an observable for a variable ID.

*   **Update UI (for displaying variables or sending commands):**
    *   **Displaying New Variables:** If you want to display the new variables, you might modify the [`VariablesPanel`](lib/ui/widgets/panels/variables_panel.dart) or create a new UI component that uses `DataService.to.getVariable(id)` to access the observable value.
    *   **Sending New Commands:** If you need to send new commands, you would modify or add buttons/controls to relevant UI panels like [`KeypadPanel`](lib/ui/widgets/panels/keypad_panel.dart) or [`SlidersPanel`](lib/ui/widgets/panels/sliders_panel.dart). Use `ConnectionService.to.writeDataPacket()` to send a `DataPacket` with the appropriate command byte and data.

## 3. Customizing UI Panels or Creating New Ones

To change the appearance or functionality of existing panels or add new visual components:

*   **Modifying Existing Panels:**
    *   Go to the [`lib/ui/widgets/panels/`](lib/ui/widgets/panels/) directory.
    *   Open the file for the panel you want to modify (e.g., [`chart_panel.dart`](lib/ui/widgets/panels/chart_panel.dart), [`keypad_panel.dart`](lib/ui/widgets/panels/keypad_panel.dart)).
    *   Modify the `buildPanel()` method to change the layout or content.
    *   Adjust the `loadState()` method if the panel needs to load different or additional data asynchronously.
    *   Update the interaction logic (e.g., button presses, slider changes) to interact with the appropriate services (`ConnectionService`, `DataService`, `StorageService`).

*   **Creating a New Panel:**
    *   Create a new Dart file in [`lib/ui/widgets/panels/`](lib/ui/widgets/panels/).
    *   Define a class that extends [`BasePanel`](lib/ui/widgets/panels/base_panel.dart).
    *   Implement the `loadState()` method if your panel needs to load data asynchronously (e.g., from storage or a service).
    *   Implement the `buildPanel()` method to define the visual layout and content of your panel. Use widgets from `flutter/material.dart` and interact with services as needed.
    *   Add your new panel to the `panels` list of the desired page widget in [`lib/ui/pages/`](lib/ui/pages/).

## 4. Adding a New Page

To add a completely new screen to the application:

*   **Create the Page Widget:**
    *   Go to the [`lib/ui/pages/`](lib/ui/pages/) directory.
    *   Create a new Dart file for your page (e.g., `new_feature_page.dart`).
    *   Define a stateless or stateful widget for your page.
    *   Wrap the content of your page in a [`PageWrapper`](lib/ui/pages/page_wrapper.dart) to get the standard app bar and side menu. Place your page's specific content (e.g., panels, forms) within the `panels` or `extraWidget` properties of the `PageWrapper`.

*   **Define the Route:**
    *   Open [`lib/utils/routes.dart`](lib/utils/routes.dart).
    *   Add a new static constant string for your page's route (e.g., `static const String newFeature = '/newfeature';`).

*   **Register the Route:**
    *   Open [`lib/main.dart`](lib/main.dart).
    *   In the `MyApp` widget, add a new `GetPage` entry to the `getPages` list. Map your new route string to a factory function that returns an instance of your new page widget.

*   **Add Navigation Link:**
    *   Open [`lib/ui/widgets/side_menu.dart`](lib/ui/widgets/side_menu.dart).
    *   Add a new `ListTile` to the `ListView` in the `SideMenu`'s `build()` method.
    *   Set the `title` to the name of your new page.
    *   In the `onTap` callback, use `Get.offAllNamed(Routes.yourNewRoute)` to navigate to your page and clear the navigation stack.

## 5. Persisting New Data

If you need to save new application data (user preferences, configurations, etc.) so it persists between app sessions:

*   **Update Storage Service:**
    *   Open [`lib/services/storage_service.dart`](lib/services/storage_service.dart).
    *   Add new methods to load and save your data using the `prefs` instance (which is a `SharedPreferences` object). You'll need to decide how to serialize/deserialize your data if it's not a basic type supported directly by `SharedPreferences` (like String, int, double, bool, List<String>). JSON encoding/decoding is a common approach for complex objects.

*   **Integrate with Services or UI:**
    *   In the service or UI component that manages the data you want to persist, call the load method from `StorageService` when the component is initialized.
    *   Call the save method from `StorageService` whenever the data changes. You might use a GetX worker (like `debounce`) to avoid saving too frequently.

By following these guidelines and referring to the existing code examples, you should be well-equipped to make modifications and add new features to the Bluetooth Terminal application.

Finally, let's look at some [Hints and Tips for Beginners](hints_and_tips.md).