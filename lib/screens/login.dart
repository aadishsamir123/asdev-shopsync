import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'forgot_password.dart';
import '/widgets/loading_spinner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred during login';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    Colors.black,
                    Color(0xFF1A1A1A),
                  ]
                : [
                    Colors.green.shade400,
                    Colors.green.shade800,
                    Colors.green.shade900,
                  ],
          ),
        ),
        height: MediaQuery.of(context).size.height,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: isDarkMode ? Colors.green[300] : Colors.white,
                        size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 40),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: isDarkMode
                          ? [Colors.green[300]!, Colors.green[400]!]
                          : [Colors.white, Colors.white.withValues(alpha: 0.9)],
                    ).createShader(bounds),
                    child: const Text(
                      'Welcome\nBack!',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign in to continue with ShopSync',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? Colors.green[100]
                          : Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.green[300]
                                : Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.green[300]
                                  : Colors.green[800],
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: isDarkMode
                                  ? Colors.green[300]
                                  : Colors.green[800],
                              size: 22,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.green[300]!
                                    : Colors.green.shade800,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.green[300]
                                : Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.green[300]
                                  : Colors.green[800],
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: isDarkMode
                                  ? Colors.green[300]
                                  : Colors.green[800],
                              size: 22,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: isDarkMode
                                    ? Colors.green[300]
                                    : Colors.green[800],
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.green[300]!
                                    : Colors.green.shade800,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.grey.shade50,
                          ),
                          obscureText: _obscureText,
                          textInputAction: TextInputAction.done,
                        ),
                        if (_errorMessage.isNotEmpty)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade400, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? Colors.green
                                  : Colors.green.shade800,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: _isLoading ? 0 : 3,
                            ),
                            child: _isLoading
                                ? const CustomLoadingSpinner(
                                    color: Colors.white,
                                    size: 24.0,
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: isDarkMode
                                ? Colors.green[300]
                                : Colors.green[800],
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.green[300]
                                  : Colors.green.shade800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.green[100]?.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDarkMode ? Colors.green[300] : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
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
