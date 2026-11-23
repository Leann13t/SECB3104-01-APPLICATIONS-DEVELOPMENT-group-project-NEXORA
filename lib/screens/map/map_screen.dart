import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  CulturalCategory? _selectedCategory;
  Discovery? _selectedDiscovery;
  String _searchQuery = '';

  bool _usePrototypeMap = false;
  bool _mapReady = false;

  // Interactive Prototype Map Pan & Zoom states
  Offset _mapPanOffset = Offset.zero;
  double _prototypeMapScale = 1.0;

  // Start centered in Johor Bahru, but show a user marker only after GPS succeeds.
  LatLng _liveLocation = const LatLng(1.4927, 103.7414);
  String _locationStatusText = 'Finding your location...';
  bool _isLocatingLiveGps = false;
  bool _hasLiveLocation = false;

  // Supabase community discoveries (strictly approved only!)
  List<Discovery> _discoveries = Discovery.placeholderDiscoveries;

  // Hunt proximity feature
  bool _isNearHuntLocation = false;
  CulturalCreature? _nearbyCreature;
  final Set<String> _collectedCreatureIds = {
    'c_taiyaki',
    'c_maneki',
    'c_burger',
    'c_bao',
    'c_elephant',
    'c_owl',
  };
  final Set<String> _bookmarkedDiscoveryIds = {};

  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    // Default to the first local discovery in Johor, Malaysia
    _selectedDiscovery =
        widget.initialSelectedDiscovery ??
        _discoveries.firstWhere(
          (d) => d.id == 'd_johor_heritage',
          orElse: () => _discoveries.first,
        );

    _detectLiveGpsLocation();
    _fetchApprovedSupabaseDiscoveries();
    _initUserCollectiblesFromSupabase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Real-Time Live GPS Location Detection (Johor, Malaysia)
  // Queries real device sensors via Geolocator.
  // ---------------------------------------------------------------------------
  Future<void> _detectLiveGpsLocation() async {
    if (mounted) {
      setState(() {
        _isLocatingLiveGps = true;
        _locationStatusText = 'Finding your location...';
      });
    }
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationStatusText = 'Location services are turned off';
            _isLocatingLiveGps = false;
            _hasLiveLocation = false;
          });
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationStatusText = permission == LocationPermission.deniedForever
                ? 'Location permission is disabled in settings'
                : 'Location permission denied';
            _isLocatingLiveGps = false;
            _hasLiveLocation = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _liveLocation = LatLng(position.latitude, position.longitude);
          _locationStatusText =
              'Live location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _isLocatingLiveGps = false;
          _hasLiveLocation = true;
        });

        if (!_usePrototypeMap && _mapReady) {
          _mapController.move(_liveLocation, 16.0);
        }
      }
    } catch (e) {
      debugPrint('Live GPS error: $e');
      if (mounted) {
        setState(() {
          _locationStatusText = 'Unable to get your location';
          _isLocatingLiveGps = false;
          _hasLiveLocation = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Supabase Data Fetching: Strictly Approved Records Only (is_approved == true)
  // ---------------------------------------------------------------------------
  Future<void> _fetchApprovedSupabaseDiscoveries() async {
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
          loaded.add(Discovery.fromMap(row));
        }

        if (loaded.isNotEmpty) {
          setState(() {
            _discoveries = loaded;
          });
        }
      }
    } catch (e) {
      debugPrint('Supabase discovery query note (using curated dataset): $e');
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
          final ids = response
              .map((r) => r['collectible_id'].toString())
              .toSet();
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
          discovery.location.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          discovery.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Map Markers
  // ---------------------------------------------------------------------------
  List<Marker> _buildMapMarkers() {
    final markers = <Marker>[];

    for (final discovery in _filteredDiscoveries) {
      final lat = discovery.latitude ?? _liveLocation.latitude;
      final lng = discovery.longitude ?? _liveLocation.longitude;

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 44,
          height: 48,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedDiscovery = discovery);
              _centerOnLocation(lat, lng);
            },
            child: Icon(
              Icons.location_on_rounded,
              color: discovery.category.borderColor,
              size: 42,
            ),
          ),
        ),
      );
    }

    if (_hasLiveLocation) {
      markers.add(
        Marker(
          point: _liveLocation,
          width: 42,
          height: 42,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x333B82F6),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3B82F6), width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.my_location_rounded,
                color: Color(0xFF2563EB),
                size: 22,
              ),
            ),
          ),
        ),
      );
    }

    if (_isNearHuntLocation && _nearbyCreature != null) {
      markers.add(
        Marker(
          point: LatLng(_nearbyCreature!.latitude, _nearbyCreature!.longitude),
          width: 42,
          height: 42,
          child: GestureDetector(
            onTap: () => _showHuntEncounterModal(_nearbyCreature!),
            child: const Icon(
              Icons.pets_rounded,
              color: Color(0xFFD98BA8),
              size: 38,
            ),
          ),
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
    if (!_usePrototypeMap && _mapReady) {
      _mapController.move(LatLng(lat, lng), zoom);
    }
  }

  void _zoomIn() {
    if (_usePrototypeMap) {
      setState(
        () => _prototypeMapScale = (_prototypeMapScale + 0.2).clamp(0.7, 2.5),
      );
    } else if (_mapReady) {
      setState(() => _currentZoom = (_currentZoom + 1).clamp(3.0, 20.0));
      _mapController.move(_mapController.camera.center, _currentZoom);
    }
  }

  void _zoomOut() {
    if (_usePrototypeMap) {
      setState(
        () => _prototypeMapScale = (_prototypeMapScale - 0.2).clamp(0.7, 2.5),
      );
    } else if (_mapReady) {
      setState(() => _currentZoom = (_currentZoom - 1).clamp(3.0, 20.0));
      _mapController.move(_mapController.camera.center, _currentZoom);
    }
  }

  Future<void> _recenterToCurrentLocation() async {
    await _detectLiveGpsLocation();
    if (!mounted) return;

    setState(() {
      _mapPanOffset = Offset.zero;
      _prototypeMapScale = 1.0;
    });

    if (!_usePrototypeMap && _mapReady && _hasLiveLocation) {
      _currentZoom = 16.0;
      _mapController.move(_liveLocation, _currentZoom);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _hasLiveLocation
              ? 'Map centered on your live location'
              : _locationStatusText,
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openExternalDirections(Discovery discovery) async {
    final lat = discovery.latitude ?? _liveLocation.latitude;
    final lng = discovery.longitude ?? _liveLocation.longitude;
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
            content: Text('Destination: ${discovery.title} ($lat, $lng)'),
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
  // Cultural Hunt Proximity Encounter (matching Image 3)
  // (Zero emojis, empty image link slot ready for user's insert image)
  // ---------------------------------------------------------------------------
  void _triggerHuntProximitySimulation() {
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
          content: Text('${creature.name} is already in your Hunt collection'),
          backgroundColor: AppColors.gold,
        ),
      );
      return;
    }

    setState(() {
      _collectedCreatureIds.add(creature.id);
    });

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
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${creature.name} (${creature.country}) added to your collection',
          ),
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
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
              // Header Frame with Close Button (Image 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_outline_rounded,
                          color: Color(0xFFF39C12),
                          size: 22,
                        ),
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
                          border: Border.all(
                            color: const Color(0xFF5A4D47),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF5A4D47),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Illustration Box with empty image slot (Image 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  height: 175,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE4F8F3), Color(0xFFFFEFF4)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF5A4D47),
                      width: 1.6,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Vector architectural scenery
                      Positioned(
                        left: 14,
                        bottom: 12,
                        child: Opacity(
                          opacity: 0.8,
                          child: const Icon(
                            Icons.landscape_rounded,
                            size: 48,
                            color: Color(0xFFB8D8D8),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 12,
                        child: Opacity(
                          opacity: 0.8,
                          child: const Icon(
                            Icons.temple_buddhist_rounded,
                            size: 44,
                            color: Color(0xFFE74C3C),
                          ),
                        ),
                      ),

                      // Rarity Badge (Image 3)
                      Positioned(
                        top: 12,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF5B041), Color(0xFFEB984E)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF5A4D47),
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFB87333),
                                offset: Offset(0, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            creature.rarity.label,
                            style: GoogleFonts.fredoka(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Center Character: Empty image slot ready for user image insert!
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF5A4D47),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18000000),
                              offset: Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: creature.imageUrl.trim().isNotEmpty
                              ? Image.network(
                                  creature.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _buildEmptyMascotSlot(),
                                )
                              : (creature.imageAsset.trim().isNotEmpty
                                    ? Image.asset(
                                        creature.imageAsset,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            _buildEmptyMascotSlot(),
                                      )
                                    : _buildEmptyMascotSlot()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Creature Name & Country Tag (Image 3)
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4F6E6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF40AA9F),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  creature.country,
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E5F57),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Highlight Box: "You reached an eligible Hunt location."
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0D1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2C46E),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFC07D1C),
                        size: 16,
                      ),
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

              // Action Buttons: Collect Now + View Hunt (Image 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Row(
                  children: [
                    // "Collect Now"
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
                            border: Border.all(
                              color: const Color(0xFFAC5E52),
                              width: 1.8,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFAC5E52),
                                offset: Offset(0, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Collect Now',
                              style: GoogleFonts.fredoka(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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
                          widget.onNavigateTab?.call(2);
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.8,
                            ),
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
                                const Icon(
                                  Icons.remove_red_eye_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
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

  Widget _buildEmptyMascotSlot() {
    return Container(
      color: const Color(0xFFF9F6F0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              size: 28,
              color: Color(0xFF8C7E75),
            ),
            const SizedBox(height: 2),
            Text(
              'Insert Image',
              style: GoogleFonts.fredoka(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C7E75),
              ),
            ),
          ],
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
          // 1. Interactive Prototype Map Body (Default) or Google Map (toggled)
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

                // Hunt Location Reached Banner (matching Image 3)
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
          // Positioned right above bottom navigation bar, fitting the scale!
          if (_selectedDiscovery != null)
            Positioned(
              left: 14,
              right: 14,
              bottom:
                  84, // Clean floating position right above bottom navigation
              child: _buildSelectedDiscoveryCard(_selectedDiscovery!),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Map Body: OpenStreetMap or offline illustrated map
  // ---------------------------------------------------------------------------
  Widget _buildMapBody() {
    if (_usePrototypeMap) {
      return _buildInteractivePrototypeMap();
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _liveLocation,
        initialZoom: _currentZoom,
        onMapReady: () {
          _mapReady = true;
          if (_hasLiveLocation) {
            _mapController.move(_liveLocation, _currentZoom);
          }
        },
        onTap: (_, _) {
          if (_selectedDiscovery != null) {
            setState(() => _selectedDiscovery = null);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.nexora',
        ),
        MarkerLayer(markers: _buildMapMarkers()),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap contributors',
              onTap: () => launchUrl(
                Uri.https('www.openstreetmap.org', '/copyright'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      ],
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
          // Logo pin icon
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
                  _isLocatingLiveGps
                      ? 'Locating your position...'
                      : _locationStatusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  content: Text('No new cultural notifications'),
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
                child: Icon(
                  Icons.notifications_outlined,
                  size: 18,
                  color: Color(0xFF5A4D47),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Profile Avatar Button
          GestureDetector(
            onTap: () {
              widget.onNavigateTab?.call(4);
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
                child: Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: Color(0xFF2E856E),
                ),
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
              child: const Icon(
                Icons.tune_rounded,
                size: 16,
                color: Color(0xFF5A4D47),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Category Pills Row (matching Image 1: Food, Heritage, Murals, Crafts)
  // Clean vector icons, zero emojis!
  // ---------------------------------------------------------------------------
  Widget _buildCategoryPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Food (cutlery icon)
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

          // Heritage (temple icon)
          _buildCategoryPill(
            label: 'Heritage',
            icon: Icons.account_balance_rounded,
            isSelected: _selectedCategory == CulturalCategory.heritage,
            bgColor: const Color(0xFFE3F7F2),
            borderColor: const Color(0xFF4A9188),
            textColor: const Color(0xFF1E5F57),
            onTap: () {
              setState(() {
                _selectedCategory =
                    _selectedCategory == CulturalCategory.heritage
                    ? null
                    : CulturalCategory.heritage;
              });
            },
          ),
          const SizedBox(width: 8),

          // Murals (palette icon)
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

          // Crafts (woven basket icon)
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
            color: isSelected
                ? const Color(0xFF5A4D47)
                : const Color(0xFFC9C1B8),
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
                color: isSelected
                    ? const Color(0xFF2E2420)
                    : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hunt Location Reached Banner (matching Image 3)
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
            child: Text(
              'Hunt location reached in ${creature.country}!',
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E5F57),
              ),
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
  // 5. Floating Controls: Recenter Live GPS, Zoom In, Zoom Out (Image 1)
  // ---------------------------------------------------------------------------
  Widget _buildFloatingControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hunt Proximity Test Action
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
              child: Icon(
                Icons.pets_rounded,
                color: Color(0xFFD98BA8),
                size: 20,
              ),
            ),
          ),
        ),

        // Recenter Live GPS Target Button (Image 1) - Reads live GPS in Johor, Malaysia!
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
            child: _isLocatingLiveGps
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
          ),
        ),
        const SizedBox(height: 8),

        // Zoom In (+) & Zoom Out (-) Cluster (Image 1)
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
                icon: const Icon(
                  Icons.remove,
                  size: 20,
                  color: Color(0xFF5A4D47),
                ),
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
  // Perfectly fits the scale and position right above bottom navigation!
  // Replaced emoji with empty image link slot ready for user image insert!
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
              // Photo Container: Empty Image Slot ready for user's insert image
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
                  child: discovery.hasCustomImage
                      ? Image.network(
                          discovery.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _buildEmptyPhotoSlot(discovery),
                        )
                      : _buildEmptyPhotoSlot(discovery),
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
                            isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            size: 22,
                            color: isBookmarked
                                ? AppColors.coral
                                : const Color(0xFF5A4D47),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Category Pill with vector icon (Image 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
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
                          Icon(
                            discovery.category.icon,
                            size: 11,
                            color: discovery.category.textColor,
                          ),
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
                        const Icon(
                          Icons.person_rounded,
                          size: 12,
                          color: AppColors.secondaryText,
                        ),
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

          // Action Buttons: "View Details ->" (Teal) and "Directions" (Coral) (Image 1)
          Row(
            children: [
              // "View Details ->"
              Expanded(
                child: GestureDetector(
                  onTap: () => _showDiscoveryDetailsModal(discovery),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF336E67),
                        width: 1.6,
                      ),
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
                        'View Details ->',
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
                      border: Border.all(
                        color: const Color(0xFFAC5E52),
                        width: 1.6,
                      ),
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
                          const Icon(
                            Icons.near_me_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
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
  // Empty Photo Slot Helper for Discovery Card (Empty image link slot)
  // ---------------------------------------------------------------------------
  Widget _buildEmptyPhotoSlot(Discovery discovery) {
    return Container(
      color: const Color(0xFFF7F2EC),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              size: 26,
              color: Color(0xFF8C7E75),
            ),
            const SizedBox(height: 3),
            Text(
              'Insert Image',
              style: GoogleFonts.fredoka(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C7E75),
              ),
            ),
          ],
        ),
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
            BoxShadow(
              color: Color(0x40000000),
              offset: Offset(0, -4),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          children: [
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F2EC),
                          border: Border.all(
                            color: const Color(0xFF5A4D47),
                            width: 1.8,
                          ),
                        ),
                        child: discovery.hasCustomImage
                            ? Image.network(
                                discovery.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _buildEmptyPhotoSlot(discovery),
                              )
                            : _buildEmptyPhotoSlot(discovery),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Pill & Approved status
                    Row(
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
                              color: discovery.category.borderColor,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                discovery.category.icon,
                                size: 14,
                                color: discovery.category.textColor,
                              ),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: Color(0xFF2E856E),
                              ),
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
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
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
                        const Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
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

                    if (discovery.culturalSignificance != null &&
                        discovery.culturalSignificance!.isNotEmpty) ...[
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
                          border: Border.all(
                            color: const Color(0xFF5A4D47),
                            width: 1.4,
                          ),
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

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F6F4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.4,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.explore_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
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
              'Map Display & Location Mode',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              title: Text(
                'Use offline illustrated map',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Switch off to use the online OpenStreetMap with live positioning',
                style: GoogleFonts.nunito(fontSize: 12),
              ),
              value: _usePrototypeMap,
              activeTrackColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _usePrototypeMap = val);
                Navigator.pop(ctx);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.my_location_rounded,
                color: AppColors.primary,
              ),
              title: Text(
                'Recenter on my live location',
                style: GoogleFonts.fredoka(fontSize: 14),
              ),
              onTap: () {
                _recenterToCurrentLocation();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // High-Fidelity Interactive Map (Matching Image 1 EXACTLY!)
  // Loads instantly, reliably on every device, without any API key or billing errors!
  // Displays live location in Johor, Malaysia with smooth panning and pinch zoom.
  // ---------------------------------------------------------------------------
  Widget _buildInteractivePrototypeMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (details) {
            setState(() {
              _mapPanOffset += details.delta;
            });
          },
          onTapDown: (details) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final tapPos = details.localPosition;

            // Hit test pins in map coordinates
            final pinPositions = _getPrototypePinPositions(size);
            for (final entry in pinPositions.entries) {
              final discovery = entry.key;
              final pinCenter = entry.value;

              final rect = Rect.fromCenter(
                center: pinCenter,
                width: 44,
                height: 44,
              );
              if (rect.contains(tapPos)) {
                setState(() {
                  _selectedDiscovery = discovery;
                });
                return;
              }
            }

            if (_selectedDiscovery != null) {
              setState(() => _selectedDiscovery = null);
            }
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _HighFidelityPrototypeMapPainter(
              discoveries: _filteredDiscoveries,
              selectedDiscovery: _selectedDiscovery,
              isNearHunt: _isNearHuntLocation,
              nearbyCreature: _nearbyCreature,
              panOffset: _mapPanOffset,
              scale: _prototypeMapScale,
            ),
          ),
        );
      },
    );
  }

  Map<Discovery, Offset> _getPrototypePinPositions(Size size) {
    final Map<Discovery, Offset> map = {};
    final cx = size.width * 0.5 + _mapPanOffset.dx;
    final cy = size.height * 0.46 + _mapPanOffset.dy;

    final offsets = [
      Offset(
        cx - 96 * _prototypeMapScale,
        cy - 90 * _prototypeMapScale,
      ), // 1. Food
      Offset(
        cx - 120 * _prototypeMapScale,
        cy - 38 * _prototypeMapScale,
      ), // 2. Heritage (Tan Hiok Nee)
      Offset(
        cx - 125 * _prototypeMapScale,
        cy + 85 * _prototypeMapScale,
      ), // 3. Murals (Pasar Karat)
      Offset(
        cx - 12 * _prototypeMapScale,
        cy - 80 * _prototypeMapScale,
      ), // 4. Crafts (Kompleks Kraf)
      Offset(
        cx + 78 * _prototypeMapScale,
        cy - 98 * _prototypeMapScale,
      ), // 5. Heritage
      Offset(
        cx + 86 * _prototypeMapScale,
        cy - 18 * _prototypeMapScale,
      ), // 6. Crafts
      Offset(
        cx + 52 * _prototypeMapScale,
        cy + 70 * _prototypeMapScale,
      ), // 7. Food
      Offset(
        cx + 20 * _prototypeMapScale,
        cy + 12 * _prototypeMapScale,
      ), // 8. Colosseum
    ];

    for (
      int i = 0;
      i < _filteredDiscoveries.length && i < offsets.length;
      i++
    ) {
      map[_filteredDiscoveries[i]] = offsets[i];
    }
    return map;
  }
}

// -----------------------------------------------------------------------------
// High-Fidelity Prototype Map Painter (Matching Image 1 EXACTLY!)
// Zero emojis, beautiful cartographic pastel streets, river/waterway,
// cultural pins, and live location blue dot in Johor, Malaysia!
// -----------------------------------------------------------------------------
class _HighFidelityPrototypeMapPainter extends CustomPainter {
  final List<Discovery> discoveries;
  final Discovery? selectedDiscovery;
  final bool isNearHunt;
  final CulturalCreature? nearbyCreature;
  final Offset panOffset;
  final double scale;

  _HighFidelityPrototypeMapPainter({
    required this.discoveries,
    required this.selectedDiscovery,
    required this.isNearHunt,
    required this.nearbyCreature,
    required this.panOffset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5 + panOffset.dx;
    final cy = size.height * 0.46 + panOffset.dy;

    // 1. Warm cream base terrain (#F6F3EB)
    final bgPaint = Paint()..color = const Color(0xFFF6F3EB);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. City Blocks: Soft pastel green parks and plaza blocks (matching Image 1)
    final parkPaint = Paint()
      ..color = const Color(0xFFE9F4E5)
      ..style = PaintingStyle.fill;

    final parkBlocks = [
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - 160 * scale,
          cy - 180 * scale,
          120 * scale,
          70 * scale,
        ),
        const Radius.circular(8),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx + 40 * scale,
          cy - 190 * scale,
          130 * scale,
          65 * scale,
        ),
        const Radius.circular(8),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - 180 * scale,
          cy + 30 * scale,
          110 * scale,
          85 * scale,
        ),
        const Radius.circular(8),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx + 60 * scale,
          cy + 40 * scale,
          120 * scale,
          75 * scale,
        ),
        const Radius.circular(8),
      ),
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - 40 * scale,
          cy - 140 * scale,
          70 * scale,
          45 * scale,
        ),
        const Radius.circular(6),
      ),
    ];
    for (final b in parkBlocks) {
      canvas.drawRRect(b, parkPaint);
    }

    // 3. Illustrated Roads Grid (Pale yellow / white with soft borders)
    final roadBorderPaint = Paint()
      ..color = const Color(0xFFE4DFD6)
      ..strokeWidth = 14 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 11 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roads = [
      Path()
        ..moveTo(cx - 220 * scale, cy - 90 * scale)
        ..lineTo(cx + 220 * scale, cy - 100 * scale),
      Path()
        ..moveTo(cx - 220 * scale, cy + 60 * scale)
        ..lineTo(cx + 220 * scale, cy + 50 * scale),
      Path()
        ..moveTo(cx - 220 * scale, cy - 10 * scale)
        ..lineTo(cx + 220 * scale, cy - 10 * scale),
      Path()
        ..moveTo(cx - 100 * scale, cy - 220 * scale)
        ..lineTo(cx - 90 * scale, cy + 220 * scale),
      Path()
        ..moveTo(cx + 70 * scale, cy - 220 * scale)
        ..lineTo(cx + 80 * scale, cy + 220 * scale),
      Path()
        ..moveTo(cx - 10 * scale, cy - 220 * scale)
        ..lineTo(cx - 10 * scale, cy + 220 * scale),
      Path()
        ..moveTo(cx - 180 * scale, cy - 200 * scale)
        ..lineTo(cx + 180 * scale, cy + 180 * scale),
      Path()
        ..moveTo(cx + 180 * scale, cy - 180 * scale)
        ..lineTo(cx - 160 * scale, cy + 180 * scale),
    ];

    for (final r in roads) {
      canvas.drawPath(r, roadBorderPaint);
      canvas.drawPath(r, roadPaint);
    }

    // 4. River / Waterway - Beautiful flowing blue water (Image 1)
    final riverShorePaint = Paint()
      ..color = const Color(0xFF7CBCE6)
      ..strokeWidth = 32 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverWaterPaint = Paint()
      ..color = const Color(0xFF98D4F7)
      ..strokeWidth = 28 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(cx - 220 * scale, cy - 70 * scale)
      ..cubicTo(
        cx - 130 * scale,
        cy - 60 * scale,
        cx - 60 * scale,
        cy - 20 * scale,
        cx - 20 * scale,
        cy + 10 * scale,
      )
      ..cubicTo(
        cx + 20 * scale,
        cy + 40 * scale,
        cx + 80 * scale,
        cy + 110 * scale,
        cx + 220 * scale,
        cy + 130 * scale,
      );

    canvas.drawPath(riverPath, riverShorePaint);
    canvas.drawPath(riverPath, riverWaterPaint);

    // River bridges
    final bridgePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8 * scale
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - 110 * scale, cy - 45 * scale),
      Offset(cx - 95 * scale, cy - 75 * scale),
      bridgePaint,
    );
    canvas.drawLine(
      Offset(cx + 40 * scale, cy + 50 * scale),
      Offset(cx + 60 * scale, cy + 80 * scale),
      bridgePaint,
    );

    // 5. Illustrated St. Peter's / Sultan Abu Bakar Architectural Dome in Background (Image 1)
    final domeCenter = Offset(cx + 115 * scale, cy - 65 * scale);
    final domePaint = Paint()
      ..color = const Color(0xFF7FA79E).withValues(alpha: 0.6)
      ..strokeWidth = 1.4 * scale
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCenter(
        center: domeCenter,
        width: 34 * scale,
        height: 38 * scale,
      ),
      3.14,
      3.14,
      false,
      domePaint,
    );
    canvas.drawLine(
      Offset(domeCenter.dx - 22 * scale, domeCenter.dy + 8 * scale),
      Offset(domeCenter.dx + 22 * scale, domeCenter.dy + 8 * scale),
      domePaint,
    );
    canvas.drawCircle(
      Offset(domeCenter.dx, domeCenter.dy - 22 * scale),
      2.5 * scale,
      domePaint,
    );

    // 6. User's Live Location (Vibrant Blue Dot with Dual Concentric Pulses in Johor - Image 1)
    final userCenter = Offset(cx - 10 * scale, cy + 2 * scale);

    // Outer soft blue pulse (radius 36)
    final outerPulsePaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userCenter, 36 * scale, outerPulsePaint);

    // Mid blue pulse (radius 22)
    final midPulsePaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userCenter, 22 * scale, midPulsePaint);

    // Center blue dot
    final centerDotPaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userCenter, 9 * scale, centerDotPaint);

    final centerDotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5 * scale
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(userCenter, 9 * scale, centerDotBorder);

    // 7. Draw Illustrated Teardrop Pins (matching Image 1 exactly!)
    final offsets = [
      Offset(cx - 96 * scale, cy - 90 * scale), // 1. Food
      Offset(cx - 120 * scale, cy - 38 * scale), // 2. Heritage (Tan Hiok Nee)
      Offset(cx - 125 * scale, cy + 85 * scale), // 3. Murals (Pasar Karat)
      Offset(cx - 12 * scale, cy - 80 * scale), // 4. Crafts (Kompleks Kraf)
      Offset(cx + 78 * scale, cy - 98 * scale), // 5. Heritage
      Offset(cx + 86 * scale, cy - 18 * scale), // 6. Crafts
      Offset(cx + 52 * scale, cy + 70 * scale), // 7. Food
      Offset(cx + 20 * scale, cy + 12 * scale), // 8. Colosseum
    ];

    for (int i = 0; i < discoveries.length && i < offsets.length; i++) {
      final d = discoveries[i];
      final isSelected = selectedDiscovery?.id == d.id;
      _drawTeardropPin(canvas, offsets[i], d.category, isSelected, scale);
    }

    // 8. Glowing Mascot Pin when Hunt Reached (Image 3)
    if (isNearHunt && nearbyCreature != null) {
      final huntPos = Offset(
        userCenter.dx + 42 * scale,
        userCenter.dy - 38 * scale,
      );

      final rayPaint = Paint()
        ..color = const Color(0xFFF39C12)
        ..strokeWidth = 2 * scale
        ..style = PaintingStyle.stroke;
      for (double angle = 0; angle < 6.28; angle += 0.8) {
        final start = Offset(
          huntPos.dx + 22 * scale * angle.abs(),
          huntPos.dy + 22 * scale * angle.abs(),
        );
        final end = Offset(
          huntPos.dx + 28 * scale * angle.abs(),
          huntPos.dy + 28 * scale * angle.abs(),
        );
        canvas.drawLine(start, end, rayPaint);
      }

      final auraPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(huntPos, 24 * scale, auraPaint);

      final catPinPaint = Paint()
        ..color = const Color(0xFFFFAB99)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(huntPos, 16 * scale, catPinPaint);

      final catPinBorder = Paint()
        ..color = const Color(0xFF5A4D47)
        ..strokeWidth = 2 * scale
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(huntPos, 16 * scale, catPinBorder);

      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.pets_rounded.codePoint),
          style: TextStyle(
            fontSize: 14 * scale,
            fontFamily: Icons.pets_rounded.fontFamily,
            package: Icons.pets_rounded.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        Offset(
          huntPos.dx - iconPainter.width / 2,
          huntPos.dy - iconPainter.height / 2,
        ),
      );
    }
  }

  void _drawTeardropPin(
    Canvas canvas,
    Offset center,
    CulturalCategory category,
    bool isSelected,
    double mapScale,
  ) {
    Color fillColor;
    IconData icon;

    switch (category) {
      case CulturalCategory.food:
        fillColor = const Color(0xFFFF6E55); // Coral
        icon = Icons.restaurant_rounded;
        break;
      case CulturalCategory.heritage:
        fillColor = const Color(0xFF4A9188); // Teal
        icon = Icons.account_balance_rounded;
        break;
      case CulturalCategory.murals:
        fillColor = const Color(0xFF9F72D9); // Purple
        icon = Icons.palette_rounded;
        break;
      case CulturalCategory.crafts:
        fillColor = const Color(0xFFE2B248); // Amber
        icon = Icons.shopping_basket_rounded;
        break;
    }

    final double pinRadius = (isSelected ? 18.0 : 15.0) * mapScale;

    // Pin Shadow
    canvas.drawCircle(
      Offset(center.dx, center.dy + 3 * mapScale),
      pinRadius,
      Paint()..color = const Color(0x24000000),
    );

    // Teardrop Pin Path
    final pinPath = Path();
    pinPath.addArc(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - 4 * mapScale),
        radius: pinRadius,
      ),
      0,
      3.14159 * 2,
    );
    pinPath.moveTo(center.dx - pinRadius * 0.7, center.dy);
    pinPath.lineTo(center.dx, center.dy + pinRadius * 1.2);
    pinPath.lineTo(center.dx + pinRadius * 0.7, center.dy);
    pinPath.close();

    // Fill
    canvas.drawPath(pinPath, Paint()..color = fillColor);

    // Border
    canvas.drawPath(
      pinPath,
      Paint()
        ..color = isSelected ? Colors.white : const Color(0xFF5A4D47)
        ..strokeWidth = (isSelected ? 2.4 : 1.6) * mapScale
        ..style = PaintingStyle.stroke,
    );

    // Inner Circle
    final iconCircleCenter = Offset(center.dx, center.dy - 4 * mapScale);
    canvas.drawCircle(
      iconCircleCenter,
      pinRadius * 0.72,
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    // White Category Icon Symbol
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: (isSelected ? 15.0 : 12.5) * mapScale,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        iconCircleCenter.dx - textPainter.width / 2,
        iconCircleCenter.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _HighFidelityPrototypeMapPainter oldDelegate) {
    return oldDelegate.selectedDiscovery != selectedDiscovery ||
        oldDelegate.discoveries != discoveries ||
        oldDelegate.isNearHunt != isNearHunt ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.scale != scale;
  }
}
