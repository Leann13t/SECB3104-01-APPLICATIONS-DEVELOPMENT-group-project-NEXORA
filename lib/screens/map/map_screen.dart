import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MapType;
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/creature_model.dart';
import '../../core/models/discovery_model.dart';
import '../../core/theme/app_colors.dart';

class MapScreen extends StatefulWidget {
  final Discovery? initialSelectedDiscovery;
  final void Function(int tabIndex)? onNavigateTab;

  const MapScreen({
    super.key,
    this.initialSelectedDiscovery,
    this.onNavigateTab,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  CulturalCategory? _selectedCategory;
  Discovery? _selectedDiscovery;
  String _searchQuery = '';

  // Mode: true for real GoogleMap, false for offline canvas preview
  bool _useGoogleMaps = true;
  bool _hasMapInitError = false;

  // Supabase community discoveries (strictly approved only!)
  List<Discovery> _discoveries = Discovery.placeholderDiscoveries;
  bool _isLoadingSupabaseData = false;
  bool _isUsingSupabaseData = false;

  // Hunt proximity feature (separate curated Hunt gamification)
  bool _isNearHuntLocation = false;
  CulturalCreature? _nearbyCreature;
  final Set<String> _collectedCreatureIds = {'c_taiyaki', 'c_maneki', 'c_burger', 'c_bao', 'c_elephant', 'c_owl'};
  final Set<String> _bookmarkedDiscoveryIds = {};

  // Current camera center: Rome Colosseum by default, with quick global jumps
  static const LatLng _defaultCenter = LatLng(41.8902, 12.4922); // Colosseum, Rome
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _selectedDiscovery = widget.initialSelectedDiscovery;
    _fetchApprovedSupabaseDiscoveries();
    _initUserCollectiblesFromSupabase();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Supabase Data Fetching: Strictly Approved Records Only (is_approved == true)
  // ---------------------------------------------------------------------------
  Future<void> _fetchApprovedSupabaseDiscoveries() async {
    setState(() => _isLoadingSupabaseData = true);
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('discoveries')
          .select()
          .eq('is_approved', true) // Rule: Never display pending or rejected contributions publicly!
          .timeout(const Duration(seconds: 4));

      if (response.isNotEmpty && mounted) {
        final List<Discovery> loaded = [];
        for (final row in response) {
          loaded.add(Discovery.fromMap(row));
        }

        if (loaded.isNotEmpty) {
          setState(() {
            _discoveries = loaded;
            _isUsingSupabaseData = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Supabase discovery query note (using global placeholder data): $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSupabaseData = false);
      }
    }
  }

  Future<void> _initUserCollectiblesFromSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('user_collectibles')
            .select('collectible_id')
            .eq('user_id', user.id);

        if (response.isNotEmpty && mounted) {
          final ids = response.map((r) => r['collectible_id'].toString()).toSet();
          setState(() {
            _collectedCreatureIds.addAll(ids);
          });
        }
      }
    } catch (e) {
      debugPrint('User collectibles fetch note: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Filtered Discoveries
  // ---------------------------------------------------------------------------
  List<Discovery> get _filteredDiscoveries {
    return _discoveries.where((discovery) {
      final matchesCategory =
          _selectedCategory == null || discovery.category == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          discovery.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          discovery.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          discovery.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Google Map Markers Generation
  // Community discoveries get category-specific markers
  // ---------------------------------------------------------------------------
  Set<Marker> _buildGoogleMapMarkers() {
    final markers = <Marker>{};

    for (final discovery in _filteredDiscoveries) {
      final lat = discovery.latitude ?? 41.8902;
      final lng = discovery.longitude ?? 12.4922;
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

      markers.add(
        Marker(
          markerId: MarkerId(discovery.id),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow.noText,
          zIndexInt: isSelected ? 3 : 1,
          onTap: () {
            setState(() {
              _selectedDiscovery = discovery;
            });
            _centerOnLocation(lat, lng);
          },
        ),
      );
    }

    // If an eligible Hunt location is active/nearby, add the special Hunt pin!
    if (_isNearHuntLocation && _nearbyCreature != null) {
      markers.add(
        Marker(
          markerId: MarkerId('hunt_${_nearbyCreature!.id}'),
          position: LatLng(_nearbyCreature!.latitude, _nearbyCreature!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
          zIndexInt: 5,
          onTap: () {
            _showHuntEncounterModal(_nearbyCreature!);
          },
        ),
      );
    }

    return markers;
  }

  // ---------------------------------------------------------------------------
  // Camera & Navigation Actions
  // ---------------------------------------------------------------------------
  void _centerOnLocation(double lat, double lng, {double zoom = 16.0}) {
    _currentZoom = zoom;
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: zoom),
        ),
      );
    }
  }

  void _zoomIn() {
    setState(() => _currentZoom = (_currentZoom + 1).clamp(3.0, 20.0));
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    setState(() => _currentZoom = (_currentZoom - 1).clamp(3.0, 20.0));
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _recenterToCurrentLocation() {
    // Center to Rome Colosseum or active selected item
    final target = _selectedDiscovery != null
        ? LatLng(_selectedDiscovery!.latitude ?? 41.8902, _selectedDiscovery!.longitude ?? 12.4922)
        : _defaultCenter;
    _centerOnLocation(target.latitude, target.longitude, zoom: 15.5);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Map centered on cultural discovery location'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openExternalDirections(Discovery discovery) async {
    final lat = discovery.latitude ?? 41.8902;
    final lng = discovery.longitude ?? 12.4922;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Directions to ${discovery.title}: $lat, $lng'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Cultural Hunt Proximity Encounter (Gamification Feature 2)
  // ---------------------------------------------------------------------------
  void _triggerHuntProximitySimulation() {
    // Select Taiyaki Spirit (matching Image 2) or next available collectible
    final creature = CulturalCreature.curatedGlobalCreatures.first;
    setState(() {
      _isNearHuntLocation = true;
      _nearbyCreature = creature;
    });

    _showHuntEncounterModal(creature);
  }

  Future<void> _collectCreature(CulturalCreature creature) async {
    if (_collectedCreatureIds.contains(creature.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ ${creature.name} is already in your Hunt collection!'),
          backgroundColor: AppColors.gold,
        ),
      );
      return;
    }

    setState(() {
      _collectedCreatureIds.add(creature.id);
    });

    // Save to Supabase user_collectibles table if user is signed in
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('user_collectibles').insert({
          'user_id': user.id,
          'collectible_id': creature.id,
          'collected_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Supabase user_collectibles insert note: $e');
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // close modal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 ${creature.name} (${creature.country}) added to your collection!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showHuntEncounterModal(CulturalCreature creature) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF5A4D47), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, 8),
                blurRadius: 20,
              ),
              BoxShadow(
                color: Color(0xFFD6CBC3),
                offset: Offset(0, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cherry Blossom Header Frame with Close Button (matching Image 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🌸', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          'Cultural Treasure Found!',
                          style: GoogleFonts.fredoka(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E2420),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3ECE6),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF5A4D47), width: 1.2),
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF5A4D47)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Cute Anime Illustration Box with Mount Fuji, Torii & Sakura (matching Image 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE4F8F3), Color(0xFFFFEFF4)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF5A4D47), width: 1.6),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background Sakura and Mount Fuji decorations
                      Positioned(
                        left: 14,
                        bottom: 12,
                        child: Opacity(
                          opacity: 0.85,
                          child: Text('🗻', style: TextStyle(fontSize: 48)),
                        ),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 12,
                        child: Opacity(
                          opacity: 0.85,
                          child: Text('⛩️', style: TextStyle(fontSize: 44)),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 14,
                        child: Text('🌸', style: TextStyle(fontSize: 22)),
                      ),
                      Positioned(
                        top: 10,
                        right: 14,
                        child: Text('✨', style: TextStyle(fontSize: 20)),
                      ),

                      // Rarity Crown Badge (Image 2)
                      Positioned(
                        top: 12,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF5B041), Color(0xFFEB984E)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF5A4D47), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFB87333),
                                offset: Offset(0, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('👑', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                creature.rarity.label,
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

                      // Cute Center Mascot Illustration (Taiyaki Spirit)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF5A4D47), width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x18000000),
                                  offset: Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                creature.emoji,
                                style: const TextStyle(fontSize: 46),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('✨', style: TextStyle(fontSize: 12)),
                              SizedBox(width: 4),
                              Text('🌸', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Creature Name & Country Tag (matching Image 2)
              Text(
                creature.name,
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E2420),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4F6E6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF40AA9F), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(creature.countryFlag, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      creature.country,
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E5F57),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Highlight Box: "You reached an eligible Hunt location."
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0D1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2C46E), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFFC07D1C), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'You reached an eligible Hunt location.',
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7A540E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Lore Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  creature.lore,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                    height: 1.35,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons: Collect Now + View Hunt (matching Image 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Row(
                  children: [
                    // "✦ Collect Now"
                    Expanded(
                      flex: 6,
                      child: GestureDetector(
                        onTap: () => _collectCreature(creature),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9E8A), Color(0xFFFF6E55)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFAC5E52), width: 1.8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFAC5E52),
                                offset: Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('✦', style: TextStyle(color: Colors.white, fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  'Collect Now',
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
                    ),
                    const SizedBox(width: 10),
                    // "View Hunt"
                    Expanded(
                      flex: 5,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          widget.onNavigateTab?.call(2); // Switch to Cultural Hunt tab!
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary, width: 1.8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFD6CBC3),
                                offset: Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.remove_red_eye_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'View Hunt',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build Method
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Interactive Map Body (Google Map with fallback to Canvas Map)
          Positioned.fill(child: _buildMapBody()),

          // 2. Top Header & Search Bar Overlay (matching Image 1)
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 6),
                _buildSearchBar(),
                const SizedBox(height: 6),
                _buildCategoryPills(),

                // Hunt Location Reached Banner (matching Image 2)
                if (_isNearHuntLocation && _nearbyCreature != null)
                  _buildHuntLocationReachedBanner(_nearbyCreature!),
              ],
            ),
          ),

          // 3. Floating Right-Side Controls: Target, Zoom In, Zoom Out (Image 1)
          Positioned(
            right: 16,
            bottom: _selectedDiscovery != null ? 245 : 96,
            child: _buildFloatingControls(),
          ),

          // 4. Pop-up Cultural Discovery Preview Card (matching Image 1)
          if (_selectedDiscovery != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 84, // Clean floating position above bottom navigation bar
              child: _buildSelectedDiscoveryCard(_selectedDiscovery!),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Map Body: Google Map or Custom Canvas Map
  // ---------------------------------------------------------------------------
  Widget _buildMapBody() {
    if (_hasMapInitError || !_useGoogleMaps) {
      return _buildDevelopmentCanvasMap();
    }

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _defaultCenter,
        zoom: 14.5,
      ),
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
        if (_selectedDiscovery != null) {
          setState(() => _selectedDiscovery = null);
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Top Header (matching Image 1: LoraGuide, Subtitle, Notification, Profile)
  // ---------------------------------------------------------------------------
  Widget _buildTopHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
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
          // Logo pin icon (green circle with cultural temple pin)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lightMint,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.temple_buddhist_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title & Subtitle: "LoraGuide - Discover culture. Explore the world."
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LoraGuide',
                  style: GoogleFonts.fredoka(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                  ),
                ),
                Text(
                  'Discover culture. Explore the world.',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Notification Bell
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔔 No new cultural notifications'),
                  backgroundColor: AppColors.primary,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0D1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF5A4D47), width: 1.4),
              ),
              child: const Center(
                child: Icon(Icons.notifications_outlined, size: 18, color: Color(0xFF5A4D47)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Profile Avatar Button
          GestureDetector(
            onTap: () {
              widget.onNavigateTab?.call(4); // Switch to Profile
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFD4F6E6),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF5A4D47), width: 1.4),
              ),
              child: const Center(
                child: Icon(Icons.person_rounded, size: 18, color: Color(0xFF2E856E)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Search Bar (matching Image 1)
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF5A4D47), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD6CBC3),
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, color: Color(0xFF5A4D47), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
              ),
              decoration: InputDecoration(
                hintText: 'Search places, food, heritage...',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9E9590),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          // Filter toggle button (sliders icon, matching Image 1)
          GestureDetector(
            onTap: _showFilterOptionsModal,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECE6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF5A4D47), width: 1.2),
              ),
              child: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF5A4D47)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Category Pills Row (matching Image 1: Food, Heritage, Murals, Crafts)
  // ---------------------------------------------------------------------------
  Widget _buildCategoryPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // All Button
          _buildCategoryPill(
            label: 'All (${_discoveries.length})',
            icon: Icons.public_rounded,
            isSelected: _selectedCategory == null,
            bgColor: const Color(0xFFE8F6F4),
            borderColor: AppColors.primary,
            textColor: AppColors.primary,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          const SizedBox(width: 8),

          // Food
          _buildCategoryPill(
            label: 'Food',
            icon: Icons.restaurant_rounded,
            isSelected: _selectedCategory == CulturalCategory.food,
            bgColor: const Color(0xFFFFECE8),
            borderColor: const Color(0xFFFF7A66),
            textColor: const Color(0xFFB52E1B),
            onTap: () {
              setState(() {
                _selectedCategory = _selectedCategory == CulturalCategory.food
                    ? null
                    : CulturalCategory.food;
              });
            },
          ),
          const SizedBox(width: 8),

          // Heritage
          _buildCategoryPill(
            label: 'Heritage',
            icon: Icons.account_balance_rounded,
            isSelected: _selectedCategory == CulturalCategory.heritage,
            bgColor: const Color(0xFFE3F7F2),
            borderColor: const Color(0xFF4A9188),
            textColor: const Color(0xFF1E5F57),
            onTap: () {
              setState(() {
                _selectedCategory = _selectedCategory == CulturalCategory.heritage
                    ? null
                    : CulturalCategory.heritage;
              });
            },
          ),
          const SizedBox(width: 8),

          // Murals
          _buildCategoryPill(
            label: 'Murals',
            icon: Icons.palette_rounded,
            isSelected: _selectedCategory == CulturalCategory.murals,
            bgColor: const Color(0xFFF3EBFF),
            borderColor: const Color(0xFF9F72D9),
            textColor: const Color(0xFF5A3194),
            onTap: () {
              setState(() {
                _selectedCategory = _selectedCategory == CulturalCategory.murals
                    ? null
                    : CulturalCategory.murals;
              });
            },
          ),
          const SizedBox(width: 8),

          // Crafts
          _buildCategoryPill(
            label: 'Crafts',
            icon: Icons.shopping_basket_rounded,
            isSelected: _selectedCategory == CulturalCategory.crafts,
            bgColor: const Color(0xFFFFF6DF),
            borderColor: const Color(0xFFE2B248),
            textColor: const Color(0xFF8C6409),
            onTap: () {
              setState(() {
                _selectedCategory = _selectedCategory == CulturalCategory.crafts
                    ? null
                    : CulturalCategory.crafts;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF5A4D47) : const Color(0xFFC9C1B8),
            width: isSelected ? 1.8 : 1.2,
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
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Icon(icon, size: 12, color: borderColor),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2E2420) : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hunt Location Reached Banner (matching Image 2)
  // ---------------------------------------------------------------------------
  Widget _buildHuntLocationReachedBanner(CulturalCreature creature) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD4F6E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E856E), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Color(0xFF8CCBB9),
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF2E856E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Hunt location reached!',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E5F57),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('✨', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showHuntEncounterModal(creature),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2E856E), width: 1.2),
              ),
              child: Text(
                'Open Encounter',
                style: GoogleFonts.fredoka(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E856E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Floating Controls: Recenter, Zoom In, Zoom Out, & Hunt Simulation (Image 1)
  // ---------------------------------------------------------------------------
  Widget _buildFloatingControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hunt Proximity Test Action (Allows testing the feature safely)
        GestureDetector(
          onTap: _triggerHuntProximitySimulation,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0ED),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFD6CBC3),
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Center(
              child: Text('🐱', style: TextStyle(fontSize: 20)),
            ),
          ),
        ),

        // Recenter Target Button
        GestureDetector(
          onTap: _recenterToCurrentLocation,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
              boxShadow: const [
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
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Zoom In (+) & Zoom Out (-) Cluster (matching Image 1)
        Container(
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFD6CBC3),
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 38),
                icon: const Icon(Icons.add, size: 20, color: Color(0xFF5A4D47)),
                onPressed: _zoomIn,
              ),
              Container(height: 1.2, color: const Color(0xFFE5DDD6)),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 38),
                icon: const Icon(Icons.remove, size: 20, color: Color(0xFF5A4D47)),
                onPressed: _zoomOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Selected Discovery Pop-up Card (matching Image 1)
  // ---------------------------------------------------------------------------
  Widget _buildSelectedDiscoveryCard(Discovery discovery) {
    final isBookmarked = _bookmarkedDiscoveryIds.contains(discovery.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            offset: Offset(0, 8),
            blurRadius: 18,
          ),
          BoxShadow(
            color: Color(0xFFD6CBC3),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle pill at the top of the card (Image 1)
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFBDB2A9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail (e.g. Colosseum photo from Image 1)
              Container(
                width: 90,
                height: 90,
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
                            child: Icon(
                              discovery.category.icon,
                              size: 32,
                              color: discovery.category.borderColor,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            discovery.category.icon,
                            size: 32,
                            color: discovery.category.borderColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Bookmark, Category Tag, Contributor, Description Snippet
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Bookmark Ribbon Button (matching Image 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            discovery.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.fredoka(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E2420),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isBookmarked) {
                                _bookmarkedDiscoveryIds.remove(discovery.id);
                              } else {
                                _bookmarkedDiscoveryIds.add(discovery.id);
                              }
                            });
                          },
                          child: Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                            size: 22,
                            color: isBookmarked ? AppColors.coral : const Color(0xFF5A4D47),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Category Pill with icon (Image 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: discovery.category.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: discovery.category.borderColor,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(discovery.category.icon, size: 11, color: discovery.category.textColor),
                          const SizedBox(width: 4),
                          Text(
                            discovery.category.label,
                            style: GoogleFonts.fredoka(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: discovery.category.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Contributor Line: "Contributed by Marco R." (Image 1)
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 12, color: AppColors.secondaryText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Contributed by ${discovery.contributor}',
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
                    const SizedBox(height: 4),

                    // Short Description
                    Text(
                      discovery.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4A4441),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons: "View Details →" (Teal) and "Directions" (Coral) (matching Image 1)
          Row(
            children: [
              // "View Details →"
              Expanded(
                child: GestureDetector(
                  onTap: () => _showDiscoveryDetailsModal(discovery),
                  child: Container(
                    height: 44,
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
                      child: Text(
                        'View Details →',
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // "Directions"
              Expanded(
                child: GestureDetector(
                  onTap: () => _openExternalDirections(discovery),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9E8A), Color(0xFFFF6E55)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFAC5E52), width: 1.6),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFAC5E52),
                          offset: Offset(0, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.near_me_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Directions',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
  // Discovery Details Modal Bottom Sheet
  // ---------------------------------------------------------------------------
  void _showDiscoveryDetailsModal(Discovery discovery) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF9F0),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Photo
                    if (discovery.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF5A4D47), width: 1.8),
                          ),
                          child: Image.network(
                            discovery.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: discovery.category.color,
                              child: Center(
                                child: Icon(discovery.category.icon, size: 64, color: discovery.category.borderColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Category Pill & Approved status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: discovery.category.color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: discovery.category.borderColor, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(discovery.category.icon, size: 14, color: discovery.category.textColor),
                              const SizedBox(width: 5),
                              Text(
                                discovery.category.label,
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: discovery.category.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4F6E6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF2E856E), width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF2E856E)),
                              const SizedBox(width: 4),
                              Text(
                                'Community Approved',
                                style: GoogleFonts.fredoka(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E5F57),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      discovery.title,
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Contributor & Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            discovery.location,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Contributed by ${discovery.contributor}',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description Box
                    Text(
                      'About this place',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      discovery.description,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF493C35),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cultural Significance Section
                    if (discovery.culturalSignificance != null && discovery.culturalSignificance!.isNotEmpty) ...[
                      Text(
                        'Cultural Significance',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF5A4D47), width: 1.4),
                        ),
                        child: Text(
                          discovery.culturalSignificance!,
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkBrown,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // GPS Coordinates Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F6F4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary, width: 1.4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.explore_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'GPS: ${discovery.latitude?.toStringAsFixed(4)}, ${discovery.longitude?.toStringAsFixed(4)}',
                            style: GoogleFonts.fredoka(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
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

  // ---------------------------------------------------------------------------
  // Filter Options Modal
  // ---------------------------------------------------------------------------
  void _showFilterOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF9F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Map Preferences',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              title: Text(
                'Use Real Google Maps',
                style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Toggle to Canvas Map for offline/low-bandwidth test mode',
                style: GoogleFonts.nunito(fontSize: 12),
              ),
              value: _useGoogleMaps,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _useGoogleMaps = val);
                Navigator.pop(ctx);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.explore_rounded, color: AppColors.primary),
              title: Text(
                'Jump to Rome Colosseum (Italy)',
                style: GoogleFonts.fredoka(fontSize: 14),
              ),
              onTap: () {
                _centerOnLocation(41.8902, 12.4922);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.ramen_dining_rounded, color: Color(0xFFFF6E55)),
              title: Text(
                'Jump to Tokyo Cultural District (Japan)',
                style: GoogleFonts.fredoka(fontSize: 14),
              ),
              onTap: () {
                _centerOnLocation(35.6655, 139.7708);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.temple_buddhist_rounded, color: Color(0xFF4A9188)),
              title: Text(
                'Jump to Sibu Heritage District (Malaysia)',
                style: GoogleFonts.fredoka(fontSize: 14),
              ),
              onTap: () {
                _centerOnLocation(2.2878, 111.8305);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Canvas Vector Map Preview (Reliable offline fallback matching Image 1)
  // ---------------------------------------------------------------------------
  Widget _buildDevelopmentCanvasMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _VectorDiscoveryMapPainter(
            discoveries: _filteredDiscoveries,
            selectedDiscovery: _selectedDiscovery,
            isNearHunt: _isNearHuntLocation,
            nearbyCreature: _nearbyCreature,
            onPinTapped: (d) {
              setState(() => _selectedDiscovery = d);
            },
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              // Check pin tap hit tests
              for (int i = 0; i < _filteredDiscoveries.length; i++) {
                final d = _filteredDiscoveries[i];
                final pinX = (width * 0.18 + (i * 70) % (width * 0.65));
                final pinY = (height * 0.28 + (i * 90) % (height * 0.45));
                final rect = Rect.fromCenter(center: Offset(pinX, pinY), width: 44, height: 44);

                if (rect.contains(details.localPosition)) {
                  setState(() => _selectedDiscovery = d);
                  return;
                }
              }

              // Dismiss card if tapped elsewhere on map
              if (_selectedDiscovery != null) {
                setState(() => _selectedDiscovery = null);
              }
            },
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Vector Discovery Map Painter (Matching Image 1 illustrated map)
// -----------------------------------------------------------------------------
class _VectorDiscoveryMapPainter extends CustomPainter {
  final List<Discovery> discoveries;
  final Discovery? selectedDiscovery;
  final bool isNearHunt;
  final CulturalCreature? nearbyCreature;
  final Function(Discovery) onPinTapped;

  _VectorDiscoveryMapPainter({
    required this.discoveries,
    required this.selectedDiscovery,
    required this.isNearHunt,
    required this.nearbyCreature,
    required this.onPinTapped,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Warm cream/mint map terrain base
    final bgPaint = Paint()..color = const Color(0xFFF9F5EC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Curving Blue River (as seen in Image 1)
    final riverPaint = Paint()
      ..color = const Color(0xFFC7EAFB)
      ..strokeWidth = 34
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.32,
        size.width * 0.55,
        size.height * 0.58,
        size.width,
        size.height * 0.48,
      );
    canvas.drawPath(riverPath, riverPaint);

    // 3. Illustrated Roads Grid
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFE2DCD4)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roads = [
      Path()..moveTo(0, size.height * 0.3) ..lineTo(size.width, size.height * 0.35),
      Path()..moveTo(0, size.height * 0.65) ..lineTo(size.width, size.height * 0.6),
      Path()..moveTo(size.width * 0.35, 0) ..lineTo(size.width * 0.32, size.height),
      Path()..moveTo(size.width * 0.72, 0) ..lineTo(size.width * 0.75, size.height),
    ];

    for (final r in roads) {
      canvas.drawPath(r, roadBorderPaint);
      canvas.drawPath(r, roadPaint);
    }

    // 4. User's Live Location (Blue Dot with soft accuracy circle - Image 1)
    final userCenter = Offset(size.width * 0.48, size.height * 0.48);
    final accuracyCirclePaint = Paint()
      ..color = const Color(0x332196F3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userCenter, 32, accuracyCirclePaint);

    final userDotPaint = Paint()
      ..color = const Color(0xFF1E88E5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userCenter, 9, userDotPaint);

    final userDotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(userCenter, 9, userDotBorder);

    // 5. Draw Cultural Pins on Map (matching Image 1)
    for (int i = 0; i < discoveries.length; i++) {
      final d = discoveries[i];
      final isSelected = selectedDiscovery?.id == d.id;
      final pinX = (size.width * 0.18 + (i * 70) % (size.width * 0.65));
      final pinY = (size.height * 0.28 + (i * 90) % (size.height * 0.45));

      _drawIllustratedPin(canvas, Offset(pinX, pinY), d.category, isSelected);
    }

    // 6. Draw Glowing Mascot Pin if Near Hunt Location (Image 2)
    if (isNearHunt && nearbyCreature != null) {
      final huntPinPos = Offset(userCenter.dx + 40, userCenter.dy - 35);

      // Glowing aura
      final glowPaint = Paint()
        ..color = const Color(0x66FFD54F)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(huntPinPos, 24, glowPaint);

      // Cute Cat Pin
      final catPinPaint = Paint()
        ..color = const Color(0xFFFFAB99)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(huntPinPos, 16, catPinPaint);

      final catPinBorder = Paint()
        ..color = const Color(0xFF5A4D47)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(huntPinPos, 16, catPinBorder);

      // Emoji
      final textPainter = TextPainter(
        text: TextSpan(
          text: nearbyCreature!.emoji,
          style: const TextStyle(fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(huntPinPos.dx - textPainter.width / 2, huntPinPos.dy - textPainter.height / 2),
      );
    }
  }

  void _drawIllustratedPin(Canvas canvas, Offset center, CulturalCategory category, bool isSelected) {
    Color fillColor;
    IconData icon;

    switch (category) {
      case CulturalCategory.food:
        fillColor = const Color(0xFFFF7A66);
        icon = Icons.restaurant_rounded;
        break;
      case CulturalCategory.heritage:
        fillColor = const Color(0xFF4A9188);
        icon = Icons.account_balance_rounded;
        break;
      case CulturalCategory.murals:
        fillColor = const Color(0xFF9F72D9);
        icon = Icons.palette_rounded;
        break;
      case CulturalCategory.crafts:
        fillColor = const Color(0xFFE2B248);
        icon = Icons.shopping_basket_rounded;
        break;
    }

    // Outer Shadow
    canvas.drawCircle(
      Offset(center.dx, center.dy + 3),
      isSelected ? 18 : 15,
      Paint()..color = const Color(0x22000000),
    );

    // Pin Body
    final pinPaint = Paint()..color = fillColor;
    canvas.drawCircle(center, isSelected ? 18 : 15, pinPaint);

    final borderPaint = Paint()
      ..color = isSelected ? Colors.white : const Color(0xFF5A4D47)
      ..strokeWidth = isSelected ? 2.5 : 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, isSelected ? 18 : 15, borderPaint);

    // Inner Symbol
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: isSelected ? 16 : 13,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _VectorDiscoveryMapPainter oldDelegate) {
    return oldDelegate.selectedDiscovery != selectedDiscovery ||
        oldDelegate.discoveries != discoveries ||
        oldDelegate.isNearHunt != isNearHunt;
  }
}
