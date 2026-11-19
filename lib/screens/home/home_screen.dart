import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Model for cultural discoveries (ready for future backend / Firestore integration)
class DiscoveryItem {
  final String id;
  final String name;
  final String category;
  final String location;
  final bool isApproved;
  final String? imageUrl;
  final Widget? illustration;

  const DiscoveryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    this.isApproved = true,
    this.imageUrl,
    this.illustration,
  });
}

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  // Sample data matching Section 2.E & 2.F
  final List<DiscoveryItem> _featuredGems = [
    DiscoveryItem(
      id: 'gem_1',
      name: 'Sibu Heritage Lane',
      category: 'Heritage',
      location: 'Sibu, Sarawak',
      isApproved: true,
      illustration: const _HeritageLaneIllustration(),
    ),
    DiscoveryItem(
      id: 'gem_2',
      name: 'Traditional Craft Corner',
      category: 'Crafts',
      location: 'Sibu, Sarawak',
      isApproved: true,
      illustration: const _CraftCornerIllustration(),
    ),
    DiscoveryItem(
      id: 'gem_3',
      name: 'Tua Pek Kong Temple',
      category: 'Heritage',
      location: 'Sibu, Sarawak',
      isApproved: true,
      illustration: const _TempleIllustration(),
    ),
  ];

  final List<DiscoveryItem> _recentlyAdded = [
    DiscoveryItem(
      id: 'recent_1',
      name: 'Laksa Taman Sentosa',
      category: 'Food',
      location: 'Sibu, Sarawak',
      isApproved: true,
      illustration: const _LaksaIllustration(),
    ),
    DiscoveryItem(
      id: 'recent_2',
      name: 'Community Mural Corner',
      category: 'Murals',
      location: 'Sibu, Sarawak',
      isApproved: true,
      illustration: const _MuralIllustration(),
    ),
    DiscoveryItem(
      id: 'recent_3',
      name: 'Ah Huat Sibu Kompia',
      category: 'Food',
      location: 'Sibu, Sarawak',
      isApproved: true,
      illustration: const _KompiaIllustration(),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F0), // Warm cream background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE6FCF7), // Soft mint green at top (matching Splash & Login)
              Color(0xFFFFF9F0), // Fading into warm cream
              Color(0xFFFFF9F0),
            ],
            stops: [0.0, 0.22, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110), // Space for floating bottom nav
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // A. Header Section
                _buildHeader(context),

                const SizedBox(height: 18),

                // B. Search Bar
                _buildSearchBar(),

                const SizedBox(height: 24),

                // C. Explore by Category
                _buildCategorySection(),

                const SizedBox(height: 24),

                // D. Explore Map — Main Featured Shortcut
                _buildExploreMapCard(context),

                const SizedBox(height: 28),

                // Cute mascot cat banner decoration between sections (as shown in Frame 3)
                _buildScrollTransitionMascot(),

                const SizedBox(height: 12),

                // E. Featured Hidden Gems
                _buildFeaturedSection(context),

                const SizedBox(height: 28),

                // F. Recently Added Discoveries
                _buildRecentlyAddedSection(context),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // A. Header Section
  // -------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Brand title, mascot badge & subtitle
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
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E2420),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Smiling location-pin mascot badge with sparkles
                    _buildMascotBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Discover culture, collect memories!',
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A4D47),
                  ),
                ),
              ],
            ),
          ),

          // Right: Action buttons (Profile Avatar + Notification Bell)
          Row(
            children: [
              // Notification Bell
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications: 2 new hidden gems near you!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F7F4),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFD0EBE7),
                        offset: Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(9),
                  child: Image.asset(
                    'assets/icons/notification_bell.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.notifications_outlined,
                      size: 20,
                      color: Color(0xFF40AA9F),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Profile Avatar with online/notification dot
              GestureDetector(
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(4); // Navigate to Profile tab
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
                        color: const Color(0xFFFFEBE3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFFEAD5CD),
                            offset: Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/girl_avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person,
                            color: Color(0xFF5A4D47),
                          ),
                        ),
                      ),
                    ),
                    // Red notification indicator dot
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6E6E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Mascot mini badge in header
  Widget _buildMascotBadge() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD4CA),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFAC5E52), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE8B6AC),
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '📍',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // B. Search Bar
  // -------------------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFF40AA9F), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFC7EBE6),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B302A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search hidden gems, food, murals...',
                  hintStyle: GoogleFonts.nunito(
                    color: const Color(0xFF9E948D),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Circular search icon button
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFD6F6F0),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF40AA9F), width: 1.6),
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Color(0xFF2C7D75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // C. Explore by Category Section
  // -------------------------------------------------------------
  Widget _buildCategorySection() {
    final categories = [
      {
        'name': 'Food',
        'color': const Color(0xFFD8F2FF),
        'borderColor': const Color(0xFF5A4D47),
        'shadowColor': const Color(0xFFBCE3F5),
        'emoji': '🍜',
      },
      {
        'name': 'Heritage',
        'color': const Color(0xFFD4F6E6),
        'borderColor': const Color(0xFF5A4D47),
        'shadowColor': const Color(0xFFB8E9D0),
        'emoji': '🏛️',
      },
      {
        'name': 'Murals',
        'color': const Color(0xFFFFE0ED),
        'borderColor': const Color(0xFF5A4D47),
        'shadowColor': const Color(0xFFF7C2D9),
        'emoji': '🎨',
      },
      {
        'name': 'Crafts',
        'color': const Color(0xFFFFF0D1),
        'borderColor': const Color(0xFF5A4D47),
        'shadowColor': const Color(0xFFEED5A5),
        'emoji': '🧺',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What will you discover?',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2E2420),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat['name'];
              return _buildCategoryButton(
                name: cat['name'] as String,
                color: cat['color'] as Color,
                borderColor: cat['borderColor'] as Color,
                shadowColor: cat['shadowColor'] as Color,
                emoji: cat['emoji'] as String,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategory = isSelected ? 'All' : cat['name'] as String;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton({
    required String name,
    required Color color,
    required Color borderColor,
    required Color shadowColor,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF2E7B73) : borderColor,
                width: isSelected ? 2.5 : 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? const Color(0xFF2E7B73) : shadowColor,
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? const Color(0xFF2E7B73) : const Color(0xFF2E2420),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // D. Explore the Map — Main Featured Shortcut
  // -------------------------------------------------------------
  Widget _buildExploreMapCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF5A4D47), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFD6CBC3),
              offset: Offset(0, 6),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title with decorative sparkles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('✦', style: GoogleFonts.fredoka(color: const Color(0xFFFFD166), fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Explore the Map',
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E2420),
                  ),
                ),
                const SizedBox(width: 8),
                Text('✦', style: GoogleFonts.fredoka(color: const Color(0xFF85D5E5), fontSize: 18)),
              ],
            ),

            const SizedBox(height: 14),

            // Illustrated Cartoon Mini-Map Canvas
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFDCF3E4), // Soft green landscape
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: const _CartoonMiniMap(),
              ),
            ),

            const SizedBox(height: 16),

            // Prominent "Explore Map →" Coral Button
            GestureDetector(
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(1); // Switch to Map tab
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Interactive Map...')),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9583), Color(0xFFFF7B69)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFAC5E52), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFB15C4C),
                      offset: Offset(0, 5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore Map →',
                        style: GoogleFonts.fredoka(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Mascot Cat Banner Decoration (from Frame 3)
  // -------------------------------------------------------------
  Widget _buildScrollTransitionMascot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Cute Cartoon Cat Mascot
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFE6),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
            ),
            child: const Center(
              child: Text('🐱', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),
          // Swirls and playful sparkles
          Text('✦', style: GoogleFonts.fredoka(color: const Color(0xFFFFD166), fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF85D5E5), Color(0xFFFFB4A2), Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('✦', style: GoogleFonts.fredoka(color: const Color(0xFFCBA9EB), fontSize: 16)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // E. Featured Hidden Gems Section
  // -------------------------------------------------------------
  Widget _buildFeaturedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Featured Hidden Gems',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2E2420),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 236,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _featuredGems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final gem = _featuredGems[index];
              return _buildDiscoveryCard(context, gem);
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // F. Recently Added Section
  // -------------------------------------------------------------
  Widget _buildRecentlyAddedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently Added',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E2420),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Showing all recently added discoveries')),
                  );
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF40AA9F),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 236,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _recentlyAdded.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = _recentlyAdded[index];
              return _buildDiscoveryCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  // Reusable Cultural Discovery Card (matching Frame 3)
  Widget _buildDiscoveryCard(BuildContext context, DiscoveryItem item) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing: ${item.name} (${item.category})'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        width: 172,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFD6CBC3),
              offset: Offset(0, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail container
            Container(
              height: 110,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F3EC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: item.illustration ??
                    const Center(child: Text('📍', style: TextStyle(fontSize: 32))),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discovery Name
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E2420),
                    ),
                  ),

                  const SizedBox(height: 3),

                  // Category & Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF85756C)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${item.category}, ${item.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF85756C),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Bottom row: "Approved" badge + arrow button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Approved Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4F6E6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF56C9BB), width: 1.2),
                        ),
                        child: Text(
                          'Approved',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF22786F),
                          ),
                        ),
                      ),

                      // Arrow Button
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3FAF9),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF5A4D47), width: 1.2),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Color(0xFF2E2420),
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
}

// -------------------------------------------------------------
// Cartoon Mini-Map Custom Vector Artwork
// -------------------------------------------------------------
class _CartoonMiniMap extends StatelessWidget {
  const _CartoonMiniMap();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Roads and pathways
        CustomPaint(
          size: Size.infinite,
          painter: _RoadPainter(),
        ),

        // Houses and landmarks
        const Positioned(
          left: 45,
          top: 35,
          child: _HouseWidget(color: Color(0xFFFF9B85)),
        ),
        const Positioned(
          left: 55,
          bottom: 25,
          child: _HouseWidget(color: Color(0xFFFFBE76)),
        ),
        const Positioned(
          right: 38,
          bottom: 20,
          child: _TemplePagodaWidget(),
        ),

        // Trees
        const Positioned(left: 18, top: 20, child: Text('🌳', style: TextStyle(fontSize: 16))),
        const Positioned(left: 15, bottom: 40, child: Text('🌲', style: TextStyle(fontSize: 14))),
        const Positioned(right: 25, top: 25, child: Text('🌳', style: TextStyle(fontSize: 16))),
        const Positioned(right: 75, top: 45, child: Text('🌲', style: TextStyle(fontSize: 14))),

        // Small location pin markers
        const Positioned(
          left: 28,
          top: 48,
          child: _SmallPin(color: Color(0xFFCBA9EB)), // Purple pin
        ),
        const Positioned(
          right: 48,
          top: 36,
          child: _SmallPin(color: Color(0xFFFF8B7A)), // Salmon pin
        ),

        // Large smiling mascot pin in the center
        Center(
          child: Container(
            width: 46,
            height: 52,
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x30000000),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Base halo
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF69D9C8).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Pin body
                Positioned(
                  top: 0,
                  child: Container(
                    width: 40,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB2A2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF8F3F34), width: 1.8),
                    ),
                    child: Center(
                      child: Text(
                        '😊',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFFFF6E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final roadBorder = Paint()
      ..color = const Color(0xFFD6CBC3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 27
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = const Color(0xFFE8D7C8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw winding roads
    final path1 = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.45, size.width * 0.5, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.8, size.width, size.height * 0.75);

    final path2 = Path()
      ..moveTo(size.width * 0.4, 0)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.4, size.width * 0.5, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.85, size.width * 0.5, size.height);

    canvas.drawPath(path1, roadBorder);
    canvas.drawPath(path2, roadBorder);
    canvas.drawPath(path1, roadPaint);
    canvas.drawPath(path2, roadPaint);

    // Dotted center lines
    canvas.drawPath(path1, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HouseWidget extends StatelessWidget {
  final Color color;
  const _HouseWidget({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EE),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF5A4D47), width: 1.4),
      ),
      child: Column(
        children: [
          Container(
            height: 9,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 4, height: 4, color: const Color(0xFF85D5E5)),
              const SizedBox(width: 4),
              Container(width: 4, height: 4, color: const Color(0xFF85D5E5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplePagodaWidget extends StatelessWidget {
  const _TemplePagodaWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0D1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF5A4D47), width: 1.4),
      ),
      child: Center(
        child: Text('🏯', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _SmallPin extends StatelessWidget {
  final Color color;
  const _SmallPin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF5A4D47), width: 1.4),
      ),
      child: const Center(
        child: Icon(Icons.circle, color: Colors.white, size: 6),
      ),
    );
  }
}

// -------------------------------------------------------------
// Discovery Card Illustration Placeholders
// -------------------------------------------------------------
class _HeritageLaneIllustration extends StatelessWidget {
  const _HeritageLaneIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF1E0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 24, color: const Color(0xFFEADBC8))),
          Positioned(left: 12, bottom: 10, child: Text('🏠', style: const TextStyle(fontSize: 32))),
          Positioned(right: 12, bottom: 10, child: Text('🏮', style: const TextStyle(fontSize: 28))),
          Positioned(top: 10, child: Text('🏮 Sibu Heritage 🏮', style: GoogleFonts.fredoka(fontSize: 10, color: const Color(0xFF8C5543), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _CraftCornerIllustration extends StatelessWidget {
  const _CraftCornerIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF6D6),
      child: Center(
        child: Text('🧺', style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}

class _TempleIllustration extends StatelessWidget {
  const _TempleIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFECE5),
      child: Center(
        child: Text('🏯', style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}

class _LaksaIllustration extends StatelessWidget {
  const _LaksaIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFECE5),
      child: Center(
        child: Text('🍜', style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}

class _MuralIllustration extends StatelessWidget {
  const _MuralIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F7FF),
      child: Center(
        child: Text('🎨', style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}

class _KompiaIllustration extends StatelessWidget {
  const _KompiaIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF2D9),
      child: Center(
        child: Text('🥟', style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}
