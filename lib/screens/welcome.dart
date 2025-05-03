import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '/services/auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Future<String> _getVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return 'Version ${packageInfo.version} (${packageInfo.buildNumber})';
  }

  Widget _getGoogleButtonImage(bool isDarkMode) {
    if (Theme.of(context).platform == TargetPlatform.android) {
      return Image.asset(
        isDarkMode
            ? 'assets/badges/google/android/png@4x/dark/android_dark_rd_na@4x.png'
            : 'assets/badges/google/android/png@4x/light/android_light_rd_na@4x.png',
        height: 48,
        fit: BoxFit.contain,
      );
    } else {
      return Image.asset(
        isDarkMode
            ? 'assets/badges/google/web/png@4x/dark/web_dark_rd_na@4x.png'
            : 'assets/badges/google/web/png@4x/light/web_light_rd_na@4x.png',
        height: 48,
        fit: BoxFit.contain,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: isDarkMode
                ? [
                    Colors.black,
                    Color(0xFF1A1A1A),
                  ]
                : [
                    const Color(0xFF4CAF50),
                    const Color(0xFF2E7D32),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Logo and App Name Section
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: isDarkMode ? Colors.green[300] : Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // App Title with Animation
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isDarkMode
                        ? [Colors.green[300]!, Colors.green[400]!]
                        : [Colors.white, Colors.white70],
                  ).createShader(bounds),
                  child: Text(
                    'ShopSync',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.green[300] : Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tagline
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Align(
                    child: Text(
                      'Share shopping lists with family and friends.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.green[100] : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Login Button
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor:
                        isDarkMode ? Colors.white : Colors.green[800],
                    backgroundColor: isDarkMode ? Colors.green : Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.rightToBracket, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Sign Up Button
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDarkMode ? Colors.green[300] : Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                    side: BorderSide(
                      color: isDarkMode ? Colors.green[300]! : Colors.white,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.userPlus, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // const SizedBox(height: 20),

                // Google Sign In Button
                // InkWell(
                //   onTap: () async {
                //     try {
                //       final credential = await AuthService.signInWithGoogle();
                //       if (credential != null && mounted) {
                //         Navigator.pushReplacementNamed(context, '/home');
                //       }
                //     } catch (e) {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(
                //           content: Text('Failed to sign in with Google'),
                //           backgroundColor: Colors.red,
                //         ),
                //       );
                //     }
                //   },
                //   child: Container(
                //     height: 48, // Standard height for Google Sign In button
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(4),
                //     ),
                //     child: _getGoogleButtonImage(isDarkMode),
                //   ),
                // ),

                const Spacer(flex: 1),

                // Version info
                FutureBuilder<String>(
                  future: _getVersionInfo(),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Loading version information...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? Colors.green[100]?.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
