import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/core/styles/main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final languageProvider = LanguageProvider();

  await languageProvider.loadLanguage();

  runApp(
    ChangeNotifierProvider(
      create: (_) => languageProvider,
      child: const MainApp(),
    ),
  );
}