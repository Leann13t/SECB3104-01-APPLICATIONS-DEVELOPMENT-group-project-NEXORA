import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home/home_screen.dart';
import 'map/map_screen.dart';
import 'hunt/hunt_screen.dart';
import 'upload/upload_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _onSelectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateTab: _onSelectTab),
      const MapScreen(),
      HuntScreen(onNavigateTab: _onSelectTab),
      UploadScreen(onSubmissionSuccess: () => _onSelectTab(4)),
      ProfileScreen(onNavigateTab: _onSelectTab),
    ];

    return Scaffold(
      extendBody: true, // Allows body content to scroll behind floating nav bar
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: _buildFloatingBottomNavBar(),
      ),
    );
  }

  // Floating pill bottom navigation bar with responsive flex distribution
  Widget _buildFloatingBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(33),
        border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E000000),
            offset: Offset(0, 6),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Color(0xFFD6CBC3),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _buildNavItem(
            index: 0,
            label: 'Home',
            iconPath: 'assets/icons/home_icon.png',
            activeHighlightColor: const Color(0xFFB5F2E8),
            activeBorderColor: const Color(0xFF40AA9F),
          ),
          _buildNavItem(
            index: 1,
            label: 'Map',
            iconPath: 'assets/icons/map_icon.png',
            activeHighlightColor: const Color(0xFFD4F6E6),
            activeBorderColor: const Color(0xFF40AA9F),
          ),
          _buildNavItem(
            index: 2,
            label: 'Hunt',
            iconPath: 'assets/icons/hunt_icon.png',
            activeHighlightColor: const Color(0xFFFFE0ED),
            activeBorderColor: const Color(0xFFD98BA8),
          ),
          _buildNavItem(
            index: 3,
            label: 'Add',
            iconPath: 'assets/icons/add_icon.png',
            activeHighlightColor: const Color(0xFFD8F2FF),
            activeBorderColor: const Color(0xFF78B9CB),
          ),
          _buildNavItem(
            index: 4,
            label: 'Profile',
            iconPath: 'assets/icons/profile_icon.png',
            activeHighlightColor: const Color(0xFFFFF0D1),
            activeBorderColor: const Color(0xFFD9B36C),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required String iconPath,
    required Color activeHighlightColor,
    required Color activeBorderColor,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onSelectTab(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? activeHighlightColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: activeBorderColor, width: 1.4)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  _getFallbackIcon(index),
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF2E2420)
                      : const Color(0xFF85756C),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.fredoka(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF2E2420)
                        : const Color(0xFF6B5E57),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFallbackIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.map_rounded;
      case 2:
        return Icons.catching_pokemon;
      case 3:
        return Icons.add_circle_outline_rounded;
      case 4:
      default:
        return Icons.person_rounded;
    }
  }
}
