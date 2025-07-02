import 'package:esp_terminal/modals/data_packet.dart';
import 'package:esp_terminal/ui/pages/page_wrapper.dart';
import 'package:esp_terminal/ui/panels/keypad_panel.dart';
import 'package:esp_terminal/ui/panels/sliders_panel.dart';
import 'package:esp_terminal/util/constants.dart';
import 'package:flutter/material.dart';

/// A page that provides a customizable keypad for sending commands.
///
/// Displays a [KeypadPanel] and a [SlidersPanel] within a [PageWrapper].
class KeypadPage extends StatelessWidget {
  /// Constructs a [KeypadPage].
  const KeypadPage({super.key});

  @override
  /// Builds the widget tree for the keypad page.
  ///
  /// Arranges a [KeypadPanel] and a [SlidersPanel] within a [PageWrapper].
  Widget build(BuildContext context) {
    return PageWrapper(
      title: "Keypad", // Set the title for the keypad page.
      panels: [
        // Display the KeypadPanel, allowing users to send commands via buttons.
        KeypadPanel(
          id: "keypad",
          // Unique ID for this panel instance.
          editable: true,
          // Allow users to edit keypad buttons on this page.
          constraintHeight: false,
          // Do not constrain the height of this panel.
          enableSendMessageButton: true,
          // Enable a button to send messages.
          labelledButtons: [
            // Define a row of pre-configured labelled buttons.
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

        // Display the SlidersPanel, allowing users to control values via sliders.
        SlidersPanel(
          id: "home_sliders", // Unique ID for this panel instance.
          editable: true, // Allow users to edit sliders on this page.
          constraintHeight: false, // Do not constrain the height of this panel.
        ),
      ],
    );
  }
}
