import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flt_alx_core_ai/flt_alx_core_ai.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:home_widget/home_widget.dart';
import 'package:narwhal/services/widget_background_handler.dart';
import 'package:narwhal/data/repository/category_repository.dart';
import 'package:flutter_core_auth_hybrid/auth_repository.dart';
import 'package:flutter_core_firestore_bridge/firestore_service.dart';
import 'package:flutter_ui_identity/app_theme.dart';
import 'package:flutter_ui_identity/auth_wrapper.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/data/repository/scratchpad_repository.dart';
import 'package:narwhal/data/repository/time_block_repository.dart';
import 'package:narwhal/services/focus_timer_service.dart';
import 'package:narwhal/services/ai/gemini_parser.dart';
import 'package:narwhal/services/ai/project_agent_service.dart';
import 'package:narwhal/ui/auth/login_screen.dart';
import 'package:narwhal/ui/main_screen.dart';
import 'package:narwhal/services/ai/gemini_brain.dart';
import 'package:narwhal/services/notification_service.dart';
import 'package:narwhal/services/background_task_service.dart';
import 'package:narwhal/core/platform/platform_utils.dart';
import 'package:narwhal/firebase_options.dart';
import 'package:narwhal/services/sync_status_service.dart';
import 'package:firedart/firedart.dart' as fd;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env.local');
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }

  // Initialize database factory synchronously before any repository accesses the DB
  try {
    initializeDatabaseFactory();
  } catch (e) {
    debugPrint("Database Factory Initialization Error: $e");
  }

  // Initialize notifications
  try {
    await NotificationService().initialize();
    await BackgroundTaskService().initialize();
  } catch (e) {
    debugPrint("Notification Initialization Error: $e");
  }

  // Register Android Home Screen Widget background callback
  if (!kIsWeb && Platform.isAndroid) {
    try {
      HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
    } catch (e) {
      debugPrint("HomeWidget Callback Registration Error: $e");
    }
  }

  // Initialize Firebase with proper error handling
  try {
    if (!kIsWeb && Platform.isLinux) {
      // 1. Initialize Firedart Auth with a volatile store (we manage persistence manually)
      fd.FirebaseAuth.initialize(DefaultFirebaseOptions.linux.apiKey, fd.VolatileStore());
      
      // 2. Initialize Firestore - it will automatically use the FirebaseAuth instance
      fd.Firestore.initialize(DefaultFirebaseOptions.linux.projectId);
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // On Android/iOS, clear the Firestore offline cache once after the
      // database architecture migration (old 'tasks' → new 'task_nodes').
      // This ensures stale cached data from the deprecated architecture is
      // discarded so the app syncs fresh data from Firestore.
      if (!kIsWeb) {
        const _kMigrationClearedKey = 'firestore_cache_cleared_v3';
        final prefs = await SharedPreferences.getInstance();
        final alreadyCleared = prefs.getBool(_kMigrationClearedKey) ?? false;
        if (!alreadyCleared) {
          try {
            // clearPersistence() alone is safe right after initializeApp()
            // before any Firestore connections are opened. Do NOT call
            // terminate() first — it shuts down the gRPC channel permanently.
            await FirebaseFirestore.instance.clearPersistence();
            debugPrint('Firestore cache cleared for architecture migration.');
          } catch (e) {
            debugPrint('Firestore cache clear warning: $e');
          }
          await prefs.setBool(_kMigrationClearedKey, true);
        }
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }
    }
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  try {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthRepository(
              apiKey: DefaultFirebaseOptions.linux.apiKey,
              clientId: dotenv.env['GOOGLE_CLIENT_ID'] ?? (kIsWeb 
                ? "737058239197-tek2hvue0nlmk482inoa16pjd4cinbr3.apps.googleusercontent.com"
                : "737058239197-ijuc8ose2sqtqfuf0sckljqvn0s764cb.apps.googleusercontent.com"),
              clientSecret: dotenv.env['GOOGLE_CLIENT_SECRET'],
            ),
          ),
          ChangeNotifierProxyProvider<AuthRepository, TaskNodeRepository>(
            create: (context) => TaskNodeRepository(
              FirestoreService(context.read<AuthRepository>()),
              context.read<AuthRepository>(),
            ),
            update: (_, auth, previous) => previous ?? TaskNodeRepository(FirestoreService(auth), auth),
          ),
          Provider<CategoryRepository>(create: (_) => CategoryRepository()),
          ChangeNotifierProxyProvider<AuthRepository, ScratchpadRepository>(
            create: (context) => ScratchpadRepository(
              FirestoreService(context.read<AuthRepository>()),
              context.read<AuthRepository>(),
            ),
            update: (_, auth, previous) => previous ?? ScratchpadRepository(FirestoreService(auth), auth),
          ),
          ChangeNotifierProxyProvider<AuthRepository, TimeBlockRepository>(
            create: (context) => TimeBlockRepository(
              FirestoreService(context.read<AuthRepository>()),
              context.read<AuthRepository>(),
            ),
            update: (_, auth, previous) => previous ?? TimeBlockRepository(FirestoreService(auth), auth),
          ),
          ChangeNotifierProxyProvider2<TimeBlockRepository, TaskNodeRepository, FocusTimerService>(
            create: (context) => FocusTimerService(
              context.read<TimeBlockRepository>(),
              context.read<TaskNodeRepository>(),
            ),
            update: (_, tbRepo, taskRepo, previous) {
              if (previous != null) {
                previous.updateRepositories(tbRepo, taskRepo);
                return previous;
              }
              return FocusTimerService(tbRepo, taskRepo);
            },
          ),
          Provider<AiBrainManager>(
            create: (_) {
              final apiKey = (dotenv.env['GEMINI_API_KEY']?.isNotEmpty ?? false)
                  ? dotenv.env['GEMINI_API_KEY']!
                  : const String.fromEnvironment('GEMINI_API_KEY');
              final manager = AiBrainManager(
                defaultConfig: StoredBrainConfig(
                  provider: BrainProvider.gemini,
                  model: 'gemini-3.1-flash-lite',
                  apiKey: apiKey,
                  streaming: false,
                  systemInstruction: 'You are Narwhal, a premium smart planner assistant. Keep answers concise and practical. You can execute actions on the user\'s planner. When the user asks you to add a task or mark/complete a task as done, you MUST append the appropriate action command at the very end of your response text (outside normal conversation).\n\nCommands:\n- To add a task: [ADD_TASK: Title of the task]\n- To complete/mark a task as done: [COMPLETE_TASK: Title of the task or task ID]',
                ),
              );
              manager.registerBrain(BrainProvider.gemini, const GeminiBrain());
              return manager;
            },
          ),
          Provider<GeminiParser>(create: (_) {
            final apiKey = (dotenv.env['GEMINI_API_KEY']?.isNotEmpty ?? false)
                ? dotenv.env['GEMINI_API_KEY']!
                : const String.fromEnvironment('GEMINI_API_KEY');
            return GeminiParser(apiKey);
          }),
          ProxyProvider<AiBrainManager, ProjectAgentService>(
            update: (_, brainManager, __) => ProjectAgentService(brainManager),
          ),
          ChangeNotifierProvider(create: (_) => SyncStatusService()),
        ],
        child: const NarwhalApp(),
      ),
    );
  } catch (e) {
    debugPrint("CRITICAL STARTUP ERROR: $e");
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("App initialization failed. Please refresh.\n$e"),
        ),
      ),
    ));
  }
}

class NarwhalApp extends StatelessWidget {
  const NarwhalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Narwhal : The Smart Planner',
          theme: AppTheme.theme(lightDynamic, Brightness.light),
          darkTheme: AppTheme.theme(darkDynamic, Brightness.dark),
          themeMode: ThemeMode.system,
          home: const AuthWrapper(
            authenticatedChild: MainScreen(),
            unauthenticatedChild: LoginScreen(),
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
