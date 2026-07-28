import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/core/styles/main_app.dart';
import 'package:rosivia/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final languageProvider = LanguageProvider();
  await languageProvider.loadLanguage();

  runApp(
    ChangeNotifierProvider(
      create: (_) => languageProvider,
      child: const MainApp(),
    ),
  );
}