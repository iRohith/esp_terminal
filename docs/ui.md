# User Interface: Pages and Widgets

The user interface of the Bluetooth Terminal application is organized within the `lib/ui/` directory. This directory is further divided into `pages/` for full screens and `widgets/` for reusable UI components, including specialized `panels/`.

## [`lib/ui/pages/`](lib/ui/pages/)

This directory contains the main screens or pages of the application. Each file here typically represents a distinct view that the user can navigate to via the side menu or other navigation actions.

*   [`lib/ui/pages/page_wrapper.dart`](lib/ui/pages/page_wrapper.dart):
    This is a crucial component that provides a consistent structure for most pages. It includes an `AppBar` with the page title and a connection status icon, and a `Drawer` that houses the [`SideMenu`](lib/ui/widgets/side_menu.dart). The main content of each page is placed within the `body` of the `Scaffold` provided by the `PageWrapper`. Most pages in the application are wrapped in a `PageWrapper`.

*   [`lib/ui/pages/home_page.dart`](lib/ui/pages/home_page.dart):
    The initial page displayed when the application starts (after service initialization). It serves as a dashboard, presenting key information and controls through embedded panels: [`VariablesPanel`](lib/ui/widgets/panels/variables_panel.dart) (for displaying variables), [`KeypadPanel`](lib/ui/widgets/panels/keypad_panel.dart) (with predefined buttons), and [`SlidersPanel`](lib/ui/widgets/panels/sliders_panel.dart).

*   [`lib/ui/pages/charts_page.dart`](lib/ui/pages/charts_page.dart):
    Displays real-time data charts. It loads chart configurations from storage and uses [`ChartPanel`](lib/ui/widgets/panels/chart_panel.dart) widgets to render individual charts. It also provides an option to add new charts.

*   [`lib/ui/pages/connection_page.dart`](lib/ui/pages/connection_page.dart):
    Allows the user to select the desired connection type (e.g., BLE, USB, WebSocket) from the available options provided by the [`ConnectionService`](lib/services/connection_service.dart). It uses radio buttons within a [`BasePanel`](lib/ui/widgets/panels/base_panel.dart) for selection.

*   [`lib/ui/pages/keypad_page.dart`](lib/ui/pages/keypad_page.dart):
    Provides a more extensive keypad interface compared to the home page. It includes a [`KeypadPanel`](lib/ui/widgets/panels/keypad_panel.dart) with customizable buttons and an option to send custom messages, as well as a [`SlidersPanel`](lib/ui/widgets/panels/sliders_panel.dart).

*   [`lib/ui/pages/logs_page.dart`](lib/ui/pages/logs_page.dart):
    Displays the application's logs (system, sent, and received messages) using [`LogPanel`](lib/ui/widgets/panels/log_panel.dart) widgets.

*   [`lib/ui/pages/send_file_page.dart`](lib/ui/pages/send_file_page.dart):
    Allows the user to select a file from their device and send its content to the connected device, with an option for password protection. It interacts with the [`ConnectionService`](lib/services/connection_service.dart) for sending data.

*   [`lib/ui/pages/settings_page.dart`](lib/ui/pages/settings_page.dart):
    Provides controls for configuring application settings, such as dark mode, and entering network credentials (Wi-Fi, WebSocket relay URL). It interacts with the [`SettingsService`](lib/services/settings_service.dart) and [`DataService`](lib/services/data_service.dart) to manage these settings.

*   [`lib/ui/pages/variables_page.dart`](lib/ui/pages/variables_page.dart):
    Displays a detailed list of variables received from the connected device using a [`VariablesPanel`](lib/ui/widgets/panels/variables_panel.dart).

## [`lib/ui/widgets/`](lib/ui/widgets/)

This directory contains reusable UI components that are not full pages but are used within pages or other widgets.

*   [`lib/ui/widgets/side_menu.dart`](lib/ui/widgets/side_menu.dart):
    Implements the side navigation drawer (`Drawer`) that is part of the `PageWrapper`. It provides a list of links to navigate to different pages of the application and displays connection statistics from the [`SettingsService`](lib/services/settings_service.dart).

*   [`lib/ui/widgets/edit_dialog.dart`](lib/ui/widgets/edit_dialog.dart):
    A generic dialog widget used for editing data. It can display various types of input fields (text, number, ID, rows of inputs, custom widgets) and includes validation logic. This dialog is reused in several places, such as when adding or editing variables, keypad buttons, or chart configurations.

*   [`lib/ui/widgets/select_device_dialog.dart`](lib/ui/widgets/select_device_dialog.dart):
    A dialog used for selecting a device to connect to, typically for Bluetooth or USB connections. It displays a searchable list of available devices and uses a callback function to initiate the connection when a device is selected.

## [`lib/ui/widgets/panels/`](lib/ui/widgets/panels/)

This subdirectory contains specific implementations of panels that are used to display content within the application's pages. They are typically based on the `BasePanel` class.

*   [`lib/ui/widgets/panels/base_panel.dart`](lib/ui/widgets/panels/base_panel.dart):
    An abstract base class for all content panels. It provides a consistent visual structure (a `Card` with a title) and handles asynchronous state loading using a `FutureBuilder`. Custom panels extend this class and implement the `loadState` (to load data) and `buildPanel` (to build the panel's content) methods.

*   [`lib/ui/widgets/panels/chart_panel.dart`](lib/ui/widgets/panels/chart_panel.dart):
    Displays a real-time line chart using the `fl_chart` package. It visualizes data from observable variables managed by the [`DataService`](lib/services/data_service.dart) based on the provided `ChartData` configuration. It also includes functionality for editing the chart's properties and variables using the [`EditDialog`](lib/ui/widgets/edit_dialog.dart).

*   [`lib/ui/widgets/panels/keypad_panel.dart`](lib/ui/widgets/panels/keypad_panel.dart):
    Displays a grid of customizable buttons. Each button is configured to send a specific `DataPacket` when pressed. It supports predefined buttons and allows adding/editing custom buttons using the [`EditDialog`](lib/ui/widgets/edit_dialog.dart). It also includes an optional text field and button for sending custom messages.

*   [`lib/ui/widgets/panels/log_panel.dart`](lib/ui/widgets/panels/log_panel.dart):
    Displays the content of an observable list of strings (a log) in a read-only text field. It provides buttons to copy the log content to the clipboard and clear the log. It is used by the [`LogsPage`](lib/ui/pages/logs_page.dart) to display different types of logs.

*   [`lib/ui/widgets/panels/sliders_panel.dart`](lib/ui/widgets/panels/sliders_panel.dart):
    Displays a list of interactive slider controls. Each slider is associated with a `DataPacket` and sends the slider's value to the connected device when it changes. It loads slider configurations from storage and allows adding/editing sliders using the [`EditDialog`](lib/ui/widgets/edit_dialog.dart).

*   [`lib/ui/widgets/panels/variables_panel.dart`](lib/ui/widgets/panels/variables_panel.dart):
    Displays a grid of variables received from the connected device. It shows the variable's name and its current value (obtained from the [`DataService`](lib/services/data_service.dart)). It loads variable configurations from storage and allows adding/editing variables using the [`EditDialog`](lib/ui/widgets/edit_dialog.dart).

Understanding the organization of the UI into pages, reusable widgets, and panels, along with how they interact with the services, is key to modifying or adding new visual components to the application.

Next, let's explore the [Utils: Helper Functions and Constants](utils.md).