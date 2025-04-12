import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/welcome.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'screens/maintenance_screen.dart';
import 'screens/onboarding.dart';
import 'widgets/loading_spinner.dart';
import 'services/update_service.dart';
import 'services/maintenance_service.dart';
import 'services/shared_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: ThemeData.estimateBrightnessForColor(
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                        Brightness.dark
                    ? Colors.grey[900]!
                    : Colors.white,
              ) ==
              Brightness.dark
          ? Colors.grey[900]
          : Colors.white,
      systemNavigationBarIconBrightness:
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark
              ? Brightness.light
              : Brightness.dark,
      statusBarIconBrightness:
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark
              ? Brightness.light
              : Brightness.dark,
    ),
  );

  runApp(ShopSync());
}

class CustomPageTransitionsBuilder extends PageTransitionsBuilder {
  const CustomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    // Custom curve for a more dynamic feel
    const curve = Curves.easeInOutQuad;

    // First, define the size transition effect (scale)
    var scaleTween = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: curve),
    );

    // Define the slide transition effect
    var slideTween =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: animation, curve: curve),
    );

    // Define the fade transition effect
    var fadeTween = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: curve),
    );

    // Combining the animations together to give the "morphing" effect
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..scale(scaleTween.value)
            ..translate(
                slideTween.value.dx * MediaQuery.of(context).size.width, 0),
          child: FadeTransition(
            opacity: fadeTween,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class ShopSync extends StatelessWidget {
  const ShopSync({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopSync',
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CustomPageTransitionsBuilder(),
            TargetPlatform.windows: CustomPageTransitionsBuilder(),
            TargetPlatform.fuchsia: CustomPageTransitionsBuilder(),
          },
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green),
      ),
      darkTheme: ThemeData.dark().copyWith(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CustomPageTransitionsBuilder(),
            TargetPlatform.windows: CustomPageTransitionsBuilder(),
            TargetPlatform.fuchsia: CustomPageTransitionsBuilder(),
          },
        ),
      ),
      // themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        // '/settings': (context) => const SettingsScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check for updates after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await SharedPrefs.isFirstLaunch() && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
        return;
      }
      UpdateService.checkForUpdate(context);
      await _checkMaintenance();
    });
  }

  Future<void> _checkMaintenance() async {
    final maintenance = await MaintenanceService.checkMaintenance();

    if (maintenance != null && mounted) {
      if (maintenance['isUnderMaintenance']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MaintenanceScreen(
              message: maintenance['message'],
              startTime: maintenance['startTime'],
              endTime: maintenance['endTime'],
              isPredictive: false,
            ),
          ),
        );
      } else if (maintenance['isPredictive']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => MaintenanceScreen(
            message: maintenance['message'],
            startTime: maintenance['startTime'],
            endTime: maintenance['endTime'],
            isPredictive: true,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If Firebase is still initializing, show loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CustomLoadingSpinner(
                color: Colors.green,
                size: 60.0,
              ),
            ),
          );
        }

        // Check if user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in, direct to home screen
          return const HomeScreen();
        }

        // User is not signed in, direct to welcome screen
        return WelcomeScreen();
      },
    );
  }
}
