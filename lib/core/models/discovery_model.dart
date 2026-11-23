import 'package:flutter/material.dart';

enum CulturalCategory {
  food,
  heritage,
  murals,
  crafts;

  String get label {
    switch (this) {
      case CulturalCategory.food:
        return 'Food';
      case CulturalCategory.heritage:
        return 'Heritage';
      case CulturalCategory.murals:
        return 'Murals';
      case CulturalCategory.crafts:
        return 'Crafts';
    }
  }

  IconData get icon {
    switch (this) {
      case CulturalCategory.food:
        return Icons.restaurant_rounded;
      case CulturalCategory.heritage:
        return Icons.account_balance_rounded;
      case CulturalCategory.murals:
        return Icons.palette_rounded;
      case CulturalCategory.crafts:
        return Icons.shopping_basket_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CulturalCategory.food:
        return const Color(0xFFFFECE8);
      case CulturalCategory.heritage:
        return const Color(0xFFE3F7F2);
      case CulturalCategory.murals:
        return const Color(0xFFF3EBFF);
      case CulturalCategory.crafts:
        return const Color(0xFFFFF6DF);
    }
  }

  Color get borderColor {
    switch (this) {
      case CulturalCategory.food:
        return const Color(0xFFFF7A66);
      case CulturalCategory.heritage:
        return const Color(0xFF4A9188);
      case CulturalCategory.murals:
        return const Color(0xFF9F72D9);
      case CulturalCategory.crafts:
        return const Color(0xFFE2B248);
    }
  }

  Color get textColor {
    switch (this) {
      case CulturalCategory.food:
        return const Color(0xFFB52E1B);
      case CulturalCategory.heritage:
        return const Color(0xFF1E5F57);
      case CulturalCategory.murals:
        return const Color(0xFF5A3194);
      case CulturalCategory.crafts:
        return const Color(0xFF8C6409);
    }
  }
}

class Discovery {
  final String id;
  final String title;
  final CulturalCategory category;
  final String location;
  final String description;
  final double? latitude;
  final double? longitude;
  final String imageUrl; // Empty image link ready for user image insertion
  final bool isApproved;
  final String contributor;
  final String? culturalSignificance;
  final bool isBookmarked;

  const Discovery({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.description,
    this.latitude,
    this.longitude,
    this.imageUrl = '', // Empty image link
    this.isApproved = true,
    this.contributor = 'Community Explorer',
    this.culturalSignificance,
    this.isBookmarked = false,
  });

  bool get hasCustomImage => imageUrl.trim().isNotEmpty;

  Discovery copyWith({
    String? id,
    String? title,
    CulturalCategory? category,
    String? location,
    String? description,
    double? latitude,
    double? longitude,
    String? imageUrl,
    bool? isApproved,
    String? contributor,
    String? culturalSignificance,
    bool? isBookmarked,
  }) {
    return Discovery(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      location: location ?? this.location,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      isApproved: isApproved ?? this.isApproved,
      contributor: contributor ?? this.contributor,
      culturalSignificance: culturalSignificance ?? this.culturalSignificance,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  factory Discovery.fromMap(Map<String, dynamic> map) {
    final catString = (map['category'] as String?)?.toLowerCase() ?? '';
    CulturalCategory cat = CulturalCategory.heritage;
    for (final c in CulturalCategory.values) {
      if (c.name.toLowerCase() == catString) {
        cat = c;
        break;
      }
    }

    return Discovery(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Cultural Gem',
      category: cat,
      location: map['location']?.toString() ?? 'Johor, Malaysia',
      description: map['description']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 1.4927,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 103.7414,
      imageUrl: map['image_url']?.toString() ?? '',
      isApproved: map['is_approved'] == true,
      contributor: map['contributor']?.toString() ?? 'Community Explorer',
      culturalSignificance: map['cultural_significance']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'location': location,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'is_approved': isApproved,
      'contributor': contributor,
      'cultural_significance': culturalSignificance,
    };
  }

  // Curated cultural discoveries with Johor, Malaysia local spots and global gems
  // (Zero emojis, empty image links ready for user image insertion)
  static List<Discovery> get placeholderDiscoveries => const [
    // 1. Johor Bahru, Malaysia (User's Live Location)
    Discovery(
      id: 'd_johor_heritage',
      title: 'Tan Hiok Nee Cultural Street',
      category: CulturalCategory.heritage,
      location: 'Jalan Tan Hiok Nee, Johor Bahru, Johor, Malaysia',
      description: 'Historic cultural lane in downtown Johor Bahru named after leader Tan Hiok Nee, featuring century-old bakeries, traditional Hainanese coffee shops, and pre-war Chinese shophouses.',
      latitude: 1.4578,
      longitude: 103.7644,
      imageUrl: '', // Empty image link ready for insert image
      isApproved: true,
      contributor: 'Wei Loon Tan',
      culturalSignificance: 'Center of Johor Bahru Chinese diaspora heritage and historical Ngee Heng Kongsi trade history along Sungai Segget.',
    ),
    // 2. Johor Bahru, Malaysia (Food)
    Discovery(
      id: 'd_johor_food',
      title: 'Restoran Hua Mui & Authentic Johor Laksa',
      category: CulturalCategory.food,
      location: 'Jalan Trus, Bandar Johor Bahru, Johor, Malaysia',
      description: 'Iconic heritage café operating since 1946 serving traditional Hainanese chicken chop and royal Johor Laksa made with spaghetti and rich spiced fish gravy.',
      latitude: 1.4582,
      longitude: 103.7648,
      imageUrl: '', // Empty image link ready for insert image
      isApproved: true,
      contributor: 'Faridah Ahmad',
      culturalSignificance: 'Culinary monument bridging Hainanese migrant cooking with traditional royal Johor Malay banquet recipes.',
    ),
    // 3. Johor Bahru, Malaysia (Murals)
    Discovery(
      id: 'd_johor_murals',
      title: 'Pasar Karat Heritage Street Murals',
      category: CulturalCategory.murals,
      location: 'Jalan Segget, Johor Bahru, Johor, Malaysia',
      description: 'Large-scale urban wall paintings illustrating early Gambier and Pepper traders, traditional river boats, and multiracial street life of old Johor.',
      latitude: 1.4589,
      longitude: 103.7635,
      imageUrl: '', // Empty image link ready for insert image
      isApproved: true,
      contributor: 'Suresh Rao',
      culturalSignificance: 'Revitalizing old Johor Bahru riverside alleys through public community storytelling and youth arts.',
    ),
    // 4. Johor Bahru, Malaysia (Crafts)
    Discovery(
      id: 'd_johor_crafts',
      title: 'Kompleks Kraf Johor (Johor Craft Complex)',
      category: CulturalCategory.crafts,
      location: 'Jalan Cenderasari, Larkin, Johor Bahru, Johor, Malaysia',
      description: 'Dedicated artisan center showcasing authentic Johor songket weaving, copper tooling, wood carving, and traditional Zapin musical instruments.',
      latitude: 1.4932,
      longitude: 103.7431,
      imageUrl: '', // Empty image link ready for insert image
      isApproved: true,
      contributor: 'Nurul Huda',
      culturalSignificance: 'Preserving ancient Malay royal court weaving and Johor Zapin folk heritage for future generations.',
    ),
    // 5. Global: Rome Colosseum
    Discovery(
      id: 'd_rome',
      title: 'Colosseum',
      category: CulturalCategory.heritage,
      location: 'Piazza del Colosseo, Rome, Italy',
      description: 'An iconic ancient amphitheatre and a symbol of Roman history and culture, completed in 80 AD under Emperor Titus.',
      latitude: 41.8902,
      longitude: 12.4922,
      imageUrl: '', // Empty image link ready for insert image
      isApproved: true,
      contributor: 'Marco R.',
      culturalSignificance: 'World Heritage marvel symbolizing Roman engineering, imperial spectacles, and civic identity.',
    ),
    // 6. Global: Tokyo Food
    Discovery(
      id: 'd_tokyo_food',
      title: 'Tsukiji Ramen & Seafood Alley',
      category: CulturalCategory.food,
      location: 'Chuo City, Tokyo, Japan',
      description: 'Historic food lane featuring century-old broth recipes, fresh sashimi bowls, and artisan tamagoyaki prepared before your eyes.',
      latitude: 35.6655,
      longitude: 139.7708,
      imageUrl: '', // Empty image link ready for insert image
      isApproved: true,
      contributor: 'Kenji Takahashi',
      culturalSignificance: 'The historic culinary belly of Tokyo preserving multi-generational culinary master crafts.',
    ),
    // 7. Global: Shoreditch Murals
    Discovery(
      id: 'd_shoreditch_murals',
      title: 'Shoreditch Cultural Murals',
      category: CulturalCategory.murals,
      location: 'Brick Lane, London, UK',
      description: 'Vibrant street murals celebrating multicultural unity, diaspora stories, and contemporary cultural vitality.',
      latitude: 51.5235,
      longitude: -0.0768,
      imageUrl: '', // Empty image link ready for insert image
      isApproved: true,
      contributor: 'Elena K.',
      culturalSignificance: 'A globally renowned open-air public art sanctuary reflecting East London migration and creative vitality.',
    ),
    // 8. Global: Kyoto Crafts
    Discovery(
      id: 'd_kyoto_crafts',
      title: 'Kiyomizu Pottery & Bamboo Craft',
      category: CulturalCategory.crafts,
      location: 'Higashiyama, Kyoto, Japan',
      description: 'Traditional stoneware studios and bamboo weaving masters continuing Edo period tea ceremony utensils.',
      latitude: 34.9949,
      longitude: 135.7850,
      imageUrl: '', // Empty image link ready for insert image
      isApproved: true,
      contributor: 'Aoi Tanaka',
      culturalSignificance: 'Intangible cultural heritage of Japanese craftsmanship centered around mindful Zen aesthetics.',
    ),
  ];
}
