import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MapType;
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/discovery_model.dart';
import '../../core/theme/app_colors.dart';

class MapScreen extends StatefulWidget {
  final Discovery? initialSelectedDiscovery;

  const MapScreen({super.key, this.initialSelectedDiscovery});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  CulturalCategory? _selectedCategory;
  Discovery?
  _selectedDiscovery; // Null by default so Google Map is shown first!
  String _searchQuery = '';

  // Mode: true for real GoogleMap, false for offline canvas preview
  bool _useGoogleMaps = true;
  bool _hasMapInitError = false;

  // Supabase data with fallback to sample data clearly marked
  List<Discovery> _discoveries = Discovery.placeholderDiscoveries;
  bool _isLoadingSupabaseData = false;
  bool _isUsingSupabaseData = false;

  // Default camera target: Sibu Heritage Center, Sarawak
  static const LatLng _sibuCenter = LatLng(2.2878, 111.8305);
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _sibuCenter,
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    // Do not pop up any card by default - show the Google Map first!
    _selectedDiscovery = widget.initialSelectedDiscovery;
    _fetchSupabaseDiscoveries();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Supabase Data Fetching (with graceful fallback to placeholder data)
  // ---------------------------------------------------------------------------
  Future<void> _fetchSupabaseDiscoveries() async {
    setState(() => _isLoadingSupabaseData = true);
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('discoveries')
          .select()
          .eq('is_approved', true)
          .timeout(const Duration(seconds: 4));

      if (response.isNotEmpty && mounted) {
        final List<Discovery> loaded = [];
        for (final row in response) {
          final catString = (row['category'] as String?)?.toLowerCase() ?? '';
          CulturalCategory cat = CulturalCategory.heritage;
          for (final c in CulturalCategory.values) {
            if (c.name.toLowerCase() == catString) {
              cat = c;
              break;
            }
          }

          loaded.add(
            Discovery(
              id: row['id']?.toString() ?? 'db_${loaded.length}',
              title: row['title']?.toString() ?? 'Cultural Gem',
              category: cat,
              location: row['location']?.toString() ?? 'Sarawak',
              description: row['description']?.toString() ?? '',
              latitude: (row['latitude'] as num?)?.toDouble() ?? 2.2878,
              longitude: (row['longitude'] as num?)?.toDouble() ?? 111.8305,
              imageUrl: row['image_url']?.toString(),
              isApproved: true,
              culturalSignificance: row['cultural_significance']?.toString(),
            ),
          );
        }

        if (loaded.isNotEmpty) {
          setState(() {
            _discoveries = loaded;
            _isUsingSupabaseData = true;
          });
        }
      }
    } catch (e) {
      debugPrint(
        'Supabase discovery query note (using curated sample data): $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingSupabaseData = false);
      }
    }
  }

  List<Discovery> get _filteredDiscoveries {
    return _discoveries.where((discovery) {
      final matchesCategory =
          _selectedCategory == null || discovery.category == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          discovery.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          discovery.location.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Google Map Markers Generation
  // When an icon/marker is pressed, it triggers the location popup card!
  // ---------------------------------------------------------------------------
  Set<Marker> _buildGoogleMapMarkers() {
    return _filteredDiscoveries.map((discovery) {
      final lat = discovery.latitude ?? 2.2878;
      final lng = discovery.longitude ?? 111.8305;
      final isSelected = _selectedDiscovery?.id == discovery.id;

      double hue;
      switch (discovery.category) {
        case CulturalCategory.food:
          hue = BitmapDescriptor.hueOrange;
          break;
        case CulturalCategory.heritage:
          hue = BitmapDescriptor.hueCyan;
          break;
        case CulturalCategory.murals:
          hue = BitmapDescriptor.hueRose;
          break;
        case CulturalCategory.crafts:
          hue = BitmapDescriptor.hueYellow;
          break;
      }

      return Marker(
        markerId: MarkerId(discovery.id),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        // Disable default basic system tooltip so our custom rich card pops up cleanly
        infoWindow: InfoWindow.noText,
        zIndexInt: isSelected ? 2 : 1,
        onTap: () {
          // Pressing the icon on the map pops up the location details card!
          setState(() {
            _selectedDiscovery = discovery;
          });
          _centerOnLocation(lat, lng);
        },
      );
    }).toSet();
  }

  // ---------------------------------------------------------------------------
  // Map Camera Control & Directions Action
  // ---------------------------------------------------------------------------
  void _centerOnLocation(double lat, double lng) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 16.5),
        ),
      );
    }
  }

  void _recenterToSibu() {
    _centerOnLocation(_sibuCenter.latitude, _sibuCenter.longitude);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Map centered on Sibu Heritage District, Sarawak'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openExternalDirections(Discovery discovery) async {
    final lat = discovery.latitude ?? 2.2878;
    final lng = discovery.longitude ?? 111.8305;
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗺️ Destination: ${discovery.title} ($lat, $lng)'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Directions launch notice: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Directions to ${discovery.title}: $lat, $lng'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Google Map View (Takes up full screen, shown FIRST!)
          Positioned.fill(child: _buildMapBody()),

          // 2. Floating Top Search & Category Filters (Compact overlay)
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 6),
                _buildSearchBar(),
                const SizedBox(height: 6),
                _buildCategoryChips(),
              ],
            ),
          ),

          // 3. Floating Recenter Control Button
          Positioned(
            right: 16,
            bottom: _selectedDiscovery != null ? 240 : 96,
            child: _buildFloatingControls(),
          ),

          // 4. Pop-up Location Details Card (ONLY shown when user presses a marker icon!)
          if (_selectedDiscovery != null)
            Positioned(
              left: 14,
              right: 14,
              bottom:
                  84, // Floats cleanly right above the bottom navigation bar
              child: _buildSelectedDiscoveryCard(_selectedDiscovery!),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Map Body: Real Google Map with Graceful Fallback
  // ---------------------------------------------------------------------------
  Widget _buildMapBody() {
    if (_hasMapInitError || !_useGoogleMaps) {
      return _buildDevelopmentCanvasMap();
    }

    return GoogleMap(
      initialCameraPosition: _initialCameraPosition,
      mapType: MapType.normal,
      markers: _buildGoogleMapMarkers(),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      onMapCreated: (controller) {
        try {
          _mapController = controller;
        } catch (_) {
          if (mounted) setState(() => _hasMapInitError = true);
        }
      },
      onTap: (_) {
        // Tapping anywhere on the map dismisses the popup card so the map is unobstructed
        if (_selectedDiscovery != null) {
          setState(() => _selectedDiscovery = null);
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header: Compact, Semi-Transparent & Map-Focused
  // ---------------------------------------------------------------------------
  Widget _buildTopHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5A4D47), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0xFFD6CBC3),
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.lightMint,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.4),
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/map_icon.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cultural Map',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                  ),
                ),
                Text(
                  _isLoadingSupabaseData
                      ? 'Syncing cultural spots...'
                      : (_selectedDiscovery == null
                            ? (_isUsingSupabaseData
                                  ? 'Live Supabase Community Spots'
                                  : 'Tap any pin on the map to view details')
                            : '${_filteredDiscoveries.length} spots in Sibu district'),
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          // View Mode Switcher
          GestureDetector(
            onTap: () {
              setState(() => _useGoogleMaps = !_useGoogleMaps);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _useGoogleMaps
                    ? const Color(0xFFD4F6E6)
                    : const Color(0xFFFFF0D1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _useGoogleMaps
                      ? const Color(0xFF2E856E)
                      : const Color(0xFFE2C46E),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _useGoogleMaps ? Icons.map_rounded : Icons.brush_rounded,
                    size: 12,
                    color: _useGoogleMaps
                        ? const Color(0xFF2E856E)
                        : const Color(0xFF7A6014),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _useGoogleMaps ? 'Google Map' : 'Canvas Map',
                    style: GoogleFonts.fredoka(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _useGoogleMaps
                          ? const Color(0xFF2E856E)
                          : const Color(0xFF7A6014),
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
  // Search Bar
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFF5A4D47), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD6CBC3),
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.nunito(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.darkBrown,
        ),
        decoration: InputDecoration(
          hintText: 'Search food spots, heritage, murals, crafts...',
          hintStyle: GoogleFonts.nunito(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF9E9590),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category Chips Filter
  // ---------------------------------------------------------------------------
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(
            label: 'All (${_discoveries.length})',
            emoji: '✨',
            isSelected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          const SizedBox(width: 8),
          ...CulturalCategory.values.map((cat) {
            final isSelected = _selectedCategory == cat;
            final count = _discoveries.where((d) => d.category == cat).length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                label: '${cat.label} ($count)',
                emoji: cat.emoji,
                isSelected: isSelected,
                activeColor: cat.color,
                onTap: () {
                  setState(() {
                    _selectedCategory = isSelected ? null : cat;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required String emoji,
    required bool isSelected,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (activeColor ?? AppColors.lightMint)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5A4D47)
                : const Color(0xFFC9C1B8),
            width: isSelected ? 1.6 : 1.2,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0xFFB5ACA2),
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.darkBrown
                    : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Floating Controls (Recenter Button)
  // ---------------------------------------------------------------------------
  Widget _buildFloatingControls() {
    return GestureDetector(
      onTap: _recenterToSibu,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Color(0xFFD6CBC3),
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Selected Discovery Pop-up Card (Triggered by pressing a marker/icon)
  // ---------------------------------------------------------------------------
  Widget _buildSelectedDiscoveryCard(Discovery discovery) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail or Category Emoji Box
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: discovery.category.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF5A4D47),
                    width: 1.6,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: discovery.imageUrl != null
                      ? Image.network(
                          discovery.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              discovery.category.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            discovery.category.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Category Tag, Location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: discovery.category.color,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF5A4D47),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            discovery.category.label,
                            style: GoogleFonts.fredoka(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkBrown,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4F6E6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 10,
                                color: Color(0xFF2E856E),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Approved',
                                style: GoogleFonts.nunito(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E856E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      discovery.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            discovery.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Close Card Button (Dismisses popup back to full map view)
              GestureDetector(
                onTap: () => setState(() => _selectedDiscovery = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3ECE4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Color(0xFF6B5E57),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Action Buttons: "Directions" (External Maps) & "View Details"
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openExternalDirections(discovery),
                  icon: const Icon(
                    Icons.directions_rounded,
                    size: 16,
                    color: AppColors.darkBrown,
                  ),
                  label: Text(
                    'Directions',
                    style: GoogleFonts.fredoka(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF5A4D47),
                      width: 1.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: const Color(0xFFFBF8F5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _showDiscoveryDetailsSheet(context, discovery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    side: const BorderSide(
                      color: Color(0xFF336E67),
                      width: 1.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'View Details →',
                    style: GoogleFonts.fredoka(
                      fontSize: 12.5,
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
    );
  }

  // ---------------------------------------------------------------------------
  // Discovery Details Bottom Sheet Modal
  // ---------------------------------------------------------------------------
  void _showDiscoveryDetailsSheet(BuildContext context, Discovery discovery) {
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
              top: BorderSide(color: Color(0xFF5A4D47), width: 2.0),
              left: BorderSide(color: Color(0xFF5A4D47), width: 2.0),
              right: BorderSide(color: Color(0xFF5A4D47), width: 2.0),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
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
                  const SizedBox(height: 14),

                  // Cultural Photo Banner if available
                  if (discovery.imageUrl != null) ...[
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF5A4D47),
                          width: 1.6,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          discovery.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              discovery.category.emoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Category & Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: discovery.category.color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF5A4D47),
                            width: 1.4,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              discovery.category.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              discovery.category.label,
                              style: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E2420),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4F6E6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2E856E),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'Approved Discovery ✓',
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

                  // Title & Address
                  Text(
                    discovery.title,
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E2420),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          discovery.location,
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5A4D47),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Description Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF5A4D47),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About this Cultural Gem',
                          style: GoogleFonts.fredoka(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E2420),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          discovery.description,
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            height: 1.4,
                            color: const Color(0xFF5A4D47),
                          ),
                        ),
                        if (discovery.culturalSignificance != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF6D1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2C46E),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '💡',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    discovery.culturalSignificance!,
                                    style: GoogleFonts.nunito(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF5A4D47),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Open External Directions Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openExternalDirections(discovery);
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: Text(
                        'Open in Google Maps / Navigation',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                            color: Color(0xFF336E67),
                            width: 1.8,
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Explicitly Labeled Development Canvas Map (Fallback / Demo Preview)
  // ---------------------------------------------------------------------------
  Widget _buildDevelopmentCanvasMap() {
    return Stack(
      children: [
        // Interactive Pannable Canvas
        InteractiveViewer(
          minScale: 0.8,
          maxScale: 2.5,
          boundaryMargin: const EdgeInsets.all(400),
          constrained: false,
          child: SizedBox(
            width: 1200,
            height: 1200,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(1200, 1200),
                  painter: _SibuCulturalDistrictPainter(),
                ),
                ..._buildCanvasPins(),
              ],
            ),
          ),
        ),

        // Development Mode Banner Pill
        Positioned(
          top: 156,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0D1).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2C46E), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⚙️', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Canvas View (Toggle to Google Map above when API key is active)',
                    style: GoogleFonts.nunito(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7A6014),
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

  List<Widget> _buildCanvasPins() {
    final Map<String, Offset> canvasCoords = const {
      'd1': Offset(0.38, 0.44),
      'd2': Offset(0.68, 0.52),
      'd3': Offset(0.78, 0.28),
      'd4': Offset(0.24, 0.62),
      'd5': Offset(0.32, 0.76),
      'd6': Offset(0.52, 0.36),
    };

    return _filteredDiscoveries.map((d) {
      final offset = canvasCoords[d.id] ?? const Offset(0.5, 0.5);
      final posX = offset.dx * 1200.0;
      final posY = offset.dy * 1200.0;
      final isSelected = _selectedDiscovery?.id == d.id;

      return Positioned(
        left: posX - 24,
        top: posY - 48,
        child: GestureDetector(
          onTap: () {
            // Tapping canvas pin pops up the details card!
            setState(() => _selectedDiscovery = d);
          },
          child: AnimatedScale(
            scale: isSelected ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: d.category.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.coral : const Color(0xFF5A4D47),
                  width: isSelected ? 2.5 : 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, 3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  d.category.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

// -----------------------------------------------------------------------------
// Sibu Cultural District Painter (Offline Canvas Preview)
// -----------------------------------------------------------------------------
class _SibuCulturalDistrictPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final landPaint = Paint()..color = const Color(0xFFF9F3EA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), landPaint);

    final riverPaint = Paint()..color = const Color(0xFFD6F2FB);
    final riverPath = Path()
      ..moveTo(0, 850)
      ..cubicTo(250, 880, 360, 960, 520, 1020)
      ..cubicTo(700, 1090, 880, 1140, 1200, 1180)
      ..lineTo(1200, 1200)
      ..lineTo(0, 1200)
      ..close();
    canvas.drawPath(riverPath, riverPaint);

    final roadCasingPaint = Paint()
      ..color = const Color(0xFFDCD2C5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28.0
      ..strokeCap = StrokeCap.round;

    final roadFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22.0
      ..strokeCap = StrokeCap.round;

    final roads = [
      Path()
        ..moveTo(100, 420)
        ..cubicTo(350, 440, 550, 480, 1100, 440),
      Path()
        ..moveTo(220, 120)
        ..cubicTo(320, 350, 420, 600, 400, 950),
      Path()
        ..moveTo(120, 820)
        ..cubicTo(450, 840, 800, 920, 1100, 980),
      Path()
        ..moveTo(600, 100)
        ..cubicTo(640, 400, 680, 750, 750, 1000),
    ];

    for (final r in roads) {
      canvas.drawPath(r, roadCasingPaint);
      canvas.drawPath(r, roadFillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
