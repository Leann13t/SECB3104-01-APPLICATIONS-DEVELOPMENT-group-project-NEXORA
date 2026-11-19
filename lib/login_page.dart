import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main',
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.nexora://login-callback',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email/phone and password.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        if (response.user != null) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/main',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: $e'),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'Explore Home',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _sparkle(String text, Color color, double size) {
    return Text(
      text,
      style: GoogleFonts.fredoka(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Container(
                width: 390,
                height: 844,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(0.50, 0.00),
                    end: Alignment(0.50, 1.00),
                    colors: [Colors.white, Color(0xFFE6FCF7)],
                  ),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 2,
                      color: Color(0xFF616779),
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Top Logo / Illustration
                    Positioned(
                      left: 69,
                      top: 23,
                      child: SizedBox(
                        width: 252,
                        height: 216,
                        child: Image.asset(
                          'assets/images/loraguide_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: Color(0xFF90BFCE),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Decorative sparkles (top area)
                    Positioned(left: 58, top: 60, child: _sparkle('✦', const Color(0xFFEBCB84), 25)),
                    Positioned(left: 331, top: 66, child: _sparkle('✦', const Color(0xFFE9CE96), 19)),
                    Positioned(left: 58, top: 99, child: _sparkle('✦', const Color(0xFFBDDFDF), 16)),
                    Positioned(left: 304, top: 117, child: _sparkle('✦', const Color(0xFFB9DFDE), 23)),
                    Positioned(left: 45, top: 160, child: _sparkle('✦', const Color(0xFFE4C89F), 21)),
                    Positioned(left: 354, top: 185, child: _sparkle('✦', const Color(0xFFE6C4B4), 17)),
                    Positioned(left: 20, top: 223, child: _sparkle('✦', const Color(0xFFE8D5AA), 19)),

                    // Heading: Welcome to LoraGuide
                    Positioned(
                      left: 24,
                      top: 249,
                      child: SizedBox(
                        width: 342,
                        child: Text(
                          'Welcome to LoraGuide',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF468F89),
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.27,
                          ),
                        ),
                      ),
                    ),

                    // Label: Email or phone number
                    Positioned(
                      left: 48,
                      top: 314,
                      child: SizedBox(
                        width: 294,
                        child: Text(
                          'Email or phone number',
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF493C35),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.43,
                          ),
                        ),
                      ),
                    ),

                    // Input field: Email or phone number
                    Positioned(
                      left: 48,
                      top: 340,
                      child: Container(
                        width: 294,
                        height: 48,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              width: 2,
                              color: Color(0xFF90BFCE),
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0xFFC9E6ED),
                              blurRadius: 0,
                              offset: Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF3B302A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your email or phone',
                              hintStyle: GoogleFonts.nunito(
                                color: const Color(0xFF7C7773),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Label: Password
                    Positioned(
                      left: 48,
                      top: 405,
                      child: SizedBox(
                        width: 294,
                        child: Text(
                          'Password',
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF493C35),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.43,
                          ),
                        ),
                      ),
                    ),

                    // Input field: Password
                    Positioned(
                      left: 48,
                      top: 431,
                      child: Container(
                        width: 294,
                        height: 48,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              width: 2,
                              color: Color(0xFFB49BCB),
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0xFFE1D5ED),
                              blurRadius: 0,
                              offset: Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF3B302A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: GoogleFonts.nunito(
                                color: const Color(0xFF7C7773),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: InputBorder.none,
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 18,
                                  color: const Color(0xFFB49BCB),
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Forgot password?
                    Positioned(
                      left: 48,
                      top: 495,
                      child: SizedBox(
                        width: 294,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Forgot password tapped.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot password?',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF457F82),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              height: 1.50,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Decorative sparkles (mid area)
                    Positioned(left: 315, top: 543, child: _sparkle('✦', const Color(0xFFF9E5AD), 29)),
                    Positioned(left: 62, top: 573, child: _sparkle('✦', const Color(0xFFE1FFF6), 20)),

                    // "Log In" Button
                    Positioned(
                      left: 48,
                      top: 559,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _handleLogin,
                        child: Container(
                          width: 294,
                          height: 60,
                          decoration: ShapeDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment(0.00, 0.50),
                              end: Alignment(1.00, 0.50),
                              colors: [Color(0xFF80E7DA), Color(0xFF56C9BB)],
                            ),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 2.20,
                                color: Color(0xFF40AA9F),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0xB22F958C),
                                blurRadius: 0,
                                offset: Offset(0, 5),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Color(0x21594F44),
                                blurRadius: 12,
                                offset: Offset(0, 8),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 16,
                                top: 14,
                                child: SizedBox(
                                  width: 262,
                                  child: _isLoading
                                      ? const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Log In',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.fredoka(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            height: 1.33,
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                left: 238,
                                top: 6,
                                child: _sparkle('✦', const Color(0xFFFFE9A6), 19),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // "or continue with"
                    Positioned(
                      left: 48,
                      top: 650,
                      child: SizedBox(
                        width: 294,
                        child: Text(
                          'or continue with',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF55413B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.54,
                          ),
                        ),
                      ),
                    ),

                    // Decorative sparkles (social area)
                    Positioned(left: 37, top: 644, child: _sparkle('✦', const Color(0xFFEACD96), 18)),
                    Positioned(left: 348, top: 653, child: _sparkle('✦', const Color(0xFFD8C6DF), 19)),

                    // Google Login Button (Full width, Apple removed)
                    Positioned(
                      left: 48,
                      top: 692,
                      child: GestureDetector(
                        onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
                        child: Container(
                          width: 294,
                          height: 48,
                          decoration: ShapeDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment(0.00, 0.50),
                              end: Alignment(1.00, 0.50),
                              colors: [Color(0xFFADEAF2), Color(0xFF85D5E5)],
                            ),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 1.80,
                                color: Color(0xFF78B9CB),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0xCC5AA4B9),
                                blurRadius: 0,
                                offset: Offset(0, 5),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Color(0x21594F44),
                                blurRadius: 12,
                                offset: Offset(0, 8),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isGoogleLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'G',
                                            style: GoogleFonts.fredoka(
                                              color: const Color(0xFF4285F4),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continue with Google',
                                        style: GoogleFonts.fredoka(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),

                    // Decorative sparkles (bottom area)
                    Positioned(left: 23, top: 765, child: _sparkle('✦', const Color(0xFFD8CDD9), 23)),
                    Positioned(left: 303, top: 769, child: _sparkle('✦', const Color(0xFFD5C8E0), 17)),
                    Positioned(left: 346, top: 756, child: _sparkle('✦', const Color(0xFFE6D4D8), 22)),

                    // "Don't have an account? Sign Up"
                    Positioned(
                      left: 35,
                      top: 790,
                      child: SizedBox(
                        width: 320,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Navigate to Sign Up screen.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.nunito(
                                color: const Color(0xFF456A68),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                height: 1.50,
                              ),
                              children: const [
                                TextSpan(text: "Don't have an account?  "),
                                TextSpan(
                                  text: 'Sign Up',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF2E6562),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

