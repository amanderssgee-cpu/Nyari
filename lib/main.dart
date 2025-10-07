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

// ⬇️ NEW: Crashlytics
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// --- Brand color (Nyari blue) ---
const Color kBrandBlue = Color(0xFF242076);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before any Firebase API is used.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ⬇️ NEW: send Flutter framework errors to Crashlytics (works in release)
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // If you prefer to also capture any other uncaught (zone) errors, use this:
  // runZonedGuarded(() {
  //   runApp(ChangeNotifierProvider(
  //     create: (_) => LanguageProvider('en'), // default
  //     child: const MyApp(),
  //   ));
  // }, (error, stack) {
  //   FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //   // You can also print to console if desired
  // });

  // Normal run (Crashlytics still captures Flutter framework errors)
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider('en'), // default
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ⟵ CRITICAL: watch language so MaterialApp rebuilds app-wide
    final lang = context.watch<LanguageProvider>().language;

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
      ),
      // Watching `lang` above ensures a rebuild on language change.
      home: const AuthWrapper(),
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return const MainNavigation();
        } else {
          return AuthPage(
            onSignedIn: () {
              (context as Element).markNeedsBuild();
            },
          );
        }
      },
    );
  }
}
