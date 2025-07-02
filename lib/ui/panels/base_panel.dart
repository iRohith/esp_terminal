import 'package:esp_terminal/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A base class for creating content panels used within the application's pages.
///
/// This class provides a consistent structure for panels, including a title,
/// a defined width, optional height constraints, and a child widget for the
/// panel's content. It also includes basic loading state handling.
///
/// The generic type [State] can be used to specify the type of data loaded
/// asynchronously by the panel.
class BasePanel<State> extends StatelessWidget {
  final String
  id; // A unique identifier for the panel, used for identification and state management.
  final RxString
  title; // The title displayed at the top of the panel, made reactive with [RxString].
  final double width; // The width of the panel.
  final Widget? child; // The main content widget of the panel.
  final bool
  constraintHeight; // Whether to constrain the height of the panel to [MAX_PANEL_HEIGHT].
  final bool showTitle; // Whether to display the panel's title.

  /// Constructs a [BasePanel].
  ///
  /// [id] is required and must be unique. [title] defaults to 'Unknown' if not provided.
  /// [width] defaults to [double.infinity] to fill available width.
  /// [constraintHeight] defaults to true, limiting the panel's height.
  /// [showTitle] defaults to false, hiding the title by default.
  /// [child] is an optional widget to be displayed as the panel's content.
  BasePanel({
    super.key,
    required this.id,
    String title = 'Unknown',
    this.width = double.infinity,
    this.constraintHeight = true,
    this.showTitle = false,
    this.child,
  }) : title = title.obs; // Initialize the reactive title.

  @override
  /// Builds the widget tree for the base panel.
  ///
  /// Uses a [FutureBuilder] to handle asynchronous state loading and displays
  /// a loading indicator, error placeholder, or the panel content based on the future's state.
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadState(), // Asynchronously load the panel's state.
      builder: (context, state) {
        // Default child widget is a loading indicator.
        Widget child = const Center(child: CircularProgressIndicator());

        // Determine the content to display based on the future's state.
        if (state.hasError) {
          // If an error occurs during state loading, display a placeholder.
          child = const Placeholder();
        } else if (state.connectionState == ConnectionState.done) {
          // If the future is complete, build the panel content.
          child = Column(
            mainAxisSize:
                MainAxisSize.min, // Column takes minimum vertical space.
            crossAxisAlignment: CrossAxisAlignment
                .start, // Align children to the start horizontally.
            spacing: 8, // Vertical spacing between children.
            children: [
              if (showTitle)
                Obx(
                  () => Text(
                    title.value,
                    // Display the panel title, reacting to changes in [title.value].
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              // Build the panel content using the overridable [buildPanel] method.
              // If [buildPanel] returns null, display a [Placeholder].
              buildPanel(context, state.data) ?? Placeholder(),
            ],
          );
        }

        // Wrap the content in a Card for consistent visual styling.
        return Card(
          elevation: 8, // Card elevation for a shadow effect.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ), // Rounded corners for the card.
          ),
          child: Container(
            width: width, // Set the container width.
            constraints: // Apply height constraints if [constraintHeight] is true.
            constraintHeight
                ? BoxConstraints(maxHeight: MAX_PANEL_HEIGHT.toDouble())
                : null,
            padding: const EdgeInsets.all(8.0), // Padding inside the container.
            child:
                // If height is constrained, make content scrollable. Otherwise, display directly.
                constraintHeight ? SingleChildScrollView(child: child) : child,
          ),
        );
      },
    );
  }

  /// Builds the main content widget of the panel.
  ///
  /// This method can be overridden by subclasses to provide specific panel content
  /// based on the loaded [state] data.
  ///
  /// [context]: The build context.
  /// [state]: The data loaded by [loadState].
  /// Returns the panel's content widget, or null if no specific content is provided.
  Widget? buildPanel(BuildContext context, State? state) {
    // Default implementation returns the provided [child] widget.
    return child;
  }

  /// Loads the asynchronous state for the panel.
  ///
  /// This method can be overridden by subclasses to load data needed for the panel
  /// before its content is built.
  /// Returns a [Future] that completes with the panel's state data.
  Future<State?> loadState() async {
    // Default implementation returns null, indicating no asynchronous state loading.
    return null;
  }
}
