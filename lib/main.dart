import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'pages/main_navigation.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kBrandBlue = Color(0xFF242076);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crashlytics hooks (catch anything after Flutter engine starts)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final montserrat = GoogleFonts.montserratTextTheme();

    return MaterialApp(
      title: 'Nyari',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
              borderSide: BorderSide.none),
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
                letterSpacing: 0.2),
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
                letterSpacing: 0.2),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kBrandBlue,
            side: const BorderSide(color: kBrandBlue),
            textStyle: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kBrandBlue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const BootGate(), // <- show something immediately
    );
  }
}

/// Boots Firebase after the UI is on screen, then routes accordingly.
class BootGate extends StatefulWidget {
  const BootGate({super.key});
  @override
  State<BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<BootGate> {
  String? error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FirebaseCrashlytics.instance.log('boot: Firebase initialized');

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    } catch (e, st) {
      error = 'Firebase initialize failed: $e';
      // Log non-fatal so we can see it in Crashlytics
      unawaited(FirebaseCrashlytics.instance.recordError(
        e,
        st,
        fatal: false,
        reason: 'boot: init',
      ));
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return BootErrorScreen(message: error!);
    }
    return const SplashScreen(); // spinner while we init
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF6FF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Starting Nyari…'),
          ],
        ),
      ),
    );
  }
}

class BootErrorScreen extends StatelessWidget {
  const BootErrorScreen({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF6FF),
      appBar: AppBar(title: const Text('Nyari')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text('We hit a startup problem.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => exit(0),
                child: const Text('Close app'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          FirebaseCrashlytics.instance.log('auth: waiting');
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          FirebaseCrashlytics.instance.recordError(
              snapshot.error!, snapshot.stackTrace,
              fatal: false, reason: 'auth stream');
          return const BootErrorScreen(message: 'Sign-in stream failed.');
        } else if (snapshot.hasData) {
          FirebaseCrashlytics.instance.log('auth: signed in');
          return const MainNavigation();
        } else {
          FirebaseCrashlytics.instance.log('auth: signed out');
          return AuthPage(onSignedIn: () {
            (context as Element).markNeedsBuild();
          });
        }
      },
    );
  }
}
