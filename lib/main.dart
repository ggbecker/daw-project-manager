import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/dashboard_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5A6B7A), // blue-grey accent similar to Cursor
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'DAW Project Manager',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF1E1F22),
        canvasColor: const Color(0xFF1E1F22),
        cardColor: const Color(0xFF2B2D31),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2B2D31),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        dividerColor: const Color(0xFF3C3F43),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
      ),
      home: const DashboardPage(),
    );
  }
}

