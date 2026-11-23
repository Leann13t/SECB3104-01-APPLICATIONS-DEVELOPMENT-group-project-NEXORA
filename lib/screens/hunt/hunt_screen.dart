import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/creature_model.dart';
import '../../core/theme/app_colors.dart';

class HuntScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HuntScreen({super.key, this.onNavigateTab});

  @override
  State<HuntScreen> createState() => _HuntScreenState();
}

class _HuntScreenState extends State<HuntScreen> {
  int _activeFilterIndex = 0; // 0: All, 1: Collected, 2: Undiscovered
  bool _isScanningRadar = false;

  // Working state copy of creatures (so user can simulate unlocking/collecting in demo!)
  late List<CulturalCreature> _creatures;

  @override
  void initState() {
    super.initState();
    _creatures = List.from(CulturalCreature.placeholderCreatures);
  }

  List<CulturalCreature> get _filteredCreatures {
    switch (_activeFilterIndex) {
      case 1:
        return _creatures.where((c) => c.isCollected).toList();
      case 2:
        return _creatures.where((c) => !c.isCollected).toList();
      default:
        return _creatures;
    }
  }

  void _triggerRadarScan() {
    setState(() => _isScanningRadar = true);

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _isScanningRadar = false);

      final uncollected = _creatures.where((c) => !c.isCollected).toList();
      if (uncollected.isNotEmpty) {
        final target = uncollected.first;
        _showRadarDiscoveryDialog(target);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 All cultural creatures in this region have been cataloged!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    });
  }

  void _showRadarDiscoveryDialog(CulturalCreature creature) {
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
            const Text('📡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'Aura Detected!',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E2420),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0ED),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF5A4D47), width: 2),
                ),
                child: Center(
                  child: Text(
                    creature.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                creature.name,
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E2420),
                ),
              ),
            ),
            Center(
              child: Text(
                creature.title,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF5A4D47), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_pin,
                    color: AppColors.coral,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nearby at: ${creature.eligibleLocation} (~140m away)',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E2420),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Later',
              style: GoogleFonts.fredoka(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _collectCreature(creature);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFAC5E52), width: 1.8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Check-in & Collect! ✨',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _collectCreature(CulturalCreature creature) {
    final index = _creatures.indexWhere((c) => c.id == creature.id);
    if (index != -1) {
      setState(() {
        _creatures[index] = CulturalCreature(
          id: creature.id,
          name: creature.name,
          title: creature.title,
          culturalOrigin: creature.culturalOrigin,
          eligibleLocation: creature.eligibleLocation,
          rarity: creature.rarity,
          emoji: creature.emoji,
          lore: creature.lore,
          isCollected: true,
        );
      });

      _showCelebrationDialog(_creatures[index]);
    }
  }

  void _showCelebrationDialog(CulturalCreature creature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF5A4D47), width: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(
              '🎊 Creature Cataloged! 🎊',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFDFF7F2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  creature.emoji,
                  style: const TextStyle(fontSize: 42),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              creature.name,
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E2420),
              ),
            ),
            Text(
              creature.title,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF5A4D47), width: 1.5),
              ),
              child: Text(
                '“${creature.lore}”',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF2E2420),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0D1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2C46E), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    '+100 Cultural Explorer XP!',
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E2420),
                    ),
                  ),
                ],
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
                  vertical: 10,
                ),
              ),
              child: Text(
                'Awesome!',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
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
    final collectedCount = _creatures.where((c) => c.isCollected).length;
    final totalCount = _creatures.length;
    final progressPercent = totalCount > 0 ? collectedCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // 1. Top Header Banner
                _buildHeader(),

                const SizedBox(height: 16),

                // 2. Explorer Rank & Collection Progress Card
                _buildProgressCard(collectedCount, totalCount, progressPercent),

                const SizedBox(height: 18),

                // 3. Radar Scan Action Button
                _buildRadarButton(),

                const SizedBox(height: 20),

                // 4. Filter Tabs (All, Collected, Undiscovered)
                _buildFilterTabs(collectedCount, totalCount),

                const SizedBox(height: 16),

                // 5. Creature Cards Grid
                _buildCreaturesGrid(),

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
            Row(
              children: [
                Text(
                  'Cultural Hunt',
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                  ),
                ),
                const SizedBox(width: 8),
                Text('✨', style: const TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Discover local culture. Collect unique creatures.',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE0ED),
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
          child: Center(
            child: Image.asset(
              'assets/icons/hunt_icon.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Collection Progress Card
  // ---------------------------------------------------------------------------
  Widget _buildProgressCard(
    int collectedCount,
    int totalCount,
    double progressPercent,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F8F5), Color(0xFFFFF4F0)],
        ),
        borderRadius: BorderRadius.circular(22),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
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
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        'LV. 3',
                        style: GoogleFonts.fredoka(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Sarawak Cultural Scout',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBrown, width: 1.4),
                ),
                child: Text(
                  '$collectedCount / $totalCount Discovered',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Custom 3D Progress Bar
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBrown, width: 1.6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercent.clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4A9188), Color(0xFF67B5AA)],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(progressPercent * 100).toInt()}% Completed',
                      style: GoogleFonts.fredoka(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: progressPercent > 0.4
                            ? Colors.white
                            : AppColors.darkBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Rarity counts summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRarityCount(
                label: 'Common',
                count: '1/2',
                color: const Color(0xFFD8F2FF),
                borderColor: const Color(0xFF78B9CB),
              ),
              _buildRarityCount(
                label: 'Rare',
                count: '1/2',
                color: const Color(0xFFFFF0D1),
                borderColor: const Color(0xFFE2C46E),
              ),
              _buildRarityCount(
                label: 'Legendary',
                count: '1/2',
                color: const Color(0xFFFFE0ED),
                borderColor: const Color(0xFFD98BA8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRarityCount({
    required String label,
    required String count,
    required Color color,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count,
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Radar Scan Button
  // ---------------------------------------------------------------------------
  Widget _buildRadarButton() {
    return GestureDetector(
      onTap: _isScanningRadar ? null : _triggerRadarScan,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFAB99), Color(0xFFFF816F)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFAC5E52), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFAC5E52),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isScanningRadar) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Searching Nearby Cultural Aura...',
                style: GoogleFonts.fredoka(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ] else ...[
              const Text('📡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Scan Nearby Cultural Aura',
                style: GoogleFonts.fredoka(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Text('✨', style: TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Filter Tabs
  // ---------------------------------------------------------------------------
  Widget _buildFilterTabs(int collectedCount, int totalCount) {
    final tabs = [
      {'label': 'All', 'count': totalCount},
      {'label': 'Collected', 'count': collectedCount},
      {'label': 'Locked', 'count': totalCount - collectedCount},
    ];

    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = _activeFilterIndex == index;
        final item = tabs[index];

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeFilterIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 5,
                right: index == tabs.length - 1 ? 0 : 5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF336E67)
                      : const Color(0xFFC9C1B8),
                  width: isSelected ? 1.8 : 1.2,
                ),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0xFF336E67),
                          offset: Offset(0, 3),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${item['label']} (${item['count']})',
                  style: GoogleFonts.fredoka(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.darkBrown,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Creature Grid
  // ---------------------------------------------------------------------------
  Widget _buildCreaturesGrid() {
    final list = _filteredCreatures;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final creature = list[index];
        return _buildCreatureCard(creature);
      },
    );
  }

  Widget _buildCreatureCard(CulturalCreature creature) {
    final isCollected = creature.isCollected;

    Color cardBg;
    Color borderColor;
    Color rarityBg;

    switch (creature.rarity) {
      case CreatureRarity.common:
        cardBg = const Color(0xFFF0FAF8);
        borderColor = const Color(0xFF98D1C8);
        rarityBg = const Color(0xFFD8F2FF);
        break;
      case CreatureRarity.rare:
        cardBg = const Color(0xFFFFFDF2);
        borderColor = const Color(0xFFE5CE87);
        rarityBg = const Color(0xFFFFF0D1);
        break;
      case CreatureRarity.legendary:
        cardBg = const Color(0xFFFCF4F8);
        borderColor = const Color(0xFFE2A8C1);
        rarityBg = const Color(0xFFFFE0ED);
        break;
    }

    if (!isCollected) {
      cardBg = const Color(0xFFF5EFE8);
      borderColor = const Color(0xFFD0C5B8);
    }

    return GestureDetector(
      onTap: () => _showCreatureDossier(creature),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCollected ? AppColors.darkBrown : borderColor,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isCollected
                  ? const Color(0xFFD6CBC3)
                  : const Color(0xFFDDD2C6),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top tag row: Rarity & Collected status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: rarityBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.darkBrown.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    creature.rarity.label,
                    style: GoogleFonts.fredoka(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ),
                if (isCollected)
                  const Text(
                    '✓ Found',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E856E),
                    ),
                  )
                else
                  const Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: Color(0xFF8C7F77),
                  ),
              ],
            ),

            const Spacer(),

            // Creature Avatar / Emoji Circle
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCollected
                      ? AppColors.darkBrown
                      : const Color(0xFFB5ACA2),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCollected
                        ? const Color(0x18000000)
                        : const Color(0x0A000000),
                    offset: const Offset(0, 3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: isCollected
                    ? Text(creature.emoji, style: const TextStyle(fontSize: 34))
                    : Opacity(
                        opacity: 0.35,
                        child: Text(
                          creature.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
              ),
            ),

            const Spacer(),

            // Name & Title
            Text(
              creature.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isCollected
                    ? AppColors.darkBrown
                    : const Color(0xFF7A6F68),
              ),
            ),

            const SizedBox(height: 2),

            Text(
              creature.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),

            const SizedBox(height: 6),

            // Location hint pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isCollected
                    ? Colors.white.withValues(alpha: 0.8)
                    : const Color(0xFFE9DFD4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCollected
                    ? creature.eligibleLocation
                    : '🔒 At ${creature.eligibleLocation}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isCollected
                      ? const Color(0xFF5A4D47)
                      : const Color(0xFF8A7E76),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Creature Dossier Bottom Sheet
  // ---------------------------------------------------------------------------
  void _showCreatureDossier(CulturalCreature creature) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFF9F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0xFF5A4D47), width: 2.2),
              left: BorderSide(color: Color(0xFF5A4D47), width: 2.2),
              right: BorderSide(color: Color(0xFF5A4D47), width: 2.2),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6CBC3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Top row: Emoji & Rarity
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: creature.isCollected
                            ? const Color(0xFFDFF7F2)
                            : const Color(0xFFEDE4DB),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF5A4D47),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          creature.emoji,
                          style: TextStyle(
                            fontSize: 34,
                            color: creature.isCollected
                                ? null
                                : Colors.black.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.darkBrown,
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  creature.rarity.label.toUpperCase(),
                                  style: GoogleFonts.fredoka(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                creature.isCollected
                                    ? '✓ In Collection'
                                    : '🔒 Undiscovered',
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: creature.isCollected
                                      ? const Color(0xFF2E856E)
                                      : const Color(0xFF8A7E76),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            creature.name,
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E2420),
                            ),
                          ),
                          Text(
                            creature.title,
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Cultural Lore Story Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF5A4D47),
                      width: 1.6,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('📜', style: TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text(
                            'Cultural Origin & Lore',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E2420),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        creature.lore,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          height: 1.45,
                          color: const Color(0xFF5A4D47),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0D1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Text('🏮', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tradition: ${creature.culturalOrigin}',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF5A4D47),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Encounter Condition
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6F4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF78B9CB),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Spawn Habitat: ${creature.eligibleLocation}',
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E2420),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    if (!creature.isCollected)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _collectCreature(creature);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.coral,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            side: const BorderSide(
                              color: Color(0xFFAC5E52),
                              width: 1.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Simulate Check-in ✨',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(1); // Go to Map tab
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            side: const BorderSide(
                              color: Color(0xFF336E67),
                              width: 1.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'View Habitat on Map 🗺️',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
