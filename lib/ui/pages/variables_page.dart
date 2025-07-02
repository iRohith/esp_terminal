import 'package:esp_terminal/ui/pages/page_wrapper.dart';
import 'package:esp_terminal/ui/panels/variables_panel.dart';
import 'package:flutter/material.dart';

/// A page dedicated to displaying and managing application variables.
///
/// This page primarily hosts a [VariablesPanel] within a [PageWrapper],
/// allowing users to view and interact with various data variables.
class VariablesPage extends StatelessWidget {
  /// Constructs a [VariablesPage].
  const VariablesPage({super.key});

  @override
  /// Builds the widget tree for the variables page.
  ///
  /// Displays a [VariablesPanel] configured for editing and full height.
  Widget build(BuildContext context) {
    return PageWrapper(
      title: "Variables", // Set the title for the variables page.
      panels: [
        // Display the VariablesPanel, which shows and allows editing of variables.
        VariablesPanel(
          id: "variables", // Unique ID for this panel instance.
          constraintHeight: false, // Do not constrain the height of this panel.
          editable: true, // Allow users to edit variables on this page.
          showTitle: true, // Display the title within the VariablesPanel.
        ),
      ],
    );
  }
}
