import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n/app_localizations.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

// NOVO: Importar providers e serviços para a lógica de auto-scan
import 'providers/providers.dart';
import 'repository/project_repository.dart';
import 'services/scanner_service.dart';
import 'services/deadline_notification_service.dart';
import 'services/notification_background_service.dart';
import 'services/google_drive_sync_service.dart';
import 'models/auto_backup_interval.dart';
import 'utils/app_paths.dart';

import 'ui/dashboard_page.dart';
import 'ui/project_detail_page.dart';
import 'ui/widgets/macos_menu_bar.dart';
import 'providers/theme_provider.dart';
import 'utils/route_observer.dart';

// Global navigator key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Auto-backup state (top-level so it persists for the app lifetime)
bool _autoBackupRunning = false;

void _startAutoBackupTimer(
  ProviderContainer container,
  GoogleDriveSyncService syncService,
) {
  Timer.periodic(const Duration(minutes: 5), (_) async {
    if (_autoBackupRunning) return;
    _autoBackupRunning = true;
    try {
      // Read saved settings from app_settings box
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('app_settings');
      final interval = AutoBackupInterval.fromStorageKey(
        settingsBox.get('autoBackupInterval'),
      );
      final duration = interval.duration;
      if (duration == null) return; // "off"

      // On desktop, try to silently restore session if not already signed in
      if (!syncService.isSignedIn) {
        if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
          try {
            final restored = await syncService.restoreSession();
            if (!restored) return;
          } catch (_) {
            return;
          }
        } else {
          return;
        }
      }

      // Check if enough time has elapsed since the last upload
      final lastUpload = await syncService.getLastBackupUploadTimestamp();
      if (lastUpload != null &&
          DateTime.now().difference(lastUpload) < duration) {
        return; // Not due yet
      }

      // Run backup silently
      final profileRepo =
          await container.read(profileRepositoryProvider.future);
      final projectRepo = await container.read(repositoryProvider.future);
      final uploadAutoDetected = settingsBox.get('uploadAutoPreviewSongs') == 'true';
      await syncService.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        uploadAutoDetectedSongs: uploadAutoDetected,
      );
      if (kDebugMode) print('Auto-backup completed successfully');
    } catch (e) {
      if (kDebugMode) print('Auto-backup failed: $e');
    } finally {
      _autoBackupRunning = false;
    }
  });
}

class _BackIntent extends Intent {
  const _BackIntent();
}

// Handle notification tap - navigate to project details
Future<void> _handleNotificationTap(String projectId) async {
  if (kDebugMode) print('Handling notification tap for project: $projectId');
  
  final context = navigatorKey.currentContext;
  if (context == null) {
    if (kDebugMode) print('Navigator context not available');
    return;
  }

  try {
    // Navigate to project details page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailPage(projectId: projectId),
      ),
    );
  } catch (e) {
    if (kDebugMode) print('Error navigating to project details: $e');
  }
}

// NOVO: Função para executar o scan
Future<void> _runInitialScan(ProjectRepository repo, ProviderContainer container) async {
  try {
    // 1. Limpa arquivos que não existem mais
    await repo.clearMissingFiles();
    
    // 2. Cria o scanner e processa as raízes de scan
    final scanner = ScannerService();
    final ignoredPaths = repo.getIgnoredPaths().map((p) => p.path).toList(growable: false);
    final scanTime = DateTime.now();
    for (final root in repo.getRoots()) {
      await for (final entity in scanner.scanDirectory(root.path, ignoredPaths: ignoredPaths)) {
        await repo.upsertFromFileSystemEntity(entity);
      }
      // Update lastScanAt timestamp for this root
      await repo.updateRootLastScanAt(root.id, scanTime);
    }
    
    // 3. Mark initial scan as complete
    container.read(initialScanStateProvider.notifier).complete();
    
    if (kDebugMode) {
      print("Initial scan completed successfully.");
    }
  } catch (e, st) {
    // Mark as complete even on error so UI doesn't stay frozen
    container.read(initialScanStateProvider.notifier).complete();
    if (kDebugMode) {
      print("Error during initial scan: $e");
      print(st);
    }
  }
}


void main() async {
  // 1. Inicialização do Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize notification services (Android only)
  if (!kIsWeb && Platform.isAndroid) {
    try {
      final notificationService = DeadlineNotificationService();
      await notificationService.initialize();
      
      // Set callback for notification taps
      notificationService.setOnNotificationTapCallback(_handleNotificationTap);
      
      await NotificationBackgroundService.initialize();
      if (kDebugMode) print('Notification services initialized');
    } catch (e) {
      if (kDebugMode) print('Error initializing notification services: $e');
    }
  }
  
  // 3. Window Manager only for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();

    // Configurações da Janela
    const initialSize = Size(1800, 1040); // Fits comfortably on 1080p screens
    const minimumSize = Size(800, 600); // Allow resizing to a smaller minimum size
    WindowOptions windowOptions = WindowOptions(
      size: initialSize,
      minimumSize: minimumSize,
      center: true,
      title: "DAW Project Manager",
      // macOS: hidden style = fullSizeContentView + transparent title bar.
      // Traffic lights remain visible and float over the Flutter content.
      // Windows/Linux debug: normal (for easy development).
      // Windows/Linux release: hidden (custom Flutter title bar).
      titleBarStyle: (!Platform.isMacOS && kDebugMode)
          ? TitleBarStyle.normal
          : TitleBarStyle.hidden,
    );
    
    // Criação e exibição da janela
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  // NOVO: 4. Configuração do Riverpod e Auto-Scan
  final container = ProviderContainer();
  try {
    // 4a. Pré-carrega o ProfileRepository primeiro
    await container.read(profileRepositoryProvider.future);
    
    // 4b. Pré-carrega o ProjectRepository (que depende do ProfileRepository)
    final repo = await container.read(repositoryProvider.future);
    
    // 4c. Executa o Scan Inicial em segundo plano (não aguardamos o Future)
    // O await repo... em cima garante que o Hive está pronto antes do scan.
    _runInitialScan(repo, container);
    
    // 4d. Schedule deadline notifications (Android only)
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final notificationService = DeadlineNotificationService();
        final projects = repo.getAllProjects();

        if (kDebugMode) {
          print('\n🔔 Scheduling deadline notifications on app start...');
          print('📦 Total projects loaded: ${projects.length}');
        }

        await notificationService.scheduleAllDeadlineNotifications(
          projects: projects,
        );
      } catch (e) {
        if (kDebugMode) print('❌ Error scheduling notifications on startup: $e');
      }
    }

    // 4e. Start auto-backup timer (desktop: try to restore session silently)
    final autoBackupService = GoogleDriveSyncService();
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      try {
        await autoBackupService.initializeCredentialsStorage();
        await autoBackupService.restoreSession();
      } catch (_) {}
    }
    _startAutoBackupTimer(container, autoBackupService);

  } catch (e) {
    // Mark as complete even on error
    container.read(initialScanStateProvider.notifier).complete();
    if (kDebugMode) print("Failed to initialize repository or run initial scan: $e");
  }


  // 5. Roda o app com o container já configurado
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DawProjectManagerApp(),
    ),
  );
}

class DawProjectManagerApp extends ConsumerStatefulWidget {
  const DawProjectManagerApp({super.key});

  @override
  ConsumerState<DawProjectManagerApp> createState() => _DawProjectManagerAppState();
}

class _DawProjectManagerAppState extends ConsumerState<DawProjectManagerApp> with WindowListener {
  static bool get _isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  static Color _bgForTheme(AppThemeType t) =>
      t == AppThemeType.neonDark ? const Color(0xFF0A0A14) : const Color(0xFF1E1F22);

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      windowManager.addListener(this);
      // Quit-warning dialog is macOS-only; intercept close only there.
      if (!kIsWeb && Platform.isMacOS) {
        windowManager.setPreventClose(true);
      }
    }
    if (!kIsWeb && Platform.isMacOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        windowManager.setBackgroundColor(_bgForTheme(ref.read(themeTypeProvider)));
      });
    }
  }

  @override
  void dispose() {
    if (_isDesktop) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final warn = ref.read(warnBeforeQuitProvider);
    if (!warn) {
      await windowManager.destroy();
      return;
    }
    final context = navigatorKey.currentContext;
    if (context == null) {
      await windowManager.destroy();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: const Text('Quit DAW Project Manager?'),
        content: const Text('Are you sure you want to quit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    if (confirmed == true) await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final currentLocale = ref.watch(localeProvider);

    // Keep window background colour in sync with the active theme (macOS only)
    if (!kIsWeb && Platform.isMacOS) {
      ref.listen(themeTypeProvider, (_, next) {
        windowManager.setBackgroundColor(_bgForTheme(next));
      });
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'DAW Project Manager',
      theme: themeData,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('pt', ''),
        Locale('es', ''),
        Locale('fr', ''),
        Locale('it', ''),
        Locale('de', ''),
        Locale('ru', ''),
        Locale('ja', ''),
        Locale('zh', ''),
      ],
      locale: currentLocale,
      // MacOSMenuBar must build with a context that has localizations — placing
      // it in builder ensures it runs after MaterialApp installs its delegates.
      builder: (context, child) => Shortcuts(
        shortcuts: const {
          // macOS: Cmd+← (standard back in macOS apps)
          SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true): _BackIntent(),
          // Windows / Linux: Alt+← (standard back in browsers and file managers)
          SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): _BackIntent(),
        },
        child: Actions(
          actions: {
            _BackIntent: CallbackAction<_BackIntent>(
              onInvoke: (_) {
                navigatorKey.currentState?.maybePop();
                return null;
              },
            ),
          },
          child: MacOSMenuBar(child: child ?? const SizedBox()),
        ),
      ),
      navigatorObservers: [appRouteObserver],
      home: const DashboardPage(),
    );
  }
}
