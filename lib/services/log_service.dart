import 'package:esp_terminal/services/data_service.dart';
import 'package:get/get.dart';

import '../util/constants.dart';

/// A service for managing and logging application events and data.
///
/// This service provides observable lists for different types of logs (sent,
/// received, and system) and methods for adding messages to these logs.
/// It also limits the size of each log to prevent excessive memory usage.
class LogService extends GetxService {
  static LogService get to => Get.find();

  final dataService = DataService.to;

  late final sendLog = dataService.get("sendLog", () => <String>[].obs);
  late final recvLog = dataService.get("recvLog", () => <String>[].obs);
  late final sysLog = dataService.get("sysLog", () => <String>[].obs);

  /// Constructs a [LogService].
  ///
  /// Sets up a listener to print the latest system log message to the console.
  LogService() {
    // Print the last system log message to the console whenever the sysLog changes.
    ever(sysLog, (v) => printInfo(info: v.lastOrNull ?? ""));
  }

  /// Adds a message to the send log.
  ///
  /// [msg] is the message string to be added.
  /// The log is prefixed with "> " and its size is limited by [MAX_LOG_LINES].
  void logSend(String msg) {
    sendLog.add("> $msg");

    // Remove the oldest message if the log size exceeds the maximum limit.
    if (sendLog.length > MAX_LOG_LINES) {
      sendLog.removeAt(0);
    }
  }

  /// Adds a message to the receive log.
  ///
  /// [msg] is the message string to be added.
  /// The log is prefixed with "> " and its size is limited by [MAX_LOG_LINES].
  void logRecv(String msg) {
    recvLog.add("> $msg");

    // Remove the oldest message if the log size exceeds the maximum limit.
    if (recvLog.length > MAX_LOG_LINES) {
      recvLog.removeAt(0);
    }
  }

  /// Adds a message to the system log.
  ///
  /// [msg] is the message string to be added.
  /// The log is prefixed with "> " and its size is limited by [MAX_LOG_LINES].
  void logSys(String msg) {
    sysLog.add("> $msg");

    // Remove the oldest message if the log size exceeds the maximum limit.
    if (sysLog.length > MAX_LOG_LINES) {
      sysLog.removeAt(0);
    }
  }
}
