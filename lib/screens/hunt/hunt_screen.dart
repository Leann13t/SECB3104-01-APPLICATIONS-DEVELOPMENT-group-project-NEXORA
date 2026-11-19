import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HuntScreen extends StatelessWidget {
  const HuntScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6FCF7),
        elevation: 0,
        title: Text(
          'Cultural Hunt',
          style: GoogleFonts.fredoka(
            color: const Color(0xFF2E2420),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0ED),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF5A4D47), width: 2),
              ),
              child: Image.asset(
                'assets/icons/hunt_icon.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Cultural Hunt & Creature Collection',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E2420),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Collect unique culture creatures while exploring Sarawak!',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF5A4D47),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
