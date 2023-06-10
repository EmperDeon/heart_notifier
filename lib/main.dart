import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:heart_notifier/utils.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/main.dart';
import 'screens/manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Command.globalExceptionHandler = (name, error) {
    print("Error in $name: $error");
  };

  initLicenses();
  DevicesManager.registerManagers();

  GetIt.I.registerSingleton(NavigationService());

  if (Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    await [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request();
  }

  FlutterLocalNotificationsPlugin notifs = FlutterLocalNotificationsPlugin();
  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings nAndr = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings nIos = DarwinInitializationSettings();
  const LinuxInitializationSettings nLin = LinuxInitializationSettings(defaultActionName: 'default');
  const InitializationSettings nInit = InitializationSettings(android: nAndr, iOS: nIos, linux: nLin);
  notifs.initialize(nInit).then((_) {
    notifs.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestPermission();
  });

  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF233976);
    const surface = Color(0xFF1D2F62);
    const primary = Color(0xFF4B5F9B);
    const fontColor = Colors.white;
    const fontWeight = 400.0;

    return MaterialApp(
      navigatorKey: GetIt.I.get<NavigationService>().navigatorKey,
      title: 'Heart Monitoring',
      theme: ThemeData(
        dialogBackgroundColor: background,
        cardColor: background,
        scaffoldBackgroundColor: background,
        canvasColor: surface,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: surface, selectedItemColor: fontColor, unselectedItemColor: fontColor),
        bottomSheetTheme: const BottomSheetThemeData(backgroundColor: surface),
        highlightColor: surface,
        indicatorColor: primary,
        fontFamily: 'Raleway',
        textTheme: TextTheme(
          displayLarge: fontStyle(Colors.white70, fontWeight),
          displayMedium: fontStyle(Colors.white70, fontWeight),
          displaySmall: fontStyle(Colors.white70, fontWeight),
          headlineLarge: fontStyle(Colors.white70, fontWeight),
          headlineMedium: fontStyle(Colors.white70, fontWeight),
          headlineSmall: fontStyle(fontColor, fontWeight),
          titleLarge: fontStyle(fontColor, fontWeight),
          titleMedium: fontStyle(fontColor, fontWeight),
          titleSmall: fontStyle(fontColor, fontWeight),
          bodyLarge: fontStyle(fontColor, fontWeight),
          bodyMedium: fontStyle(fontColor, fontWeight),
          bodySmall: fontStyle(Colors.white70, fontWeight),
          labelLarge: fontStyle(fontColor, fontWeight),
          labelMedium: fontStyle(fontColor, fontWeight),
          labelSmall: fontStyle(Colors.white54, fontWeight),
        ),
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: primary,
          secondary: primary,
          background: background,
          surface: surface,
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.white,
          onSurface: Colors.white,
          onError: Colors.white,
          scrim: Colors.white24,
        ),
      ),
      home: Devices(),
      debugShowCheckedModeBanner: false,
    );
  }

  fontStyle(Color color, double weight) {
    return TextStyle(
      fontFamily: 'Raleway',
      color: color,
      decoration: TextDecoration.none,
      fontVariations: [FontVariation('wght', weight)],
    );
  }
}
