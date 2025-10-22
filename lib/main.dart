<<<<<<< HEAD
import 'dart:async';
=======
// lib/main.dart
import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' show PlatformDispatcher;

>>>>>>> 2c1e312 (local: icon + plist + main + pubspec changes)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
<<<<<<< HEAD
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Brand color (Nyari blue)
=======

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'firebase_options.dart';
import 'language_provider.dart';
import 'pages/main_navigation.dart';
import 'pages/auth_page.dart';

// --- Brand color (Nyari blue) ---
>>>>>>> 2c1e312 (local: icon + plist + main + pubspec changes)
const Color kBrandBlue = Color(0xFF242076);

/// Initialize Firebase once, tolerating the duplicate-app hot-restart case.
Future<void> _initFirebaseOnce() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      Firebase.app(); // attach to existing
    } else {
      rethrow;
    }
  }
}

Future<void> main() async {
  // Make sure bindings are ready even if we throw super early.
  WidgetsFlutterBinding.ensureInitialized();

<<<<<<< HEAD
  // Initialize Firebase before runApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics wiring
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  // Flutter framework errors -> Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Platform dispatcher uncaught errors -> Crashlytics
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Friendly error widget + report
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final message = details.exceptionAsString();
=======
  // Initialize Firebase ASAP (before runApp).
  await _initFirebaseOnce();

  // Enable Crashlytics collection (so it can receive errors right away).
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  // Route Flutter framework errors to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Route platform (zone) errors to Crashlytics too.
  PlatformDispatcher.instance.onError = (error, stack) {
>>>>>>> 2c1e312 (local: icon + plist + main + pubspec changes)
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
      reason: 'PlatformDispatcher.onError',
    );
    return true;
  };

<<<<<<< HEAD
  // Run the app inside a zone to capture any sync top-level errors
  runZonedGuarded(() {
    runApp(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider('en'),
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });

  // Non-fatal watchdog if UI seems stuck (optional)
  Future.delayed(const Duration(seconds: 10), () {
    FirebaseCrashlytics.instance.recordError(
      Exception('watchdog: no visible UI ~10s after runApp'),
      StackTrace.current,
      fatal: false,
      reason: 'Startup took unusually long',
=======
  // A couple of breadcrumbs around startup.
  dev.log('main(): Firebase initialized', name: 'startup');
  FirebaseCrashlytics.instance.log('startup: main() after Firebase.init');

  // Watchdog to catch “stuck white screen” after ~10s with no first UI.
  Future.delayed(const Duration(seconds: 10), () {
    FirebaseCrashlytics.instance.recordError(
      Exception('watchdog: ~10s after boot and still no visible UI'),
      StackTrace.current,
      fatal: false,
      reason: 'startup-watchdog',
>>>>>>> 2c1e312 (local: icon + plist + main + pubspec changes)
    );
  });

  // Run the app in a Guarded Zone to catch any async errors at root.
  runZonedGuarded(() {
    runApp(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider('en'),
        child: const MyApp(),
      ),
    );
  }, (error, stack) async {
    await FirebaseCrashlytics.instance
        .recordError(error, stack, fatal: true, reason: 'runZonedGuarded');
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    // Do any one-time boot tasks after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Place one-time boot tasks here if needed.
      } catch (e, st) {
        _bootError = e;
        _bootStack = st;
        FirebaseCrashlytics.instance.recordError(e, st, fatal: true);
      } finally {
        if (mounted) setState(() => _booting = false);
      }
    });
=======
    _initFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Extra breadcrumbs to help trace boot sequence.
    FirebaseCrashlytics.instance.log('bootstrap: start');
    FirebaseCrashlytics.instance.setCustomKey('channel', 'testflight');

    // Send a non-fatal ping so we know we got this far.
    FirebaseCrashlytics.instance.recordError(
      Exception('diag: bootstrap ping'),
      StackTrace.current,
      fatal: false,
      reason: 'bootstrap-ping',
    );
>>>>>>> 2c1e312 (local: icon + plist + main + pubspec changes)
  }

  @override
  Widget build(BuildContext context) {
    // watch language to rebuild MaterialApp when changed
    final lang = context.watch<LanguageProvider>().language;

    final montserrat = GoogleFonts.montserratTextTheme();

    final theme = ThemeData(
      fontFamily: GoogleFonts.montserrat().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kBrandBlue,
        primary: kBrandBlue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: false,
      ),
      scaffoldBackgroundColor: const Color(0xFFFEF6FF),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: montserrat,
      primaryTextTheme: montserrat,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kBrandBlue,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kBrandBlue,
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kBrandBlue,
          side: const BorderSide(color: kBrandBlue),
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: Colors.white,
        selectedColor: kBrandBlue.withOpacity(.08),
        secondarySelectedColor: kBrandBlue.withOpacity(.12),
        side: const BorderSide(color: Colors.transparent),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: kBrandBlue,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );

    return MaterialApp(
      title: 'Nyari',
      debugShowCheckedModeBanner: false,
      theme: theme,
<<<<<<< HEAD
      // (lang) is currently unused but kept to trigger rebuilds on language change
      home: _booting
          ? const _BootSplash()
          : (_bootError != null
              ? _BootError(error: _bootError!, stack: _bootStack)
              : const AuthWrapper()),
=======
      home: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _BootSplash();
          } else if (snapshot.hasError) {
            return _BootError(
                error: snapshot.error!, stack: snapshot.stackTrace);
          } else {
            return const AuthWrapper();
          }
        },
      ),
>>>>>>> 2c1e312 (local: icon + plist + main + pubspec changes)
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseCrashlytics.instance.log('auth: building stream');
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          FirebaseCrashlytics.instance.log('auth: waiting');
          return const _BootSplash();
        } else if (snapshot.hasData) {
          FirebaseCrashlytics.instance.log('auth: signed in -> MainNavigation');
          return const MainNavigation();
        } else {
          FirebaseCrashlytics.instance.log('auth: signed out -> AuthPage');
          return AuthPage(
            onSignedIn: () {
              FirebaseCrashlytics.instance.log('auth: onSignedIn callback');
              (context as Element).markNeedsBuild();
            },
          );
        }
      },
    );
  }
}

/// Minimal in-app splash so we never show a white screen.
class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBrandBlue,
      body: Center(
        child: SizedBox(
          height: 64,
          width: 64,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Friendly error screen in case boot throws.
class _BootError extends StatelessWidget {
  final Object error;
  final StackTrace? stack;
  const _BootError({required this.error, this.stack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nyari')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Something went wrong starting the app.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text('$error', style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  stack?.toString() ?? '(no stack)',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (r) => false,
                );
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
