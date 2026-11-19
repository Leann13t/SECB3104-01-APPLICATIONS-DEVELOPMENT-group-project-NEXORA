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
      const HuntScreen(),
      const UploadScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true, // Allows the body content to scroll behind the floating nav bar
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildFloatingBottomNavBar(),
    );
  }

  // Fixed floating-style bottom navigation bar with 5 items (Section 2.G)
  Widget _buildFloatingBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: const Color(0xFF5A4D47), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E000000),
            offset: Offset(0, 8),
            blurRadius: 18,
          ),
          BoxShadow(
            color: Color(0xFFD6CBC3),
            offset: Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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

    return GestureDetector(
      onTap: () => _onSelectTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeHighlightColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: activeBorderColor, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: isSelected ? 26 : 24,
              height: isSelected ? 26 : 24,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                _getFallbackIcon(index),
                size: 22,
                color: isSelected ? const Color(0xFF2E2420) : const Color(0xFF85756C),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2E2420) : const Color(0xFF6B5E57),
              ),
            ),
          ],
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
