import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/Feature/auth/provider/auth_provider.dart';
import 'package:rosivia/Feature/favorites/provider/favorites_provider.dart';
import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/Feature/settings/provider/regional_prefs_provider.dart';
import 'package:rosivia/core/providers/theme_provider.dart';
import 'package:rosivia/core/styles/main_app.dart';
import 'package:rosivia/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Auth + Firestore only — the AI assistant now
  // goes through the ROSIVA AI backend, so Firebase App Check / Firebase
  // AI Logic are no longer used).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final languageProvider = LanguageProvider();
  await languageProvider.loadLanguage();

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        // App-wide so every product-price widget can show the shopper's
        // currency + an approximate conversion, and the catalog can
        // apply country-availability visibility.
        ChangeNotifierProvider<RegionalPrefsProvider>(
          create: (_) => RegionalPrefsProvider()..load(),
        ),
        // AuthProvider is provided once at the root so every screen in
        // the app (auth flow and beyond) can read/watch the same
        // authentication state via `context.watch<AuthProvider>()`.
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        // FavoritesProvider depends on AuthProvider (to read the
        // signed-in uid and stream Firestore favorites), so it's
        // built from the existing AuthProvider instance via
        // ChangeNotifierProxyProvider rather than created standalone.
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider?>(
          create: (_) => null,
          update: (_, auth, previous) =>
              auth.currentUser == null ? null : FavoritesProvider(authProvider: auth),
        ),
      ],
      child: const MainApp(),
    ),
  );
}
