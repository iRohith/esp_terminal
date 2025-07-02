import 'package:esp_terminal/services/settings_service.dart';
import 'package:esp_terminal/ui/panels/base_panel.dart';
import 'package:esp_terminal/ui/widgets/side_menu.dart';
import 'package:esp_terminal/util/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A wrapper widget that provides a consistent page structure with an app bar,
/// a side menu, and a body for displaying content panels.
///
/// This widget is used to wrap the content of different pages in the application
/// to maintain a uniform look and feel. It includes a title in the app bar,
/// an icon indicating the current connection type, and a drawer for navigation.
class PageWrapper extends StatelessWidget {
  // The list of content panels to display in the body.
  final List<BasePanel> panels;

  // An optional extra widget to display below the panels.
  final Widget? extraWidget;

  final String title; // The title to display in the app bar.
  final bool useScroll; // Whether the body content should be scrollable.

  /// Constructs a [PageWrapper].
  ///
  /// [panels] is the required list of panels. [title] is the page
  /// title. [useScroll] determines if the body should
  /// be scrollable (defaults to true). [extraWidget] is an optional widget
  /// to include at the end of all panels.
  const PageWrapper({
    super.key,
    required this.title,
    required this.panels,
    this.useScroll = true,
    this.extraWidget,
  });

  @override
  /// Builds the widget tree for the page wrapper.
  ///
  /// Constructs a [Scaffold] with an [AppBar], [SideMenu] drawer, and a body
  /// containing the provided panels and optional extra widget.
  Widget build(BuildContext context) {
    // Get [connectionType] setting state variable to display the icon.
    final connectionType = SettingsService.to.connectionType;

    // Arrange the panels and optional extra widget in a column.
    final child = panels.length == 1 && extraWidget == null
        ? Center(
            child: panels.first,
          ) // Center the single panel if no extra widget.
        : SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...panels.map(
                  (p) => ExpansionTile(
                    title: Obx(() => Text(p.title.value)),
                    initiallyExpanded: true,
                    children: [p],
                  ),
                ),
                if (extraWidget != null) extraWidget!,
              ],
            ),
          );

    // Build the Scaffold with AppBar, Drawer, and Body.
    return Scaffold(
      appBar: AppBar(
        title: Text(title), // Display the page title.
        backgroundColor: Theme.of(
          context,
        ).colorScheme.inversePrimary, // Set the app bar background color.
        actions: <Widget>[
          // IconButton to navigate to the connection page.
          IconButton(
            onPressed: () {
              Get.toNamed(
                Routes.connection,
              ); // Navigate to the connection page.
            },
            icon: Obx(() {
              // Determine the icon based on the current connection type.
              final c = connectionType.value?.toLowerCase() ?? "None";
              var icon = Icons.do_not_disturb;
              if (c.startsWith("ws") || c.contains("wifi")) {
                icon = Icons.wifi;
              } else if (c.contains("usb")) {
                icon = Icons.usb;
              } else if (c.contains("ble") || c.contains("bt")) {
                icon = Icons.bluetooth;
              }
              return Icon(icon);
            }),
          ),
        ],
      ),
      drawer: SideMenu(), // Include the SideMenu as the drawer.
      body: SafeArea(
        // Ensure content is within the safe area.
        child: useScroll ? SingleChildScrollView(child: child) : child,
      ),
    );
  }
}
