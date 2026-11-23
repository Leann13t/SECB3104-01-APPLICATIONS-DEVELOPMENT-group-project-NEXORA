import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/discovery_model.dart';
import '../../core/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const ProfileScreen({super.key, this.onNavigateTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isGirlAvatar = true;

  // User cultural place contributions (clearly marked placeholder data for demo)
  final List<Map<String, dynamic>> _mySubmissions = [
    {
      'title': 'Colosseum Ancient Arch',
      'category': CulturalCategory.heritage,
      'location': 'Piazza del Colosseo, Rome',
      'status': 'Approved',
      'xp': '+50 XP',
      'date': 'Yesterday',
    },
    {
      'title': 'Ah Huat Clay-Oven Kompia',
      'category': CulturalCategory.food,
      'location': 'Market Road, Sibu',
      'status': 'Approved',
      'xp': '+50 XP',
      'date': '3 days ago',
    },
    {
      'title': 'Shoreditch Brick Lane Murals',
      'category': CulturalCategory.murals,
      'location': 'Brick Lane, London',
      'status': 'Pending Review',
      'xp': 'Pending',
      'date': 'Just now',
    },
  ];

  // Contributor Badges
  final List<Map<String, dynamic>> _badges = [
    {
      'name': 'Heritage Scout',
      'icon': Icons.account_balance_rounded,
      'category': 'Heritage',
      'status': 'Unlocked',
      'desc': 'Discovered 3 historical landmarks in Sarawak.',
      'bg': Color(0xFFD4F6E6),
      'border': Color(0xFF2E856E),
    },
    {
      'name': 'Street Foodie',
      'icon': Icons.restaurant_rounded,
      'category': 'Food',
      'status': 'Unlocked',
      'desc': 'Explored 3 traditional Sarawak food spots.',
      'bg': Color(0xFFD8F2FF),
      'border': Color(0xFF78B9CB),
    },
    {
      'name': 'Mural Hunter',
      'icon': Icons.palette_rounded,
      'category': 'Murals',
      'status': 'Unlocked',
      'desc': 'Cataloged 2 vibrant community street murals.',
      'bg': Color(0xFFFFE0ED),
      'border': Color(0xFFD98BA8),
    },
    {
      'name': 'Craft Apprentice',
      'icon': Icons.shopping_basket_rounded,
      'category': 'Crafts',
      'status': 'In Progress (2/3)',
      'desc': 'Visit 3 indigenous craft and weaving workshops.',
      'bg': Color(0xFFFFF0D1),
      'border': Color(0xFFE2C46E),
    },
    {
      'name': 'Master Curator',
      'icon': Icons.workspace_premium_rounded,
      'category': 'Curator',
      'status': 'Locked',
      'desc': 'Submit 5 community-approved cultural gems.',
      'bg': Color(0xFFF3ECE0),
      'border': Color(0xFFB5ACA2),
    },
  ];

  Future<void> _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase sign out note: $e');
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out of LoraGuide. See you again, Explorer!'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 1),
      ),
    );

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showBadgeDetails(Map<String, dynamic> badge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF5A4D47), width: 2),
        ),
        title: Row(
          children: [
            Icon(badge['icon'] as IconData, size: 24, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              badge['name'] as String,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badge['bg'] as Color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: badge['border'] as Color, width: 1.2),
              ),
              child: Text(
                'Status: ${badge['status']}',
                style: GoogleFonts.fredoka(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge['desc'] as String,
              style: GoogleFonts.nunito(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFF5A4D47),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFF336E67), width: 1.8),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
              ),
              child: Text(
                'Got it!',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail =
        Supabase.instance.client.auth.currentUser?.email ??
        'explorer@loraguide.my';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // 1. Top Header with Settings & Log out
                _buildHeader(),

                const SizedBox(height: 16),

                // 2. Profile Card with Avatar Toggle
                _buildProfileCard(userEmail),

                const SizedBox(height: 18),

                // 3. Quick Stats Metric Cards (3 Cards Row)
                _buildStatsRow(),

                const SizedBox(height: 22),

                // 4. Contributor Badges Section
                _buildContributorBadgesSection(),

                const SizedBox(height: 22),

                // 5. My Contributions Feed (Tabs & List)
                _buildContributionsSection(),

                const SizedBox(height: 22),

                // 6. About Project & Group Info
                _buildProjectInfoCard(),

                const SizedBox(height: 22),

                // 7. Logout Button
                _buildLogoutButton(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header Section
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explorer Profile',
              style: GoogleFonts.fredoka(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Your cultural journey, badges & discoveries.',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings: Notifications & Sync are active.'),
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBrown, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFD6CBC3),
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.darkBrown,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Profile Card with Avatar Switcher
  // ---------------------------------------------------------------------------
  Widget _buildProfileCard(String userEmail) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F8F5), Color(0xFFFFF9F0)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBrown, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            offset: Offset(0, 5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Color(0xFFD6CBC3),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with click-to-switch indicator
              GestureDetector(
                onTap: () {
                  setState(() => _isGirlAvatar = !_isGirlAvatar);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Switched avatar to ${_isGirlAvatar ? "Explorer Hana" : "Explorer Alex"}!',
                      ),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            offset: Offset(0, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          _isGirlAvatar
                              ? 'assets/icons/girl_avatar.png'
                              : 'assets/icons/boy_avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // User Info & Rank
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _isGirlAvatar ? 'Hana Explorer' : 'Alex Explorer',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('🌿', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.darkBrown,
                          width: 1.2,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '⭐ Sarawak Cultural Scout • Lv. 3',
                          style: GoogleFonts.fredoka(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Level XP Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level 3 Progression',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  Text(
                    '350 / 500 XP (70%)',
                    style: GoogleFonts.fredoka(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkBrown, width: 1.4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.70,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4A9188), Color(0xFF67B5AA)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Stats Row
  // ---------------------------------------------------------------------------
  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.location_on_rounded,
          count: '6',
          label: 'Gems Visited',
          bg: const Color(0xFFD8F2FF),
          border: const Color(0xFF78B9CB),
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          icon: Icons.pets_rounded,
          count: '3',
          label: 'Creatures',
          bg: const Color(0xFFFFE0ED),
          border: const Color(0xFFD98BA8),
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          icon: Icons.edit_note_rounded,
          count: '3',
          label: 'Shared',
          bg: const Color(0xFFFFF0D1),
          border: const Color(0xFFE2C46E),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String count,
    required String label,
    required Color bg,
    required Color border,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.6),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFD6CBC3),
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 2),
            Text(
              count,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5A4D47),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Contributor Badges Section
  // ---------------------------------------------------------------------------
  Widget _buildContributorBadgesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Contributor Badges',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.military_tech_rounded, size: 16),
              ],
            ),
            Text(
              '3 / 5 Unlocked',
              style: GoogleFonts.fredoka(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _badges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final badge = _badges[index];
              final isUnlocked = badge['status'] == 'Unlocked';

              return GestureDetector(
                onTap: () => _showBadgeDetails(badge),
                child: Container(
                  width: 104,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUnlocked ? (badge['bg'] as Color) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isUnlocked
                          ? (badge['border'] as Color)
                          : const Color(0xFFD6CBC3),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUnlocked
                            ? const Color(0xFFD6CBC3)
                            : const Color(0xFFE5DDD5),
                        offset: const Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        badge['icon'] as IconData,
                        size: 28,
                        color: isUnlocked
                            ? AppColors.primary
                            : Colors.black.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        badge['name'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? AppColors.darkBrown
                              : const Color(0xFF8A7E76),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isUnlocked ? 'Unlocked ✓' : 'In Progress',
                        style: GoogleFonts.nunito(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? const Color(0xFF2E856E)
                              : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. My Contributions Section
  // ---------------------------------------------------------------------------
  Widget _buildContributionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Cultural Contributions',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD4F6E6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '3 Shared',
                style: GoogleFonts.fredoka(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E856E),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Submissions List
        ..._mySubmissions.map((sub) {
          final isApproved = sub['status'] == 'Approved';
          final category = sub['category'] as CulturalCategory;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBrown, width: 1.6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFD6CBC3),
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkBrown, width: 1.4),
                  ),
                  child: Center(
                    child: Icon(
                      category.icon,
                      size: 22,
                      color: category.textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub['title'] as String,
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sub['location']} • ${sub['date']}',
                        style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? const Color(0xFFD4F6E6)
                        : const Color(0xFFFFF0D1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isApproved
                          ? const Color(0xFF2E856E)
                          : const Color(0xFFE2C46E),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isApproved ? 'Approved ✓' : 'In Review ⏳',
                    style: GoogleFonts.fredoka(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isApproved
                          ? const Color(0xFF2E856E)
                          : const Color(0xFF7A6014),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Project & Group Info
  // ---------------------------------------------------------------------------
  Widget _buildProjectInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6CBC3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBrown, width: 1.2),
            ),
            child: const Text('🎓', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LoraGuide • Group NEXORA',
                  style: GoogleFonts.fredoka(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SECB3104 Applications Development\nLocation-based cultural discovery for local food, heritage, murals and crafts in Sarawak.',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Logout Button
  // ---------------------------------------------------------------------------
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleSignOut,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFAC5E52), width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFD6CBC3),
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: Color(0xFFAC5E52),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Sign Out from LoraGuide',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFAC5E52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
