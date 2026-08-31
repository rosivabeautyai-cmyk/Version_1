import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/Feature/auth/provider/auth_provider.dart';
import 'package:rosivia/Feature/favorites/provider/favorites_provider.dart';
import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/Feature/settings/provider/regional_prefs_provider.dart';
import 'package:rosivia/core/providers/theme_provider.dart';
import 'package:rosivia/core/services/notification_service.dart';
import 'package:rosivia/core/styles/main_app.dart';
import 'package:rosivia/firebase_options.dart';

/// FCM background / terminated-state handler. Must be a top-level
/// function. Notification-type payloads are rendered by the OS itself;
/// this hook is only for any extra work on data payloads — kept minimal
/// on purpose (no other Firebase services touched here).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // A separate isolate: initialise Firebase before using any plugin API.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // already initialised, or offline — nothing to do
  }
}

void main() {
  // Run the whole bootstrap inside a guarded zone so a single stray
  // async error — an unhandled Future, or a browser extension that
  // monkey-patches the Firebase JS SDK on the web — is reported to the
  // console instead of taking the entire app down. This is NOT an
  // exception-hider: every error is still surfaced via
  // FlutterError.presentError; the app just keeps running.
  runZonedGuarded(_bootstrap, (error, stack) {
    FlutterError.presentError(
      FlutterErrorDetails(exception: error, stack: stack, library: 'bootstrap'),
    );
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Framework + platform (engine) errors go to the console rather than
  // terminating the app.
  FlutterError.onError = FlutterError.presentError;
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error\n$stack');
    return true;
  };

  // Initialize Firebase (Auth + Firestore only). A failure here must
  // NOT prevent runApp() — that is exactly what leaves a web build
  // stuck on the loading indicator. Instead we render a small
  // "couldn't connect / retry" screen.
  Object? firebaseInitError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, s) {
    firebaseInitError = e;
    debugPrint('Firebase.initializeApp failed: $e\n$s');
  }

  // Cloud Messaging: register the background handler + wire up
  // foreground/tap listeners. This does NOT prompt for permission —
  // that only happens when the user turns notifications on in Settings.
  if (firebaseInitError == null) {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      // Fire-and-forget; failures are logged, never fatal.
      unawaited(NotificationService.instance.initListeners());
    } catch (e) {
      debugPrint('Cloud Messaging setup failed: $e');
    }
  }

  final languageProvider = LanguageProvider();
  final themeProvider = ThemeProvider();
  try {
    await languageProvider.loadLanguage();
  } catch (e) {
    debugPrint('loadLanguage failed (using defaults): $e');
  }
  try {
    await themeProvider.loadTheme();
  } catch (e) {
    debugPrint('loadTheme failed (using defaults): $e');
  }

  if (firebaseInitError != null) {
    runApp(_StartupErrorApp(themeProvider: themeProvider));
    return;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        // App-wide so every product-price widget can show the shopper's
        // currency + an approximate conversion, and the catalog can
        // apply country-availability visibility.
        ChangeNotifierProvider<RegionalPrefsProvider>(
          create: (_) {
            final provider = RegionalPrefsProvider();
            // Fire-and-forget, but never let it become an unhandled
            // Future (its config read is best-effort with a fallback).
            provider.load().catchError(
              (Object e) => debugPrint('RegionalPrefsProvider.load failed: $e'),
            );
            return provider;
          },
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

/// Shown only when `Firebase.initializeApp` itself failed — so the app
/// still renders something actionable instead of a blank/forever-loading
/// page. Retrying re-runs the full bootstrap; on success `runApp` swaps
/// in the real app.
class _StartupErrorApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _StartupErrorApp({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    "Couldn't connect to ROSIVA.\n"
                    'Check your internet connection and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _bootstrap,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
