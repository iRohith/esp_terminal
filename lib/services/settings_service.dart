import 'package:esp_terminal/services/data_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A service for managing common application settings data.
class SettingsService extends GetxService {
  static SettingsService get to => Get.find();

  final dataService = DataService.to;

  late final isDarkMode = dataService.get("isDarkMode", () => true.obs);
  late final connectionType = dataService.get(
    "connectionType",
    () => RxnString("None"),
  );

  void reset() {
    isDarkMode.value = true;
    connectionType.value = "None";
  }

  @override
  void onInit() {
    super.onInit();

    ever(isDarkMode, (_) {
      Get.changeThemeMode(
        SettingsService.to.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      );
    });
  }
}
