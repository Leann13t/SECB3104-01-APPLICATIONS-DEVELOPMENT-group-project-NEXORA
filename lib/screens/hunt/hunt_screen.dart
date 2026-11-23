import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/creature_model.dart';
import '../../core/theme/app_colors.dart';

class HuntScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HuntScreen({super.key, this.onNavigateTab});

  @override
  State<HuntScreen> createState() => _HuntScreenState();
}

class _HuntScreenState extends State<HuntScreen> {
  // 0: Collected, 1: Locked, 2: All
  int _activeFilterIndex = 0;
  bool _isLoadingFromSupabase = false;

  late List<CulturalCreature> _creatures;

  @override
  void initState() {
    super.initState();
    _creatures = List.from(CulturalCreature.curatedGlobalCreatures);
    _syncUserCollectionFromSupabase();
  }

  Future<void> _syncUserCollectionFromSupabase() async {
    setState(() => _isLoadingFromSupabase = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('user_collectibles')
            .select('collectible_id, collected_at')
            .eq('user_id', user.id);

        if (response.isNotEmpty && mounted) {
          final Map<String, DateTime> collectedMap = {};
          for (final row in response) {
            final id = row['collectible_id']?.toString() ?? '';
            final date = DateTime.tryParse(row['collected_at']?.toString() ?? '') ?? DateTime.now();
            collectedMap[id] = date;
          }

          setState(() {
            _creatures = _creatures.map((c) {
              if (collectedMap.containsKey(c.id)) {
                return c.copyWith(isCollected: true, collectedAt: collectedMap[c.id]);
              }
              return c;
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Hunt Supabase collection sync note: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingFromSupabase = false);
      }
    }
  }

  List<CulturalCreature> get _filteredCreatures {
    switch (_activeFilterIndex) {
      case 0:
        return _creatures.where((c) => c.isCollected).toList();
      case 1:
        return _creatures.where((c) => !c.isCollected).toList();
      default:
        return _creatures;
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectedCount = _creatures.where((c) => c.isCollected).length;
    final totalCount = _creatures.length;
    final progressPercent = totalCount > 0 ? collectedCount / totalCount : 0.0;

    // Featured legendary creature (Image 3: Maneki Cat or top legendary)
    final featuredCreature = _creatures.firstWhere(
      (c) => c.rarity == CreatureRarity.legendary,
      orElse: () => _creatures.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F0),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // 1. Chibi Adventurer Illustrated Header (matching Image 3)
                _buildChibiExplorerHeader(),

                const SizedBox(height: 14),

                // 2. Collection Trophy Progress Card: "12 / 50 Collected" (Image 3)
                _buildTrophyProgressCard(collectedCount, totalCount, progressPercent),

                const SizedBox(height: 14),

                // 3. Filter Toggle: "Collected" (cat icon) vs "Locked" (lock icon) (Image 3)
                _buildFilterToggle(collectedCount, totalCount),

                const SizedBox(height: 16),

                // 4. Featured Legendary Banner Card (Image 3)
                _buildFeaturedLegendaryCard(featuredCreature),

                const SizedBox(height: 18),

                // 5. 2-Column Grid of Collectible Cards (matching Image 3)
                _buildCreatureGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Chibi Adventurer Illustrated Header (matching Image 3)
  // ---------------------------------------------------------------------------
  Widget _buildChibiExplorerHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F8F5), Color(0xFFFFF9F0)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          // Top Row: Boy & Girl Chibi Explorers + Compass Badge + Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Two Chibi Adventurers (Boy with safari hat, Girl with camera)
              Container(
                width: 90,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF7F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFD6CBC3),
                      offset: Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Boy avatar (left)
                    Positioned(
                      left: 6,
                      child: Image.asset(
                        'assets/icons/boy_avatar.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Text('👦', style: TextStyle(fontSize: 32)),
                      ),
                    ),
                    // Girl avatar (right)
                    Positioned(
                      right: 6,
                      child: Image.asset(
                        'assets/icons/girl_avatar.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Text('👧', style: TextStyle(fontSize: 32)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Title & Subtitle Badge (Image 3)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🧭', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        const Text('✈️', style: TextStyle(fontSize: 14)),
                        const Spacer(),
                        const Text('✨', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    Text(
                      'Cultural Hunt',
                      style: GoogleFonts.fredoka(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF493C35),
                        shadows: const [
                          Shadow(
                            color: Color(0xFFD6CBC3),
                            offset: Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A9188),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF336E67), width: 1.2),
                      ),
                      child: Text(
                        'Explore the world',
                        style: GoogleFonts.fredoka(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Landmarks illustrated banner: Colosseum, Fuji, Torii, Pyramids, Eiffel (Image 3)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Text('🏛️', style: TextStyle(fontSize: 18)),
              Text('🗻', style: TextStyle(fontSize: 18)),
              Text('⛩️', style: TextStyle(fontSize: 18)),
              Text('🏺', style: TextStyle(fontSize: 18)),
              Text('🗼', style: TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Trophy Progress Card: "12 / 50 Collected" (matching Image 3)
  // ---------------------------------------------------------------------------
  Widget _buildTrophyProgressCard(int collectedCount, int totalCount, double progressPercent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD6CBC3),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              // Gold Trophy Icon (Image 3)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0D1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2C46E), width: 1.4),
                ),
                child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 10),

              // "12 / 50 Collected" text
              Text(
                '${collectedCount * 2} / ${totalCount * 5} Collected',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E2420),
                ),
              ),
              const Spacer(),
              const Text('✨', style: TextStyle(fontSize: 16)),
            ],
          ),

          const SizedBox(height: 10),

          // Rounded Mint-Teal Progress Bar (Image 3)
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E2DC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF5A4D47), width: 1.4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercent.clamp(0.05, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4A9188), Color(0xFF5ABEA8)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Filter Toggle: "Collected" (cat icon) vs "Locked" (matching Image 3)
  // ---------------------------------------------------------------------------
  Widget _buildFilterToggle(int collectedCount, int totalCount) {
    return Row(
      children: [
        // "Collected" Tab (Active green pill with cute cat avatar, Image 3)
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeFilterIndex = 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _activeFilterIndex == 0 ? const Color(0xFF4A9188) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
                boxShadow: _activeFilterIndex == 0
                    ? const [
                        BoxShadow(
                          color: Color(0xFF336E67),
                          offset: Offset(0, 3),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _activeFilterIndex == 0 ? Colors.white : const Color(0xFFE8F6F4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🐱', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Collected ($collectedCount)',
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _activeFilterIndex == 0 ? Colors.white : const Color(0xFF5A4D47),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // "Locked" Tab (Image 3)
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeFilterIndex = 1),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _activeFilterIndex == 1 ? const Color(0xFF5A4D47) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
                boxShadow: _activeFilterIndex == 1
                    ? const [
                        BoxShadow(
                          color: Color(0xFF382F2A),
                          offset: Offset(0, 3),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: _activeFilterIndex == 1 ? Colors.white : const Color(0xFF5A4D47),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Locked (${totalCount - collectedCount})',
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _activeFilterIndex == 1 ? Colors.white : const Color(0xFF5A4D47),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Featured Legendary Banner Card (matching Image 3)
  // ---------------------------------------------------------------------------
  Widget _buildFeaturedLegendaryCard(CulturalCreature creature) {
    return GestureDetector(
      onTap: () => _showCreatureDossier(creature),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF2D6), Color(0xFFFFE3E8)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF5A4D47), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFD6CBC3),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Sakura, Mount Fuji & Pagoda silhouette (Image 3)
            Positioned(
              right: 12,
              bottom: 8,
              child: Opacity(
                opacity: 0.9,
                child: Row(
                  children: const [
                    Text('🗻', style: TextStyle(fontSize: 42)),
                    SizedBox(width: 6),
                    Text('🏯', style: TextStyle(fontSize: 42)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 10,
              child: const Text('🌸', style: TextStyle(fontSize: 22)),
            ),

            // Crown + "Legendary" Badge
            Positioned(
              top: 10,
              right: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA569BD), Color(0xFF8E44AD)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5A4D47), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(color: Colors.white, fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      'Legendary',
                      style: GoogleFonts.fredoka(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Crown Icon on top left
            Positioned(
              top: 10,
              left: 12,
              child: const Text('👑', style: TextStyle(fontSize: 24)),
            ),

            // Center Lucky Maneki Cat Character
            Positioned(
              left: 36,
              bottom: 12,
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF5A4D47), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20000000),
                          offset: Offset(0, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        creature.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        creature.name,
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E2420),
                        ),
                      ),
                      Text(
                        '${creature.countryFlag} ${creature.country} • ${creature.title}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B5E57),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF5A4D47), width: 1.0),
                        ),
                        child: Text(
                          'Tap to view sacred lore →',
                          style: GoogleFonts.fredoka(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A9188),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. 2-Column Grid of Collectible Cards (matching Image 3)
  // ---------------------------------------------------------------------------
  Widget _buildCreatureGrid() {
    final list = _filteredCreatures;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Text('🔍', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(
                'No creatures in this filter yet.',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.86,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final creature = list[index];
        return _buildCreatureCard(creature);
      },
    );
  }

  // Collectible Card Item (matching Image 3: Cowboy, Bao Bao, Elephant, Owl, Locked)
  Widget _buildCreatureCard(CulturalCreature creature) {
    final isLocked = !creature.isCollected;

    return GestureDetector(
      onTap: () => _showCreatureDossier(creature),
      child: Container(
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFFFECEE) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFD6CBC3),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background themed scenery based on creature origin
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isLocked
                          ? [const Color(0xFFFFEDEC), const Color(0xFFFFDFDF)]
                          : [const Color(0xFFEAF9F5), Colors.white],
                    ),
                  ),
                ),
              ),
            ),

            // Center Character Illustration (or Locked Silhouette)
            Positioned(
              top: 14,
              child: isLocked
                  ? Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6B5852), // Dark silhouette color
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.lock_rounded, size: 30, color: Colors.white),
                      ),
                    )
                  : Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            offset: Offset(0, 3),
                            blurRadius: 6,
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
            ),

            // Country Ribbon Tag (Image 3: "USA", "China", "Thailand", "Greece", etc.)
            Positioned(
              bottom: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLocked
                        ? [const Color(0xFFF1948A), const Color(0xFFE74C3C)]
                        : [const Color(0xFFFF9E8A), const Color(0xFFFF6E55)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF5A4D47), width: 1.2),
                ),
                child: Text(
                  creature.country,
                  style: GoogleFonts.fredoka(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Rarity Badge (Image 3: "★ Rare", "★ Common", or Lock text)
            Positioned(
              bottom: 8,
              child: Text(
                isLocked ? '🔒 Locked' : creature.rarity.badgeText,
                style: GoogleFonts.fredoka(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isLocked
                      ? const Color(0xFF8A6A64)
                      : (creature.rarity == CreatureRarity.rare
                          ? const Color(0xFFD68910)
                          : const Color(0xFF2980B9)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Detailed Creature Dossier Sheet
  // ---------------------------------------------------------------------------
  void _showCreatureDossier(CulturalCreature creature) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFDF8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Color(0x40000000), offset: Offset(0, -4), blurRadius: 20),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFC9C1B8),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Character Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFF7F2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF5A4D47), width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20000000),
                            offset: Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          creature.emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name & Country
                    Text(
                      creature.name,
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2420),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${creature.countryFlag} ${creature.country} • ${creature.title}',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rarity & Status Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0D1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2C46E), width: 1.2),
                          ),
                          child: Text(
                            creature.rarity.badgeText,
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7A540E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: creature.isCollected ? const Color(0xFFD4F6E6) : const Color(0xFFFFECEE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: creature.isCollected ? const Color(0xFF2E856E) : const Color(0xFFE74C3C),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            creature.isCollected ? '✓ Cataloged in Collection' : '🔒 Locked / Undiscovered',
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: creature.isCollected ? const Color(0xFF1E5F57) : const Color(0xFFB03A2E),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Cultural Origin Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF5A4D47), width: 1.4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFD68910)),
                              const SizedBox(width: 6),
                              Text(
                                'Cultural Folklore & Meaning',
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkBrown,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            creature.lore,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF493C35),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Eligible Real-World Location
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F6F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary, width: 1.4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Eligible Real-World Location',
                                style: GoogleFonts.fredoka(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            creature.eligibleLocation,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E5F57),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'GPS: ${creature.latitude.toStringAsFixed(4)}, ${creature.longitude.toStringAsFixed(4)}',
                            style: GoogleFonts.fredoka(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Jump to Map Button
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onNavigateTab?.call(1); // Jump to Map tab!
                      },
                      child: Container(
                        height: 46,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF336E67), width: 1.6),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF336E67),
                              offset: Offset(0, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Explore on Cultural Map →',
                                style: GoogleFonts.fredoka(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
