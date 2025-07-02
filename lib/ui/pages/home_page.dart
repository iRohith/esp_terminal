import 'package:esp_terminal/modals/data_packet.dart';
import 'package:esp_terminal/ui/pages/page_wrapper.dart';
import 'package:esp_terminal/ui/panels/keypad_panel.dart';
import 'package:esp_terminal/ui/panels/sliders_panel.dart';
import 'package:esp_terminal/ui/panels/variables_panel.dart';
import 'package:esp_terminal/util/constants.dart';
import 'package:flutter/material.dart';

/// The home page of the application.
///
/// Displays various panels such as variables, keypad, and sliders,
/// providing a central dashboard for device interaction.
class HomePage extends StatelessWidget {
  /// Constructs a [HomePage].
  const HomePage({super.key});

  @override
  /// Builds the widget tree for the home page.
  ///
  /// Arranges [VariablesPanel], [KeypadPanel], and [SlidersPanel] within a [PageWrapper].
  Widget build(BuildContext context) {
    return PageWrapper(
      title: "Home", // Set the title for the home page.
      panels: [
        // Display the VariablesPanel, showing device variables.
        VariablesPanel(
          id: "home_variables", // Unique ID for this panel instance.
          editable: false, // Variables are not editable from the home page.
          constraintHeight: true, // Constrain the height of this panel.
        ),

        // Display the KeypadPanel, providing interactive buttons.
        KeypadPanel(
          id: "home_keypad", // Unique ID for this panel instance.
          editable:
              false, // Keypad buttons are not editable from the home page.
          constraintHeight: true, // Constrain the height of this panel.
          labelledButtons: [
            // Define a row of labelled buttons for common commands.
            [
              (
                "ON", // Button label.
                DataPacket(
                  cmd: ON_SEND,
                  id: 0x11,
                ), // Data packet to send when "ON" is pressed.
              ),
              (
                "OFF", // Button label.
                DataPacket(
                  cmd: OFF_SEND,
                  id: 0x12,
                ), // Data packet to send when "OFF" is pressed.
              ),
              (
                "MODE", // Button label.
                DataPacket(
                  cmd: MODE_SEND,
                  id: 0x13,
                ), // Data packet to send when "MODE" is pressed.
              ),
            ],
          ],
        ),

        // Display the SlidersPanel, showing interactive sliders.
        SlidersPanel(
          id: "home_sliders", // Unique ID for this panel instance.
          editable: false, // Sliders are not editable from the home page.
          constraintHeight: false, // Do not constrain the height of this panel.
        ),
      ],
    );
  }
}
