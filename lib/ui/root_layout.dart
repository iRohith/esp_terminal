import 'package:esp_terminal/ui/pages/charts_page.dart';
import 'package:esp_terminal/ui/pages/connection_page.dart';
import 'package:esp_terminal/ui/pages/home_page.dart';
import 'package:esp_terminal/ui/pages/keypad_page.dart';
import 'package:esp_terminal/ui/pages/logs_page.dart';
import 'package:esp_terminal/ui/pages/send_file_page.dart';
import 'package:esp_terminal/ui/pages/settings_page.dart';
import 'package:esp_terminal/ui/pages/variables_page.dart';
import 'package:esp_terminal/util/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RootLayout extends StatelessWidget {
  const RootLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "ESP Terminal",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      defaultTransition: Transition.cupertino,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.home,

      getPages: [
        GetPage(name: Routes.home, page: () => const HomePage(), title: "Home"),

        GetPage(
          name: Routes.connection,
          page: () => const ConnectionPage(),
          title: "Connection",
        ),

        GetPage(
          name: Routes.variables,
          page: () => const VariablesPage(),
          title: "Variables",
        ),

        GetPage(
          name: Routes.keypad,
          page: () => const KeypadPage(),
          title: "Keypad",
        ),

        GetPage(name: Routes.charts, page: () => ChartsPage(), title: "Charts"),

        GetPage(name: Routes.logs, page: () => LogsPage(), title: "Logs"),

        GetPage(
          name: Routes.settings,
          page: () => SettingsPage(),
          title: "Settings",
        ),

        GetPage(
          name: Routes.sendFile,
          page: () => SendFilePage(),
          title: "Send file",
        ),
      ],
    );
  }
}
