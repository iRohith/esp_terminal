# Bluetooth Terminal Application Developer Manual

Welcome to the developer manual for the Bluetooth Terminal application! This document is designed to help new developers understand the structure and functionality of the application, providing guidance on where to make changes and how to contribute.

The application is built using Flutter and utilizes the GetX framework for state management, dependency injection, and routing.

## Project Structure

The core of the application resides in the `lib/` directory. Here's a breakdown of the main folders:

*   [`lib/connectors/`](lib/connectors/): Contains the implementations for different connection types (Bluetooth Low Energy, Classic Bluetooth, USB, WebSocket, Mock).
*   [`lib/modals/`](lib/modals/): Defines the data structures used throughout the application, such as data packets, chart configurations, slider data, and variable data.
*   [`lib/services/`](lib/services/): Houses the core application logic and state management using GetX services. This includes handling connections, managing data, logging, settings, and persistent storage.
*   [`lib/ui/`](lib/ui/): Contains the user interface components, organized into pages and reusable widgets (panels, dialogs, side menu).
*   [`lib/utils/`](lib/utils/): Provides utility functions, constants, route definitions, and permission handling.

## Core Concepts

### GetX Framework

This application heavily relies on the GetX framework. Key concepts you'll encounter include:

*   **GetxService:** Services are used for dependency injection and managing application-level state. They are initialized and available globally.
*   **Observables (Rx):** GetX uses `Rx` types (e.g., `Rx<T>`, `RxList<T>`, `RxMap<K, V>`) to make variables observable. Changes to observable variables automatically trigger UI updates where they are used.
*   **Get.put():** Used to register a service or controller with the GetX dependency injection container.
*   **Get.find():** Used to retrieve an instance of a registered service or controller.
*   **Get.toNamed(), Get.offAllNamed():** Used for navigation between pages using named routes defined in [`lib/utils/routes.dart`](lib/utils/routes.dart).
*   **Obx(), ObxValue():** Widgets that automatically rebuild when the observable variables they are listening to change.
*   **ValueBuilder():** A widget similar to `Obx` but specifically designed for managing and updating a single observable value within a widget tree.
*   **Workers (ever, once, debounce, interval):** GetX provides workers to react to changes in observable variables in different ways (e.g., `ever` for every change, `debounce` for changes after a delay).

### Data Handling

The application uses the [`DataPacket`](lib/modals/data_packet.dart) class to represent data exchanged with connected devices. This class includes a command byte, a floating-point value, and an identifier. Utility functions in [`lib/utils/util.dart`](lib/utils/util.dart) handle the conversion of byte streams to `DataPacket` objects.

Application data, such as variables received from devices, chart configurations, and slider settings, are managed by the [`DataService`](lib/services/data_service.dart) and persisted using the [`StorageService`](lib/services/storage_service.dart) which utilizes `shared_preferences`.

### Connections

The [`ConnectionService`](lib/services/connection_service.dart) is responsible for managing device connections. It uses a factory pattern to create instances of different [`BaseConnector`](lib/connectors/base_connector.dart) implementations based on the selected connection type. The `BaseConnector` defines the common interface for initializing, connecting, disconnecting, reading, and writing data.

### User Interface

The UI is structured using pages and panels. The [`PageWrapper`](lib/ui/pages/page_wrapper.dart) widget provides a consistent layout for most pages, including an app bar and a side menu ([`SideMenu`](lib/ui/widgets/side_menu.dart)) for navigation.

Content on each page is organized into panels, which are typically based on the [`BasePanel`](lib/ui/widgets/panels/base_panel.dart) widget. Specific panel implementations like [`VariablesPanel`](lib/ui/widgets/panels/variables_panel.dart), [`KeypadPanel`](lib/ui/widgets/panels/keypad_panel.dart), [`SlidersPanel`](lib/ui/widgets/panels/sliders_panel.dart), and [`ChartPanel`](lib/ui/widgets/panels/chart_panel.dart) handle the display and interaction for different types of data and controls.

Reusable dialogs, such as [`EditDialog`](lib/ui/widgets/edit_dialog.dart) for editing data and [`SelectDeviceDialog`](lib/ui/widgets/select_device_dialog.dart) for selecting devices, are located in the [`lib/ui/widgets/`](lib/ui/widgets/) directory.

## Key Areas for Development

### Adding a New Connection Type

To add support for a new communication protocol (e.g., Serial Port):

1.  Create a new class in [`lib/connectors/`](lib/connectors/) that extends [`BaseConnector`](lib/connectors/base_connector.dart). Implement the `init`, `dispose`, `connect`, `disconnect`, `write`, and `read` methods according to the new protocol.
2.  Register the new connector in the `initConnectors()` function in [`lib/main.dart`](lib/main.dart) by adding an entry to the `connectors` map in `ConnectionService`.
3.  Update the [`ConnectionPage`](lib/ui/pages/connection_page.dart) if necessary to handle any specific UI requirements for the new connection type (though the current implementation should handle it generically).

### Adding New Data Variables or Commands

If your connected device sends new types of data or responds to new commands:

1.  Update the [`DataPacket`](lib/modals/data_packet.dart) class if the new data format requires changes.
2.  Define new constants for command bytes in [`lib/utils/constants.dart`](lib/utils/constants.dart).
3.  Modify the `dataPacketTransformer()` in [`lib/utils/util.dart`](lib/utils/util.dart) to correctly parse the new incoming data into `DataPacket` objects.
4.  Update the [`DataService`](lib/services/data_service.dart) to handle and store the new data variables if they are meant to be displayed or used in the UI.
5.  If the new commands are sent from the application, update the relevant UI components (e.g., [`KeypadPanel`](lib/ui/widgets/panels/keypad_panel.dart), [`SlidersPanel`](lib/ui/widgets/panels/sliders_panel.dart)) to send the appropriate `DataPacket`.

### Customizing UI Panels

To modify existing panels or create new ones:

1.  Existing panel implementations are in [`lib/ui/widgets/panels/`](lib/ui/widgets/panels/). You can modify these files to change the layout, appearance, or behavior of the panels.
2.  To create a new panel, extend [`BasePanel`](lib/ui/widgets/panels/base_panel.dart) and implement the `loadState` (if asynchronous data loading is needed) and `buildPanel` methods.
3.  Add the new panel to the desired page widget in [`lib/ui/pages/`](lib/ui/pages/).

### Adding a New Page

To add a new screen to the application:

1.  Create a new Dart file in [`lib/ui/pages/`](lib/ui/pages/) for your new page widget.
2.  Wrap the content of your new page in a [`PageWrapper`](lib/ui/pages/page_wrapper.dart) to maintain consistency.
3.  Define a new route for your page in [`lib/utils/routes.dart`](lib/utils/routes.dart).
4.  Add a `GetPage` entry for your new route in the `getPages` list in the `MyApp` widget in [`lib/main.dart`](lib/main.dart).
5.  Add a navigation link to your new page in the [`SideMenu`](lib/ui/widgets/side_menu.dart).

### Persistent Storage

The [`StorageService`](lib/services/storage_service.dart) handles saving and loading data using `shared_preferences`. If you need to persist new types of data:

1.  Add methods to `StorageService` to encode and decode your data to/from a format supported by `shared_preferences` (e.g., JSON strings for complex objects).
2.  Call these methods from the relevant services or UI components when data needs to be saved or loaded.

## Hints for Beginners

*   **Understand GetX:** Spend some time understanding the core concepts of GetX, especially observables and dependency injection. This is fundamental to how the application manages state and services.
*   **Follow Existing Patterns:** When adding new features or modifying existing ones, try to follow the established patterns and architecture used in the existing code.
*   **Use the Debugger:** Flutter's debugging tools are powerful. Use breakpoints, inspect variables, and utilize the widget inspector to understand the UI tree.
*   **Read the Code:** The best way to learn is by reading the existing code. Start with [`main.dart`](lib/main.dart) to see how the application is initialized and then explore the different directories based on the functionality you're interested in.
*   **Refer to GetX Documentation:** The official GetX documentation is a valuable resource for understanding the framework's features and usage.
*   **Ask for Help:** Don't hesitate to ask for help if you get stuck.

This manual provides a starting point for understanding the Bluetooth Terminal application. As you explore the codebase and contribute, you'll gain a deeper understanding of its inner workings. Happy coding!