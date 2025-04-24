import 'package:flutter/material.dart';
import 'package:Magister/screens/theme_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeProvider().initialize();
  runApp(AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider().themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Attendance Register',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
          ),
          themeMode: themeMode,
          home: HomeScreen(),
        );
      },
    );
  }
}
