import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/Feature/auth/provider/auth_provider.dart';
import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/core/styles/main_app.dart';
import 'package:rosivia/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final languageProvider = LanguageProvider();
  await languageProvider.loadLanguage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        // AuthProvider is provided once at the root so every screen in
        // the app (auth flow and beyond) can read/watch the same
        // authentication state via `context.watch<AuthProvider>()`.
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ],
      child: const MainApp(),
    ),
  );
}
