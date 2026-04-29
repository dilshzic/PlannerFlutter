import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:planner/data/repository/task_repository.dart';
import 'package:planner/data/repository/category_repository.dart';
import 'package:planner/data/repository/auth_repository.dart';
import 'package:planner/logic/gemini_parser.dart';
import 'package:planner/logic/platform_utils.dart';
import 'package:planner/ui/theme/app_theme.dart';
import 'package:planner/ui/main_screen.dart';
import 'package:planner/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database Factory (Synchronous part)
  initializeDatabaseFactory();

  // Start Firebase initialization but don't let it block the app startup UI
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).catchError((e) {
    debugPrint("Firebase Initialization Error: $e");
  });

  runApp(
    MultiProvider(
      providers: [
        Provider<TaskRepository>(create: (_) => TaskRepository()),
        Provider<CategoryRepository>(create: (_) => CategoryRepository()),
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        // TODO: Replace with your actual Gemini API Key
        Provider<GeminiParser>(create: (_) => GeminiParser("YOUR_API_KEY_HERE")),
      ],
      child: const PlannerApp(),
    ),
  );
}

class PlannerApp extends StatelessWidget {
  const PlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Planner',
          theme: AppTheme.theme(lightDynamic, Brightness.light),
          darkTheme: AppTheme.theme(darkDynamic, Brightness.dark),
          themeMode: ThemeMode.system,
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
