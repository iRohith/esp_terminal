import 'package:esp_terminal/services/connection_service.dart';
import 'package:esp_terminal/services/data_service.dart';
import 'package:esp_terminal/services/settings_service.dart';
import 'package:esp_terminal/services/storage_service.dart';
import 'package:esp_terminal/ui/pages/page_wrapper.dart';
import 'package:esp_terminal/ui/panels/base_panel.dart';
import 'package:esp_terminal/util/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A page for managing application settings, including theme, app reset, and Wi-Fi credentials.
///
/// This page allows users to configure various aspects of the application,
/// such as switching between dark and light themes, resetting all stored data,
/// and entering Wi-Fi network details for devices that connect via Wi-Fi.
class SettingsPage extends StatelessWidget {
  /// Constructs a [SettingsPage].
  const SettingsPage({super.key});

  @override
  /// Builds the widget tree for the settings page.
  ///
  /// It organizes settings into panels for general settings and Wi-Fi settings,
  /// using [BasePanel] for consistent styling.
  Widget build(BuildContext context) {
    // Access the singleton instance of DataService for managing application data.
    final ds = DataService.to;

    // Retrieve observable state variables for Wi-Fi settings from DataService.
    // These values are persisted across app sessions.
    final ssid = ds.get("ssid", () => "".obs); // Observable for Wi-Fi SSID.
    final username = ds.get(
      "username",
      () => "".obs,
    ); // Observable for WPA2 username.
    final pwd = ds.get("pwd", () => "".obs); // Observable for Wi-Fi password.
    final wsrelay = ds.get(
      "wsrelay",
      () => "ws://".obs,
    ); // Observable for WebSocket Relay URL.

    // Create TextEditingControllers for each input field, initialized with current observable values.
    final ssidCtrl = TextEditingController(text: ssid.value);
    final usernameCtrl = TextEditingController(text: username.value);
    final pwdCtrl = TextEditingController(text: pwd.value);
    final wsrelayCtrl = TextEditingController(text: wsrelay.value);

    // Add listeners to update the observable state variables whenever the text in the controllers changes.
    ssidCtrl.addListener(() => ssid.value = ssidCtrl.text);
    usernameCtrl.addListener(() => username.value = usernameCtrl.text);
    pwdCtrl.addListener(() => pwd.value = pwdCtrl.text);
    wsrelayCtrl.addListener(() => wsrelay.value = wsrelayCtrl.text);

    return PageWrapper(
      title: "Settings", // Set the title for the settings page.
      useScroll:
          false, // Disable scrolling for this page as content fits without it.
      panels: [
        // Panel for general application settings.
        BasePanel(
          title: "Settings",
          // Panel title.
          id: "settings",
          // Unique ID for the panel.
          width: Get.width * 0.8,
          // Set the panel width to 80% of screen width for responsiveness.
          constraintHeight: false,
          // Do not constrain the panel height, allowing it to expand as needed.
          child: Padding(
            padding: const EdgeInsets.all(
              8.0,
            ), // Add padding around the content for visual spacing.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              // Center content vertically within the column.
              crossAxisAlignment: CrossAxisAlignment.center,
              // Center content horizontally within the column.
              mainAxisSize: MainAxisSize.min,
              // Column takes minimum vertical space, fitting its children.
              spacing: 12,
              // Vertical spacing between children widgets.
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // Space out children horizontally, pushing them to ends.
                  children: [
                    const Text(
                      "Dark Theme", // Label for the dark theme switch.
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    ObxValue(
                      (isDarkMode) => Switch(
                        value: isDarkMode.value,
                        // Current value of the switch, bound to the isDarkMode observable.
                        onChanged: (value) => isDarkMode.value =
                            value, // Update the observable when the switch state changes.
                      ),
                      SettingsService
                          .to
                          .isDarkMode, // The observable controlling the dark theme state.
                    ),
                  ],
                ),
                ElevatedButton(
                  // Button to reset the application to its initial state.
                  onPressed: () async {
                    // Clear all data from persistent storage.
                    await StorageService.to.clear();
                    // Reset application settings to their default values.
                    SettingsService.to.reset();
                    // Reset the connection service state.
                    ConnectionService.to.reset();
                    // Navigate to the connection page, clearing the entire navigation stack.
                    Get.offAllNamed(Routes.connection);

                    // Display a snackbar to inform the user that the app has been reset.
                    Get.snackbar(
                      "App reset", // Snackbar title.
                      "", // Empty message for a cleaner look.
                      snackPosition: SnackPosition.BOTTOM,
                      // Position the snackbar at the bottom of the screen.
                      duration: const Duration(
                        seconds: 2,
                      ), // Display duration for the snackbar.
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Get.theme.colorScheme.primaryContainer,
                    foregroundColor: Get.theme.colorScheme.onPrimaryContainer,
                    elevation: 8,
                  ),
                  child: const Text(
                    "Reset App",
                  ), // Text displayed on the button.
                ),
              ],
            ),
          ),
        ),

        // Panel for Wi-Fi settings, allowing users to configure network credentials.
        BasePanel(
          id: "wifi",
          // Unique ID for the panel.
          title: "Wifi",
          // Panel title.
          width: Get.width * 0.8,
          // Set the panel width to 80% of screen width.
          constraintHeight: false,
          // Do not constrain the panel height.
          child: Padding(
            padding: const EdgeInsets.all(
              8.0,
            ), // Add padding around the content.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              // Center content vertically.
              crossAxisAlignment: CrossAxisAlignment.center,
              // Center content horizontally.
              mainAxisSize: MainAxisSize.min,
              // Column takes minimum vertical space.
              spacing: 12,
              // Vertical spacing between children.
              children: [
                TextField(
                  controller:
                      ssidCtrl, // Link to the SSID text controller for input.
                  decoration: const InputDecoration(
                    labelText: "SSID", // Label for the input field.
                    border:
                        OutlineInputBorder(), // Visual border around the input field.
                  ),
                  keyboardType: TextInputType
                      .name, // Suggest name keyboard type for easier input.
                  maxLines: 1, // Restrict input to a single line.
                ),

                ValueBuilder<bool?>(
                  initialValue: true,
                  // Initial state: password text is obscured for security.
                  builder: (obscureText, updateFn) => TextField(
                    controller: pwdCtrl,
                    // Link to the password text controller for input.
                    keyboardType: TextInputType.visiblePassword,
                    // Suggest visible password keyboard type.
                    maxLines: 1,
                    // Restrict input to a single line.
                    decoration: InputDecoration(
                      labelText: "Password",
                      // Label for the input field.
                      border: const OutlineInputBorder(),
                      // Visual border around the input field.
                      suffixIcon: IconButton(
                        // Icon button to toggle password visibility.
                        icon: Icon(
                          obscureText! // Use `!` to assert non-nullability after initialValue.
                              ? Icons
                                    .visibility // Show visibility icon if text is obscured.
                              : Icons.visibility_off,
                          // Show visibility_off icon if text is visible.
                          color: Colors.grey, // Set icon color to grey.
                        ),
                        onPressed: () => updateFn(
                          !obscureText,
                        ), // Toggle obscureText state on press.
                      ),
                    ),
                    obscureText:
                        obscureText, // Control text obscuring based on state.
                  ),
                ),

                TextField(
                  controller: usernameCtrl,
                  // Link to the username text controller for input.
                  decoration: const InputDecoration(
                    labelText: "WPA2 Username", // Label for the input field.
                    border:
                        OutlineInputBorder(), // Visual border around the input field.
                  ),
                  keyboardType: TextInputType.name,
                  // Suggest name keyboard type.
                  maxLines: 1, // Restrict input to a single line.
                ),

                TextField(
                  controller: wsrelayCtrl,
                  // Link to the WS Relay URL text controller for input.
                  decoration: const InputDecoration(
                    labelText: "WS Relay URL", // Label for the input field.
                    border:
                        OutlineInputBorder(), // Visual border around the input field.
                  ),
                  keyboardType: TextInputType.name,
                  // Suggest name keyboard type.
                  maxLines: 1, // Restrict input to a single line.
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // Space out children horizontally, pushing them to ends.
                  children: [
                    ElevatedButton(
                      // Button to send Wi-Fi credentials to the connected device.
                      onPressed: () async {
                        // Construct the message string with SSID, password, and username.
                        ConnectionService.to.writeMessage(
                          "SSID:${ssid.value};;PWD:${pwd.value};;USERNAME:${username.value}",
                          log:
                              false, // Do not log this message to the send log (sensitive info).
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Get.theme.colorScheme.primaryContainer,
                        foregroundColor:
                            Get.theme.colorScheme.onPrimaryContainer,
                        elevation: 8,
                      ),
                      child: const Text(
                        "Send Creds",
                      ), // Text displayed on the button.
                    ),

                    ElevatedButton(
                      // Button to send the WebSocket Relay URL to the connected device.
                      onPressed: () async {
                        // Construct the message string with the WS Relay URL.
                        ConnectionService.to.writeMessage(
                          "WSRELAY:${wsrelay.value}",
                          log:
                              false, // Do not log this message as it might contain sensitive info.
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Get.theme.colorScheme.primaryContainer,
                        foregroundColor:
                            Get.theme.colorScheme.onPrimaryContainer,
                        elevation: 8,
                      ),
                      child: const Text(
                        "Send Relay",
                      ), // Text displayed on the button.
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
