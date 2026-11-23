import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/discovery_model.dart';
import '../../core/models/creature_model.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  CulturalCategory? _selectedCategory;

  // Placeholder discoveries (clearly marked sample data)
  final List<Discovery> _allDiscoveries = Discovery.placeholderDiscoveries;
  final List<CulturalCreature> _creatures =
      CulturalCreature.placeholderCreatures;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Discovery> get _filteredDiscoveries {
    if (_selectedCategory == null) return _allDiscoveries;
    return _allDiscoveries
        .where((d) => d.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final int collectedCount = _creatures.where((c) => c.isCollected).length;
    final int totalCreatures = _creatures.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            bottom: 100,
          ), // Space for floating bottom nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. Top Header with Greeting & Avatar / Notification
              _buildHeader(context),

              const SizedBox(height: 16),

              // 2. Search Bar
              _buildSearchBar(),

              const SizedBox(height: 20),

              // 3. Category Shortcuts (Food, Heritage, Murals, Crafts)
              _buildCategoryShortcuts(),

              const SizedBox(height: 22),

              // 4. Explore Cultural Map Banner
              _buildExploreMapBanner(context),

              const SizedBox(height: 22),

              // 5. Cultural Hunt Progress Teaser
              _buildCulturalHuntTeaser(context, collectedCount, totalCreatures),

              const SizedBox(height: 24),

              // 6. Featured Hidden Gems (Horizontal Scroll Cards)
              _buildFeaturedSection(context),

              const SizedBox(height: 26),

              // 7. Recently Added Discoveries (Horizontal / Grid Feed)
              _buildRecentlyAddedSection(context),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header Section
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Title, Mascot Icon & Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LoraGuide',
                      style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBrown,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Small cartoon location-pin mascot badge
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.lightMint,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryTeal,
                          width: 1.6,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.location_on_rounded, size: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Discover culture. Explore the world.',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Actions: Notification bell & profile avatar
          Row(
            children: [
              // Notification Bell
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notifications: 2 new Sarawak cultural spots verified!',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryTeal,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x15000000),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/icons/notification_bell.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Profile Avatar
              GestureDetector(
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(4); // Switch to Profile tab
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkBrown, width: 1.8),
                    color: AppColors.lavender,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/girl_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person_rounded,
                        color: AppColors.darkBrown,
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
  // 2. Search Bar
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primaryTeal, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE4DAD0),
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.primaryTeal,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                ),
                decoration: InputDecoration(
                  hintText: 'Search hidden gems, food, murals...',
                  hintStyle: GoogleFonts.nunito(
                    color: AppColors.secondaryText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.secondaryText,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Category Shortcuts (Food, Heritage, Murals, Crafts)
  // ---------------------------------------------------------------------------
  Widget _buildCategoryShortcuts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'What will you discover?',
                style: GoogleFonts.fredoka(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown,
                ),
              ),
              if (_selectedCategory != null)
                GestureDetector(
                  onTap: () => setState(() => _selectedCategory = null),
                  child: Text(
                    'Clear Filter',
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: CulturalCategory.values.map((category) {
              final bool isSelected = _selectedCategory == category;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = isSelected ? null : category;
                      });
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 64,
                          decoration: BoxDecoration(
                            color: category.color,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryTeal
                                  : AppColors.cardOutline,
                              width: isSelected ? 2.2 : 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.primaryTeal
                                    : AppColors.cardShadow,
                                offset: const Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              category.icon,
                              size: 28,
                              color: category.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category.label,
                          style: GoogleFonts.fredoka(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primaryTeal
                                : AppColors.darkBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Explore Cultural Map Banner
  // ---------------------------------------------------------------------------
  Widget _buildExploreMapBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardOutline, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              offset: Offset(0, 5),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Explore Cultural Map',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryTeal,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    'Interactive',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Mini Map preview visual
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFDFF5E7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardOutline, width: 1.4),
              ),
              child: Stack(
                children: [
                  // Stylized road canvas
                  CustomPaint(
                    size: Size.infinite,
                    painter: _MiniMapRoadPainter(),
                  ),
                  // Cultural landmarks icons
                  const Positioned(
                    left: 30,
                    top: 18,
                    child: Icon(Icons.home_rounded, size: 18),
                  ),
                  const Positioned(
                    right: 35,
                    top: 22,
                    child: Icon(Icons.account_balance_rounded, size: 20),
                  ),
                  const Positioned(
                    left: 80,
                    bottom: 16,
                    child: Icon(Icons.restaurant_rounded, size: 18),
                  ),
                  const Positioned(
                    right: 80,
                    bottom: 20,
                    child: Icon(Icons.palette_rounded, size: 18),
                  ),

                  // Central Smiling Pin Mascot
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF9E4B3E),
                          width: 1.6,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x30000000),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.location_on_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Explore Map Action Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(1); // Switch to Map tab
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(
                      color: Color(0xFF9E4B3E),
                      width: 1.8,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Explore Map →',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Cultural Hunt Progress Teaser
  // ---------------------------------------------------------------------------
  Widget _buildCulturalHuntTeaser(
    BuildContext context,
    int collected,
    int total,
  ) {
    final double progress = total > 0 ? (collected / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          if (widget.onNavigateTab != null) {
            widget.onNavigateTab!(2); // Switch to Hunt tab
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.lavender,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardOutline, width: 1.6),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Creature Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardOutline, width: 1.4),
                ),
                child: const Center(
                  child: Text('🦜', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Progress Bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cultural Hunt Progress',
                          style: GoogleFonts.fredoka(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        Text(
                          '$collected / $total Found',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: AppColors.white,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.darkBrown,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Featured Hidden Gems
  // ---------------------------------------------------------------------------
  Widget _buildFeaturedSection(BuildContext context) {
    final gems = _filteredDiscoveries.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Featured Hidden Gems',
                style: GoogleFonts.fredoka(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(width: 6),
              const Text('✨', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 232,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: gems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final gem = gems[index];
              return _buildDiscoveryCard(context, gem);
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Recently Added Discoveries
  // ---------------------------------------------------------------------------
  Widget _buildRecentlyAddedSection(BuildContext context) {
    final recent = _filteredDiscoveries.reversed.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently Added',
                style: GoogleFonts.fredoka(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBrown,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Showing all community discoveries'),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.fredoka(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 232,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final gem = recent[index];
              return _buildDiscoveryCard(context, gem);
            },
          ),
        ),
      ],
    );
  }

  // Discovery Card component
  Widget _buildDiscoveryCard(BuildContext context, Discovery item) {
    return GestureDetector(
      onTap: () {
        _showDiscoveryDetailSheet(context, item);
      },
      child: Container(
        width: 175,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardOutline, width: 1.6),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / Cultural Photo Header
            Container(
              height: 104,
              width: double.infinity,
              decoration: BoxDecoration(
                color: item.category.color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: item.hasCustomImage
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.expand(),
                      )
                    : const SizedBox.expand(),
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Bottom Row: Approved tag + arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.approvedBadgeBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primaryTeal,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Approved',
                          style: GoogleFonts.nunito(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.approvedGreen,
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.cardOutline,
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: AppColors.darkBrown,
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

  void _showDiscoveryDetailSheet(BuildContext context, Discovery item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardOutline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.category.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.cardOutline,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        item.category.icon,
                        size: 26,
                        color: item.category.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        Text(
                          '${item.category.label} • ${item.location}',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                item.description,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.darkBrown,
                  height: 1.45,
                ),
              ),
              if (item.culturalSignificance != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryTeal,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.culturalSignificance!,
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _MiniMapRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFFFF7ED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final roadBorder = Paint()
      ..color = const Color(0xFFD6CBC3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 23
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.3,
        size.width * 0.5,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.8,
        size.width,
        size.height * 0.65,
      );

    canvas.drawPath(path, roadBorder);
    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
