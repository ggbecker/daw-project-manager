import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart'; // NOVO IMPORT
import 'ui/dashboard_page.dart';

// O main() agora é assíncrono para usar o window_manager
void main() async {
  // 1. Inicialização do Flutter e Window Manager
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // 2. Configurações da Janela
  const initialSize = Size(1200, 700);
  WindowOptions windowOptions = WindowOptions(
    size: initialSize,
    minimumSize: initialSize,
    center: true,
    title: "DAW Project Manager",
    
    // 3. LÓGICA CONDICIONAL: 
    // Debug: TitleBarStyle.normal (Barra nativa)
    // Release: TitleBarStyle.hidden (Sem barra)
    titleBarStyle: kDebugMode ? TitleBarStyle.normal : TitleBarStyle.hidden,
  );
  
  // 4. Criação e exibição da janela
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5A6B7A), 
      brightness: Brightness.dark,
    );

    final baseTheme = ThemeData(
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A6B7A), foregroundColor: Colors.white),
      )
    );

    return MaterialApp(
      title: 'DAW Project Manager',
      themeMode: ThemeMode.dark,
      theme: baseTheme,
      darkTheme: baseTheme, 
      // Agora o DashboardPage é o widget principal, 
      // pois a CustomWindow (do bitsdojo) não é mais necessária.
      home: const DashboardPage(), 
    );
  }
}