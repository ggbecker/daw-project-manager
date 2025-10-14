import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

// NOVO: Importar providers para acessar o repositoryProvider
import 'providers/providers.dart'; 
import 'ui/dashboard_page.dart';

// O main() agora é assíncrono
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
  
  // 5. NOVO: Pré-carregamento do Repositório Hive
  final container = ProviderContainer();
  try {
    // Força o Riverpod a esperar a conclusão do ProjectRepository.init()
    await container.read(repositoryProvider.future);
  } catch (e, stack) {
    // Trata ou loga qualquer erro de inicialização do Hive
    debugPrint('Erro ao inicializar o repositório: $e\n$stack');
    // Nota: A aplicação continuará, mas pode não ter dados se o Hive falhar
  }

  // 6. NOVO: Passa o container pré-carregado para a aplicação
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5A6B7A), // blue-grey accent similar to Cursor
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
      darkTheme: baseTheme, // Usando o mesmo tema base para darkTheme
      home: const DashboardPage(),
    );
  }
}