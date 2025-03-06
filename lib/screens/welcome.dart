import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';

class WelcomeScreen extends StatelessWidget {
  WelcomeScreen({super.key});

  // ValueNotifier to track loading state
  final ValueNotifier<bool> _isGoogleSigningIn = ValueNotifier<bool>(false);

  // Future<void> _signInWithGoogle(BuildContext context) async {
  //   _isGoogleSigningIn.value = true;
  //
  //   try {
  //     // Begin interactive sign in process
  //     final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
  //
  //     // If user cancels the sign-in flow
  //     if (gUser == null) {
  //       _isGoogleSigningIn.value = false;
  //       return;
  //     }
  //
  //     // Obtain auth details from the request
  //     final GoogleSignInAuthentication gAuth = await gUser.authentication;
  //
  //     // Create a new credential for the user
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: gAuth.accessToken,
  //       idToken: gAuth.idToken,
  //     );
  //
  //     // Sign in with Firebase
  //     await FirebaseAuth.instance.signInWithCredential(credential);
  //
  //     if (context.mounted) {
  //       Navigator.pushReplacementNamed(context, '/home');
  //     }
  //   } catch (e) {
  //     _isGoogleSigningIn.value = false;
  //
  //     if (context.mounted) {
  //       debugPrint('Error signing in with Google: ${e.toString()}');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error signing in with Google: ${e.toString()}'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  Future<String> _getVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return 'Version ${packageInfo.version} (${packageInfo.buildNumber})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),

                // App Title with highlight
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'ShopSync',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..color = Colors.white.withOpacity(0.3),
                      ),
                    ),
                    const Text(
                      'ShopSync',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // App Tagline
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Share shopping lists with family and friends',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Login Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.green[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login),
                      SizedBox(width: 8),
                      Text(
                        'Log In',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Sign Up Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.green[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add),
                      SizedBox(width: 8),
                      Text(
                        'Sign Up',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Google Sign-in Button with loading indicator
                // ValueListenableBuilder<bool>(
                //   valueListenable: _isGoogleSigningIn,
                //   builder: (context, isLoading, _) {
                //     return Material(
                //       color: Colors.transparent,
                //       child: InkWell(
                //         onTap: isLoading ? null : () => _signInWithGoogle(context),
                //         borderRadius: BorderRadius.circular(8),
                //         splashColor: Colors.grey.withOpacity(0.3),
                //         highlightColor: Colors.grey.withOpacity(0.1),
                //         child: Ink(
                //           child: Padding(
                //             padding: const EdgeInsets.symmetric(vertical: 8.0),
                //             child: isLoading
                //                 ? SizedBox(
                //               height: 48,
                //               child: Center(
                //                 child: CircularProgressIndicator(
                //                   color: Colors.white,
                //                   strokeWidth: 3,
                //                 ),
                //               ),
                //             )
                //                 : Image.asset(
                //               './assets/logos/continue_google.png',
                //               height: 48,
                //               fit: BoxFit.contain,
                //             ),
                //           ),
                //         ),
                //       ),
                //     );
                //   },
                // ),

                SizedBox(height: 40),

                // Version info at bottom
                FutureBuilder<String>(
                  future: _getVersionInfo(),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Loading version information...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
