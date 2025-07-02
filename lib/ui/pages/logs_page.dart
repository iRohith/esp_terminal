import 'package:esp_terminal/services/log_service.dart';
import 'package:esp_terminal/ui/pages/page_wrapper.dart';
import 'package:esp_terminal/ui/panels/log_panel.dart';
import 'package:flutter/material.dart';

/// A page dedicated to displaying various application logs.
///
/// Presents system, sent, and received data logs using [LogPanel] widgets.
class LogsPage extends StatelessWidget {
  /// Constructs a [LogsPage].
  const LogsPage({super.key});

  @override
  /// Builds the widget tree for the logs page.
  ///
  /// Displays three [LogPanel] instances for different log types.
  Widget build(BuildContext context) {
    // Access the singleton instance of LogService to retrieve log data.
    final logService = LogService.to;

    return PageWrapper(
      title: "Logs", // Set the title for the logs page.
      panels: [
        // LogPanel for displaying system-level logs.
        LogPanel(title: "System Log", id: 'sys_log', log: logService.sysLog),
        // LogPanel for displaying logs of data sent from the application.
        LogPanel(title: "Send Log", id: 'send_log', log: logService.sendLog),
        // LogPanel for displaying logs of data received by the application.
        LogPanel(title: "Receive Log", id: 'recv_log', log: logService.recvLog),
      ],
    );
  }
}
