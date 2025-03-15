import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/welcome.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/home.dart';
import 'screens/profile.dart';
import 'screens/settings.dart';
import 'screens/maintenance_screen.dart';
import 'services/update_service.dart';
import 'services/maintenance_service.dart';
// import 'services/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ShopSync());
}

class ShopSync extends StatelessWidget {
  const ShopSync({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopSync',
      theme: ThemeData(
        // pageTransitionsTheme: const PageTransitionsTheme(
        //   builders: {
        //     TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        //   },
        // ),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green),
      ),
      darkTheme: ThemeData(
        // pageTransitionsTheme: const PageTransitionsTheme(
        //   builders: {
        //     TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        //   },
        // ),
        useMaterial3: true,
        colorScheme: ColorScheme.dark(primary: Colors.green),
      ),
      // themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
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
              child: CircularProgressIndicator(),
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
