# Project Structure

Understanding the project's directory structure is crucial for navigating the codebase and finding where specific functionalities are located. The core application code resides within the `lib/` directory.

Here's a breakdown of the main directories within `lib/` and their purpose:

*   [`lib/connectors/`](lib/connectors/):
    This directory contains the implementations for different communication protocols the application supports. Each file here represents a specific type of connection (e.g., Bluetooth Low Energy, Classic Bluetooth, USB, WebSocket). These classes handle the low-level details of establishing and managing connections and sending/receiving raw data.

*   [`lib/modals/`](lib/modals/):
    This folder defines the data models or structures used throughout the application. You'll find classes representing the format of data packets exchanged with devices, configurations for UI components like charts and sliders, and data structures for variables. These models ensure data consistency and provide a clear representation of the information being processed.

*   [`lib/services/`](lib/services/):
    This is where the core application logic and state management are implemented using GetX Services. Each service is responsible for a specific domain of the application, such as managing the connection state ([`ConnectionService`](lib/services/connection_service.dart)), handling application data ([`DataService`](lib/services/data_service.dart)), managing logs ([`LogService`](lib/services/log_service.dart)), storing settings ([`SettingsService`](lib/services/settings_service.dart)), and interacting with persistent storage ([`StorageService`](lib/services/storage_service.dart)). Services are designed to be easily accessible and shareable across the application.

*   [`lib/ui/`](lib/ui/):
    This directory contains all the user interface components of the application. It's further organized into:
    *   [`lib/ui/pages/`](lib/ui/pages/): Contains the main screens or pages of the application (e.g., Home, Charts, Settings). Each file here typically represents a full screen the user can navigate to.
    *   [`lib/ui/widgets/`](lib/ui/widgets/): Houses reusable UI components that are used across different pages or panels. This includes dialogs ([`EditDialog`](lib/ui/widgets/edit_dialog.dart), [`SelectDeviceDialog`](lib/ui/widgets/select_device_dialog.dart)), the side navigation menu ([`SideMenu`](lib/ui/widgets/side_menu.dart)), and the base class for panels ([`lib/ui/widgets/panels/base_panel.dart`](lib/ui/widgets/panels/base_panel.dart)).
    *   [`lib/ui/widgets/panels/`](lib/ui/widgets/panels/): Contains specific implementations of panels that are displayed within the pages. These panels are responsible for rendering specific types of content or controls, such as variables, keypads, sliders, and charts.

*   [`lib/utils/`](lib/utils/):
    This folder contains various utility classes and functions that are used across the application but don't belong to a specific feature domain. This includes:
    *   [`lib/utils/constants.dart`](lib/utils/constants.dart): Defines application-wide constants, such as command bytes, limits, and colors.
    *   [`lib/utils/permission_handler.dart`](lib/utils/permission_handler.dart): Handles requesting and checking necessary permissions (e.g., Bluetooth, Location).
    *   [`lib/utils/routes.dart`](lib/utils/routes.dart): Defines the named routes used for navigation with GetX.
    *   [`lib/utils/util.dart`](lib/utils/util.dart): Contains general-purpose helper functions, such as showing snackbars, formatting duration, and data transformation streams.

*   [`lib/main.dart`](lib/main.dart):
    This is the entry point of the application. It initializes the necessary services and connectors and sets up the main application widget (`MyApp`) which configures the theme and routing.

Understanding this structure will help you locate the code responsible for specific features and make changes effectively.

Next, let's explore the [Core Concepts: GetX Framework](core_concepts_getx.md) that powers this application.