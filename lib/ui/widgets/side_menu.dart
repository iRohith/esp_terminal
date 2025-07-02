import 'package:esp_terminal/services/data_service.dart';
import 'package:esp_terminal/util/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A side menu (Drawer) for navigating between application pages.
///
/// Displays navigation options and real-time connection statistics.
class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the DataService instance for real-time data.
    final ds = DataService.to;

    // The main Drawer widget for the side menu.
    return Drawer(
      child: ListView(
        // Remove default padding to allow content to extend to edges.
        padding: EdgeInsets.zero,
        children: [
          // SizedBox to control the height of the DrawerHeader.
          SizedBox(
            height: 180,
            // Header for the side menu, displaying app title and connection stats.
            child: DrawerHeader(
              decoration: BoxDecoration(
                // Use the primary container color from the theme for the header background.
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                // Align content to the start (left) of the column.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App title.
                  const Text('ESP Terminal', style: TextStyle(fontSize: 24)),
                  // Add some vertical spacing.
                  const SizedBox(height: 8),
                  // Obx widget to reactively display data service statistics.
                  Obx(
                    () => Column(
                      // Align content to the start (left) of the column.
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display data transfer speed.
                        Text(
                          "Speed: ${ds.speed.value.toStringAsFixed(2)} KB/s",
                        ),
                        // Display data latency.
                        Text("Latency: ${ds.latency.value.round()} ms"),
                        // Display variables per second.
                        Text(
                          "Vars: ${ds.varsPerSecond.value.toStringAsFixed(2)} /s",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Home navigation list tile.
          ListTile(
            title: const Text('Home'),
            // Navigate to home, removing all previous routes from the stack.
            onTap: () => Get.offAllNamed(Routes.home),
          ),
          // Variables navigation list tile.
          ListTile(
            title: const Text('Variables'),
            // Navigate to variables page.
            onTap: () => Get.offAllNamed(Routes.variables),
          ),
          // Keypad navigation list tile.
          ListTile(
            title: const Text('Keypad'),
            // Navigate to keypad page.
            onTap: () => Get.offAllNamed(Routes.keypad),
          ),
          // Charts navigation list tile.
          ListTile(
            title: const Text('Charts'),
            // Navigate to charts page.
            onTap: () => Get.offAllNamed(Routes.charts),
          ),
          // Send file navigation list tile.
          ListTile(
            title: const Text('Send file'),
            // Navigate to send file page.
            onTap: () => Get.offAllNamed(Routes.sendFile),
          ),

          // Divider to visually separate navigation sections.
          const Divider(),

          // Logs navigation list tile.
          ListTile(
            title: const Text('Logs'),
            // Navigate to logs page.
            onTap: () => Get.offAllNamed(Routes.logs),
          ),
          // Connection settings navigation list tile.
          ListTile(
            title: const Text('Connection'),
            // Navigate to connection settings page.
            onTap: () => Get.offAllNamed(Routes.connection),
          ),
          // General settings navigation list tile.
          ListTile(
            title: const Text('Settings'),
            // Navigate to general settings page.
            onTap: () => Get.offAllNamed(Routes.settings),
          ),
        ],
      ),
    );
  }
}
