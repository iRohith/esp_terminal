import 'dart:async';
import 'dart:io';

import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:esp_terminal/connectors/base_connector.dart';
import 'package:esp_terminal/ui/widgets/select_device_dialog.dart';
import 'package:esp_terminal/util/permission_handler.dart';
import 'package:esp_terminal/util/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:universal_ble/universal_ble.dart';

/// Implements a connector for Bluetooth Classic devices.
///
/// Handles device discovery, connection, disconnection, and data transfer
/// using the `bluetooth_classic` plugin.
class BTConnector extends BaseConnector {
  /// The Service UUID (SUUID) for Bluetooth Classic serial port profile (SPP).
  static final suuid = "00001101-0000-1000-8000-00805F9B34FB";

  /// Instance of the `BluetoothClassic` plugin.
  final _bt = BluetoothClassic();

  /// Observable boolean indicating if Bluetooth is currently enabled.
  final bluetoothOn = false.obs;

  /// The currently connected Bluetooth Classic device. Null if no device is connected.
  Device? connectedDevice;

  /// Static flags and callbacks to manage event subscriptions from the `bluetooth_classic` plugin.
  static bool subscriptionsAdded = false;
  static Function(Device)? onDeviceDiscovered;
  static Function(int)? onDeviceStatusChanged;

  /// Initializes the Bluetooth Classic connector.
  ///
  /// Verifies Bluetooth permissions and prompts the user to enable Bluetooth if off.
  /// Sets up global listeners for device discovery and status changes.
  /// Returns `true` if successful, `false` otherwise.
  @override
  Future<bool> init() async {
    // Check if Bluetooth permissions are granted and initialize plugin permissions.
    if (!(await PermissionHandler.areBtPermissionsGranted()) ||
        !(await _bt.initPermissions())) {
      await showSnackbar("Error", "Missing permissions");
      return false;
    }

    // Get the current Bluetooth availability state.
    final state = await UniversalBle.getBluetoothAvailabilityState();

    // If Bluetooth is powered off, prompt the user to turn it on.
    if (state == AvailabilityState.poweredOff) {
      await Get.defaultDialog(
        title: "Turn bluetooth on",
        middleText: "Please enable Bluetooth to connect to devices.",
        actions: [
          // Button to enable Bluetooth (Android only).
          TextButton(
            onPressed: () async {
              if (!kIsWeb && Platform.isAndroid) {
                await UniversalBle.enableBluetooth();
              }
              Get.back(); // Close the dialog.
            },
            child: const Text("Ok"),
          ),
          // Button to cancel and close the dialog.
          TextButton(
            onPressed: () {
              Get.back(); // Close the dialog.
            },
            child: const Text("Cancel"),
          ),
        ],
      );

      // Listen for changes in Bluetooth availability state.
      UniversalBle.onAvailabilityChange = (s) {
        bluetoothOn.trigger(s == AvailabilityState.poweredOn);
      };

      // Wait until Bluetooth is powered on. If it remains off, show an error.
      if (await bluetoothOn.stream.first == false) {
        await showSnackbar("Error", "Turn on bluetooth");
        return false;
      }
    } else if (state != AvailabilityState.poweredOn) {
      // If Bluetooth is in an unknown or unsupported state, show an error.
      await showSnackbar("Error", "Unknown bluetooth state");
      return false;
    }

    // Set up global static listeners for device discovery and status changes if not already added.
    if (!subscriptionsAdded) {
      _bt.onDeviceDiscovered().listen((d) => onDeviceDiscovered?.call(d));
      _bt.onDeviceStatusChanged().listen((e) => onDeviceStatusChanged?.call(e));
      subscriptionsAdded = true;
    }

    return true; // Initialization successful.
  }

  /// Disposes of Bluetooth Classic connector resources.
  ///
  /// Clears static callback functions to prevent memory leaks.
  /// Returns `true` indicating successful disposal.
  @override
  Future<bool> dispose() async {
    onDeviceDiscovered = null;
    onDeviceStatusChanged = null;
    return true;
  }

  /// Initiates the connection process to a Bluetooth Classic device.
  ///
  /// Retrieves paired devices, scans for new ones, presents a selection dialog,
  /// and attempts to connect using the SPP UUID.
  /// Returns `true` if connected, `false` otherwise.
  @override
  Future<bool> connect() async {
    // Initialize observable list for devices and a map for quick lookup.
    final devices = <(String, String)>[].obs;
    final deviceMap = <String, Device>{};

    // Get already paired Bluetooth Classic devices.
    for (final d in await _bt.getPairedDevices()) {
      // Add device to the list, using "Unknown" if the name is empty.
      devices.add(((d.name ?? "").isEmpty ? "Unknown" : d.name!, d.address));
      deviceMap[d.address] = d; // Store device in map for easy access.
    }

    // Set up a callback for new device discovery during scanning.
    onDeviceDiscovered = (d) {
      deviceMap[d.address] = d; // Update device in map.
      final idx = devices.indexWhere(
        (v) => v.$2 == d.address,
      ); // Find existing device in list.
      final val = (
        (d.name ?? "").isEmpty ? "Unknown" : d.name!,
        d.address,
      ); // Create new value tuple.
      if (idx == -1) {
        devices.add(val); // Add new device if not found.
      } else {
        devices[idx] = val; // Update existing device.
      }
    };

    // Start scanning for Bluetooth Classic devices.
    await _bt.startScan();

    // Show a dialog to allow the user to select a device.
    connected.value =
        true ==
        await Get.dialog(
          SelectDeviceDialog(
            name: "Bluetooth device", // Title for the dialog.
            devices: devices, // List of discovered devices.
            connectCallback: (_, d) async {
              try {
                await _bt
                    .stopScan(); // Stop scanning once a device is selected.
                printInfo(info: "Connecting...");

                // Attempt to connect to the selected device using the SPP UUID.
                await _bt.connect(d, suuid);

                // Set up a callback for device status changes (connected/disconnected).
                onDeviceStatusChanged = (event) {
                  if (event == Device.connected) {
                    connected.value = true; // Update connection status to true.
                  } else if (event == Device.disconnected) {
                    connected.value =
                        false; // Update connection status to false.
                  }
                };
                Get.back(
                  result: true,
                ); // Close the dialog with a success result.
              } catch (e, st) {
                connected.value =
                    false; // Update connection status to false on error.
                printError(info: "BT Classic Connect error: $e\n$st");
                Get.back(
                  result: false,
                ); // Close the dialog with a failure result on error.
              }
            },
          ),
        );

    return connected.value; // Return the final connection status.
  }

  /// Disconnects from the currently connected Bluetooth Classic device.
  ///
  /// Clears static callback functions, connected device reference, and updates connection status.
  /// Returns `true` if the disconnection attempt is completed.
  @override
  Future<bool> disconnect() async {
    onDeviceDiscovered = null; // Clear the device discovered callback.
    onDeviceStatusChanged = null; // Clear the device status changed callback.
    connectedDevice = null; // Clear the reference to the connected device.
    // Attempt to disconnect using tryFunc for robust error handling.
    await tryFunc(_bt.disconnect, name: "BT Classic disconnect");
    connected.value = false; // Update the connection status to disconnected.
    return true; // Disconnection attempt completed.
  }

  /// Provides a stream for reading incoming data from the Bluetooth Classic device.
  ///
  /// Returns a [Stream<int>] where each integer represents a single byte received.
  @override
  Stream<int> read() {
    printInfo(info: "Connected... Reading...");
    showSnackbar(
      "Connected",
      "Successfully connected to Bluetooth Classic device.",
    );

    // Return a stream that expands the received Uint8List into individual bytes (integers).
    return _bt.onDeviceDataReceived().expand<int>((v) => v);
  }

  /// Writes a buffer of data to the Bluetooth Classic device.
  ///
  /// Converts the [Uint8List] to a `String` and sends it.
  /// Returns the number of bytes successfully written, or -1 on error.
  @override
  Future<int> write(Uint8List buffer) async {
    try {
      // Convert the Uint8List buffer to a String and write it to the device.
      await _bt.write(String.fromCharCodes(buffer));
      return buffer.length; // Return the number of bytes written.
    } catch (e, st) {
      printError(
        info: "BT Classic Write error: $e\n$st",
      ); // Log any errors during writing.
      return -1; // Return -1 to indicate an error.
    }
  }
}
