import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/main_navigation.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/auth_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Brand color (Nyari blue)
const Color kBrandBlue = Color(0xFF242076);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    FirebaseCrashlytics.instance.recordError(
      details.exception,
      details.stack,
      fatal: true,
      reason: 'ErrorWidget.builder caught a build error',
    );
    return Material(
      color: const Color(0xFFFEF6FF),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
          ),
          child: Text(
            'Startup error:\n\n$message',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

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
    );
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _booting = true;
  Object? _bootError;
  StackTrace? _bootStack;

  @override
  void initState() {
    super.initState();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
      // (lang) is currently unused but kept to trigger rebuilds on language change
      home: _booting
          ? const _BootSplash()
          : (_bootError != null
              ? _BootError(error: _bootError!, stack: _bootStack)
              : const AuthWrapper()),
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

/// Minimal splash so you don’t see white while we do first-frame work.
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
                // crude retry: relaunch the app’s root
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
