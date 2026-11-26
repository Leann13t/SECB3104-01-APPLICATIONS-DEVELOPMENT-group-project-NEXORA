import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_colors.dart';
import 'login_page.dart';

class SplashPage extends StatelessWidget {
  final VoidCallback? onGetStarted;

  const SplashPage({super.key, this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCFF6EE), Colors.white, Color(0xFFFFF9F0)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),

                          // App Mascot / Logo
                          Center(
                            child: SizedBox(
                              width: 260,
                              height: 260,
                              child: Image.asset(
                                'assets/images/loraguide_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.explore_rounded,
                                  size: 100,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // App Title
                          Text(
                            'LoraGuide',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              color: AppColors.primary,
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              shadows: const [
                                Shadow(
                                  offset: Offset(0, 3),
                                  blurRadius: 0,
                                  color: Color(0xFFE2D5A8),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Tagline
                          Text(
                            'Discover local culture.\nCollect unique creatures.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              color: AppColors.darkBrown,
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Subtitle description
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Find hidden food spots, murals, crafts and heritage places shared by your local community.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: AppColors.secondaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                              ),
                            ),
                          ),

                          const Spacer(flex: 2),

                          // "Get Started" Button
                          GestureDetector(
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
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 320),
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFFFFAB99),
                                    Color(0xFFFF816F),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFAC5E52),
                                  width: 2.2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFFAC5E52),
                                    blurRadius: 0,
                                    offset: Offset(0, 5),
                                  ),
                                  BoxShadow(
                                    color: Color(0x3D9B6B5D),
                                    blurRadius: 10,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: GoogleFonts.fredoka(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
