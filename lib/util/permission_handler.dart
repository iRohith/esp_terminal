// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/*
  Required Permissions :
  <----------->
   IOS :
    - Bluetooth
  <----------->
   Android :
   if AndroidVersions < 12
      - Location
      - Bluetooth
    else
      - Bluetooth Scan
      - Bluetooth Connect
  <----------->
    Macos :
  <----------->
    Windows : None
  <----------->
    Linux : None
  <----------->
    Web :
     Check if Browser Supports Bluetooth
  */

/// Handles platform-specific permission requests, primarily for Bluetooth and Location.
/// This class abstracts away the complexities of requesting permissions on different
/// operating systems and Android versions.
class PermissionHandler {
  /// Checks if the necessary Bluetooth and Location permissions are granted.
  ///
  /// Returns `true` if permissions are granted, `false` otherwise.
  /// On non-mobile platforms, this always returns `true`.
  /// If permissions are permanently denied on mobile, it opens the app settings.
  ///
  /// Returns a [Future] that completes with `true` if permissions are granted, `false` otherwise.
  static Future<bool> areBtPermissionsGranted() async {
    // Permissions are not required on non-mobile platforms.
    if (!isMobilePlatform) return true;

    // Get the current permission status for Bluetooth and Location.
    var status = await _permissionStatus;
    bool blePermissionGranted = status[0];
    bool locationPermissionGranted = status[1];

    // If both permissions are already granted, return true.
    if (locationPermissionGranted && blePermissionGranted) return true;

    // If Bluetooth permission is not granted, request it.
    if (!blePermissionGranted) {
      PermissionStatus blePermissionCheck = await Permission.bluetooth
          .request();
      // If the permission is permanently denied, print a message and open app settings.
      if (blePermissionCheck.isPermanentlyDenied) {
        print("Bluetooth Permission Permanently Denied");
        openAppSettings();
      }
      // Return false as permission was not granted.
      return false;
    }

    // If Location permission is not granted, request it.
    if (!locationPermissionGranted) {
      PermissionStatus locationPermissionCheck = await Permission.location
          .request();
      // If the permission is permanently denied, print a message and open app settings.
      if (locationPermissionCheck.isPermanentlyDenied) {
        print("Location Permission Permanently Denied");
        openAppSettings();
      }
      // Return false as permission was not granted.
      return false;
    }

    // If we reach here, it means one of the permissions was just requested and
    // might not be granted yet, or the user denied it.
    return false;
  }

  // /// Checks if the necessary USB permissions are granted.
  // ///
  // /// This method is currently commented out and not implemented.
  // // static Future<bool> areUsbPermissionsGranted() async {
  // //   if (!isMobilePlatform) return true;
  // //
  // //   // await Permission.
  // //
  // //   return false;
  // // }

  /// Gets the current permission status for Bluetooth and Location based on the platform and Android version.
  ///
  /// Returns a list of booleans: `[blePermissionGranted, locationPermissionGranted]`.
  static Future<List<bool>> get _permissionStatus async {
    bool blePermissionGranted = false;
    bool locationPermissionGranted = false;

    // Check if explicit Android Bluetooth permissions (SCAN, CONNECT) are required (Android SDK >= 31).
    if (await requiresExplicitAndroidBluetoothPermissions) {
      // Request Bluetooth Connect permission.
      bool bleConnectPermission =
          (await Permission.bluetoothConnect.request()).isGranted;
      // Request Bluetooth Scan permission.
      bool bleScanPermission =
          (await Permission.bluetoothScan.request()).isGranted;

      // Both scan and connect permissions must be granted.
      blePermissionGranted = bleConnectPermission && bleScanPermission;
      // Location permission is not explicitly required on Android >= 31 for BLE.
      locationPermissionGranted = true;
    } else {
      // For older Android versions or other mobile platforms, request the general Bluetooth permission.
      PermissionStatus permissionStatus = await Permission.bluetooth.request();
      blePermissionGranted = permissionStatus.isGranted;
      // Check if Location permission is required (Android < 31) and request it if needed.
      locationPermissionGranted = await requiresLocationPermission
          ? (await Permission.locationWhenInUse.request()).isGranted
          : true;
    }
    // Return the status of Bluetooth and Location permissions.
    return [blePermissionGranted, locationPermissionGranted];
  }

  /// Checks if the current platform is a mobile platform (Android or iOS) and not web.
  ///
  /// Returns `true` if the platform is Android or iOS and not web, `false` otherwise.
  static bool get isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Checks if Location permission is required.
  ///
  /// Location permission is required on Android versions older than SDK 31 for Bluetooth scanning.
  ///
  /// Returns a [Future] that completes with `true` if location permission is required, `false` otherwise.
  static Future<bool> get requiresLocationPermission async =>
      !kIsWeb &&
      Platform.isAndroid &&
      (!await requiresExplicitAndroidBluetoothPermissions);

  /// Checks if explicit Android Bluetooth permissions (SCAN, CONNECT) are required.
  ///
  /// This is typically required on Android SDK 31 (Android 12) and above.
  /// NOTE: The current implementation hardcodes `return true;`, overriding the SDK version check.
  ///
  /// Returns a [Future] that completes with `true` if explicit Bluetooth permissions are required, `false` otherwise.
  static Future<bool> get requiresExplicitAndroidBluetoothPermissions async {
    if (kIsWeb || !Platform.isAndroid) return false;
    AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt >= 31;
  }
}
