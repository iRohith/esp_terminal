import 'dart:async';
import 'dart:io';

import 'package:esp_terminal/connectors/base_connector.dart';
import 'package:esp_terminal/ui/widgets/select_device_dialog.dart';
import 'package:esp_terminal/util/permission_handler.dart';
import 'package:esp_terminal/util/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:universal_ble/universal_ble.dart';

/// Implements a connector for Bluetooth Low Energy (BLE) devices.
///
/// This class handles BLE-specific operations like scanning, connecting,
/// disconnecting, and data transfer using the `universal_ble` plugin.
class BleConnector extends BaseConnector {
  /// Service UUID for the BLE device.
  static final suuid = ("6db99c15-8890-4fa8-8138-2a1a55deebbf");

  /// Write Characteristic UUID for sending data to the BLE device.
  static final wcuuid = ("c389bbb2-c68e-4a4e-8f62-8e0f0fa7e4c6");

  /// Read Characteristic UUID for receiving data from the BLE device.
  static final rcuuid = ("95e8186c-6ed1-42e8-a1e2-22dfa4c11f68");

  /// The currently connected BLE device. Null if no device is connected.
  BleDevice? connectedDevice;

  /// Observable boolean indicating if Bluetooth is currently enabled.
  final bluetoothOn = false.obs;

  /// Initializes the BLE connector.
  ///
  /// Checks Bluetooth permissions and prompts the user to enable Bluetooth if off.
  /// Returns `true` if successful, `false` otherwise.
  @override
  Future<bool> init() async {
    // Check if Bluetooth permissions are granted. If not, show an error and return.
    if (!(await PermissionHandler.areBtPermissionsGranted())) {
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

    return true; // Initialization successful.
  }

  /// Disposes of BLE connector resources.
  ///
  /// Currently, no specific resources require explicit disposal.
  @override
  Future<bool> dispose() async {
    return true;
  }

  /// Initiates the connection process to a BLE device.
  ///
  /// Scans for devices advertising [suuid], presents a selection dialog,
  /// and attempts to connect to the chosen device.
  /// Returns `true` if connected, `false` otherwise.
  @override
  Future<bool> connect() async {
    // Initialize observable list for devices and a map for quick lookup.
    final devices = <(String, String)>[].obs;
    final deviceMap = <String, BleDevice>{};

    // Get already paired/system devices that advertise the service UUID.
    for (final d in await UniversalBle.getSystemDevices(
      withServices: [suuid],
    )) {
      // Add device to the list, using "Unknown" if the name is empty.
      devices.add(((d.name ?? "").isEmpty ? "Unknown" : d.name!, d.deviceId));
      deviceMap[d.deviceId] = d; // Store device in map for easy access.
    }

    // Set up a callback for new scan results.
    UniversalBle.onScanResult = (d) {
      deviceMap[d.deviceId] = d; // Update device in map.
      var idx = devices.indexWhere(
        (v) => v.$2 == d.deviceId,
      ); // Find existing device in list.
      final val = (
        (d.name ?? "").isEmpty ? "Unknown" : d.name!,
        d.deviceId,
      ); // Create new value tuple.
      if (idx == -1) {
        devices.add(val); // Add new device if not found.
      } else {
        devices[idx] = val; // Update existing device.
      }
    };

    // Start scanning for BLE devices.
    await UniversalBle.startScan();

    // Show a dialog to allow the user to select a device.
    connected.value =
        true ==
        await Get.dialog(
          SelectDeviceDialog(
            name: "BLE device", // Title for the dialog.
            devices: devices, // List of discovered devices.
            connectCallback: (_, d) async {
              try {
                await UniversalBle.stopScan(); // Stop scanning once a device is selected.
                printInfo(info: "Connecting...");
                UniversalBle.connect(
                  d,
                ); // Initiate connection to the selected device.

                // Set up a callback for connection status changes.
                UniversalBle
                    .onConnectionChange = (deviceId, isConnected, error) async {
                  if (isConnected) {
                    // If connected, discover services, request MTU, and subscribe to notifications.
                    await UniversalBle.discoverServices(d);
                    UniversalBle.requestMtu(
                      d,
                      512,
                    ); // Request a larger MTU for data transfer.
                    await UniversalBle.subscribeNotifications(
                      deviceId,
                      suuid, // Service UUID.
                      rcuuid, // Read Characteristic UUID.
                    );
                    connectedDevice =
                        deviceMap[d]!; // Store the connected device.
                    printInfo(info: "Connected: $d");

                    // Update the global connection status.
                    UniversalBle.onConnectionChange = (_, c, _) {
                      connected.value = c;
                    };

                    Get.back(
                      result: true,
                    ); // Close the dialog with a success result.
                  } else {
                    Get.back(
                      result: false,
                    ); // Close the dialog with a failure result.
                  }
                };
              } catch (e, st) {
                printError(info: "BLE Connect error: $e\n$st");
                Get.back(
                  result: false,
                ); // Close the dialog with a failure result on error.
              }
            },
          ),
        );

    return connected.value; // Return the final connection status.
  }

  /// Disconnects from the currently connected BLE device.
  ///
  /// Clears the connected device reference and updates the connection status.
  /// Returns `true` if the disconnection attempt is completed.
  @override
  Future<bool> disconnect() async {
    // Attempt to disconnect from the connected device using tryFunc for error handling.
    await tryFunc(
      () => UniversalBle.disconnect(connectedDevice!.deviceId),
      name: "BLE Disconnect", // Name for logging the operation.
    );
    connectedDevice = null; // Clear the reference to the connected device.
    connected.value = false; // Update the connection status to disconnected.
    return true; // Disconnection attempt completed.
  }

  /// Provides a stream for reading incoming data from the BLE device.
  ///
  /// Sets up a listener for characteristic value changes and adds received bytes to the stream.
  /// Returns a [Stream<int>] where each integer is a single byte.
  @override
  Stream<int> read() {
    printInfo(info: "Connected... Reading...");
    showSnackbar("Connected", "Successfully connected to BLE device.");

    // Create a StreamController to manage the incoming byte stream.
    final s = StreamController<int>();

    // Set up a callback for characteristic value changes (incoming data).
    UniversalBle.onValueChange =
        (String deviceId, String characteristicId, Uint8List value) async {
          try {
            // Ensure the data is from the connected device and the correct read characteristic.
            if (deviceId == connectedDevice?.deviceId &&
                characteristicId.toLowerCase() == rcuuid.toLowerCase()) {
              // Add each byte from the received value to the stream.
              for (final b in value) {
                s.add(b);
              }
            }
          } catch (e, st) {
            s.add(-1); // Add an error indicator to the stream.
            printError(info: "Ble read error: $e\n$st");
            connected.value =
                false; // Update connection status to disconnected on error.
            UniversalBle.onValueChange =
                (_, _, _) {}; // Clear the callback to prevent further errors.
          }
        };

    return s.stream; // Return the stream of incoming bytes.
  }

  /// Writes a buffer of data to the BLE device.
  ///
  /// Sends the provided [Uint8List] to the write characteristic ([wcuuid]).
  /// Returns the number of bytes successfully written, or -1 on error.
  @override
  Future<int> write(Uint8List buffer) async {
    try {
      // Write the buffer to the specified characteristic of the connected device.
      UniversalBle.write(connectedDevice!.deviceId, suuid, wcuuid, buffer);
      return buffer.length; // Return the number of bytes written.
    } catch (e, st) {
      printError(
        info: "BLE Write error: $e\n$st",
      ); // Log any errors during writing.
      return -1; // Return -1 to indicate an error.
    }
  }
}
