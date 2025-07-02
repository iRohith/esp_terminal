import 'dart:io';

import 'package:esp_terminal/connectors/ble_connector.dart';
import 'package:esp_terminal/connectors/bt_connector.dart';
import 'package:esp_terminal/connectors/none_connector.dart';
import 'package:esp_terminal/connectors/test_connector.dart';
import 'package:esp_terminal/connectors/usb_connector.dart';
import 'package:esp_terminal/connectors/ws_cloud_connector.dart';
import 'package:esp_terminal/connectors/ws_local_connector.dart';
import 'package:esp_terminal/services/connection_service.dart';
import 'package:esp_terminal/services/data_service.dart';
import 'package:esp_terminal/services/log_service.dart';
import 'package:esp_terminal/services/settings_service.dart';
import 'package:esp_terminal/services/storage_service.dart';
import 'package:esp_terminal/ui/root_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Main entry point of the application.
///
/// Initializes services and runs the Flutter UI.
void main() async {
  initServices(); // Initialize all application services.
  runApp(const RootLayout()); // Run the Flutter application.
}

/// Initializes application services using GetX for dependency injection.
///
/// Sets up core services like logging, storage, connection management, settings,
/// and data handling. Services are registered using `lazyPut` for
/// improved startup performance and reduced memory consumption.
void initServices() {
  // Register core services
  Get.lazyPut(() => StorageService());
  Get.lazyPut(() => DataService());
  Get.lazyPut(() => LogService());
  Get.lazyPut(() => SettingsService());

  // Register ConnectionService with all available connectors
  Get.lazyPut(
    () => ConnectionService({
      "None": () => NoneConnector(),
      "BLE": () => BleConnector(),
      // Bluetooth Low Energy connector
      if (!kIsWeb && Platform.isAndroid) "BT Classic": () => BTConnector(),
      // Bluetooth Classic (Android only)
      "USB": () => UsbConnector(),
      // USB serial connector
      "WS Local": () => WSLocalConnector(),
      // WebSocket local network connector
      "WS Cloud": () => WSCloudConnector(),
      // WebSocket cloud connector
      "Test": () => TestConnector(),
      // Test/mock connector
    }),
  );
}
