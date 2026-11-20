import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

class SplashPage extends StatelessWidget {
  final VoidCallback? onGetStarted;

  const SplashPage({
    super.key,
    this.onGetStarted,
  });

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
                    colors: [
                      Color(0xFFCFF6EE),
                      Colors.white,
                      Color(0xFFFDFFFE),
                    ],
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
                    // Top illustration image / logo
                    Positioned(
                      left: 0,
                      top: 56,
                      child: SizedBox(
                        width: 388,
                        height: 332,
                        child: Image.asset(
                          'assets/images/loraguide_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 64,
                                color: Color(0xFF90BFCE),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // App Title
                    Positioned(
                      left: 28,
                      top: 388,
                      child: SizedBox(
                        width: 334,
                        child: Text(
                          'LoraGuide',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF4A9188),
                            fontSize: 46,
                            fontWeight: FontWeight.w700,
                            height: 1.20,
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 3),
                                blurRadius: 0,
                                color: Color(0xFFE2D5A8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tagline
                    Positioned(
                      left: 30,
                      top: 460,
                      child: SizedBox(
                        width: 330,
                        child: Text(
                          'Discover local culture.\nCollect unique creatures.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF3B302A),
                            fontSize: 23,
                            fontWeight: FontWeight.w500,
                            height: 1.39,
                          ),
                        ),
                      ),
                    ),

                    // Subtitle / Description
                    Positioned(
                      left: 48,
                      top: 552,
                      child: SizedBox(
                        width: 294,
                        child: Text(
                          'Find hidden food spots, murals, crafts and heritage places shared by your community.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            color: const Color(0xFF51443F),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.53,
                          ),
                        ),
                      ),
                    ),

                    // "Get Started" Button
                    Positioned(
                      left: 46,
                      top: 710,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (onGetStarted != null) {
                            onGetStarted!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          }
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            width: 298,
                            height: 60,
                            decoration: ShapeDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment(0.00, 0.50),
                                end: Alignment(1.00, 0.50),
                                colors: [Color(0xFFFFAB99), Color(0xFFFF816F)],
                              ),
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  width: 2.20,
                                  color: Color(0xFFAC5E52),
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0xE5B15C4C),
                                  blurRadius: 0,
                                  offset: Offset(0, 6),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Color(0x3D9B6B5D),
                                  blurRadius: 9,
                                  offset: Offset(0, 10),
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
                                    width: 266,
                                    child: Text(
                                      'Get Started',
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
