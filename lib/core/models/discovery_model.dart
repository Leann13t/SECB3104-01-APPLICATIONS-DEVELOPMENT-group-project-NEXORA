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

  String get emoji {
    switch (this) {
      case CulturalCategory.food:
        return '🍜';
      case CulturalCategory.heritage:
        return '🏛️';
      case CulturalCategory.murals:
        return '🎨';
      case CulturalCategory.crafts:
        return '🧺';
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
  final String? imageUrl;
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
    this.imageUrl,
    this.isApproved = true,
    this.contributor = 'Community Explorer',
    this.culturalSignificance,
    this.isBookmarked = false,
  });

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
      location: map['location']?.toString() ?? 'Global',
      description: map['description']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      imageUrl: map['image_url']?.toString(),
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

  // Curated global cultural discoveries clearly marked as placeholder development data
  static List<Discovery> get placeholderDiscoveries => const [
    Discovery(
      id: 'd_rome',
      title: 'Colosseum',
      category: CulturalCategory.heritage,
      location: 'Piazza del Colosseo, Rome, Italy',
      description:
          'An iconic ancient amphitheatre and a symbol of Roman history and culture, completed in 80 AD under Emperor Titus.',
      latitude: 41.8902,
      longitude: 12.4922,
      imageUrl:
          'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=700&q=80',
      isApproved: true,
      contributor: 'Marco R.',
      culturalSignificance:
          'World Heritage marvel symbolizing Roman engineering, imperial spectacles, and civic identity.',
    ),
    Discovery(
      id: 'd_tokyo_food',
      title: 'Tsukiji Ramen & Seafood Alley',
      category: CulturalCategory.food,
      location: 'Chuo City, Tokyo, Japan',
      description:
          'Historic food lane featuring century-old broth recipes, fresh sashimi bowls, and artisan tamagoyaki prepared before your eyes.',
      latitude: 35.6655,
      longitude: 139.7708,
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=700&q=80',
      isApproved: true,
      contributor: 'Kenji Takahashi',
      culturalSignificance:
          'The historic culinary belly of Tokyo preserving multi-generational culinary master crafts.',
    ),
    Discovery(
      id: 'd_shoreditch_murals',
      title: 'Shoreditch Cultural Murals',
      category: CulturalCategory.murals,
      location: 'Brick Lane, London, UK',
      description:
          'Vibrant street murals celebrating multicultural unity, diaspora stories, and contemporary cultural resistance.',
      latitude: 51.5235,
      longitude: -0.0768,
      imageUrl:
          'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=700&q=80',
      isApproved: true,
      contributor: 'Elena K.',
      culturalSignificance:
          'A globally renowned open-air public art sanctuary reflecting East London migration and creative vitality.',
    ),
    Discovery(
      id: 'd_kyoto_crafts',
      title: 'Kiyomizu Pottery & Bamboo Craft',
      category: CulturalCategory.crafts,
      location: 'Higashiyama, Kyoto, Japan',
      description:
          'Traditional stoneware studios and bamboo weaving masters continuing Edo period tea ceremony utensils.',
      latitude: 34.9949,
      longitude: 135.7850,
      imageUrl:
          'https://images.unsplash.com/photo-1590736969955-71cc94801759?auto=format&fit=crop&w=700&q=80',
      isApproved: true,
      contributor: 'Aoi Tanaka',
      culturalSignificance:
          'Intangible cultural heritage of Japanese craftsmanship centered around mindful Zen aesthetics.',
    ),
    Discovery(
      id: 'd_sibu_heritage',
      title: 'Sibu Heritage Lane & Pagoda',
      category: CulturalCategory.heritage,
      location: 'Jalan Temple, Sibu, Malaysia',
      description:
          'A charming historic riverside street featuring preserved colonial-era shophouses, traditional Foochow craftsmanship, and the 7-tier Tua Pek Kong Pagoda.',
      latitude: 2.2878,
      longitude: 111.8305,
      imageUrl:
          'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?auto=format&fit=crop&w=700&q=80',
      isApproved: true,
      contributor: 'Mei Ling Wong',
      culturalSignificance:
          'One of the earliest trade settlements established along the Rajang River blending Foochow and Dayak traditions.',
    ),
    Discovery(
      id: 'd_sibu_food',
      title: 'Ah Huat Clay-Oven Kompia',
      category: CulturalCategory.food,
      location: 'Market Road, Sibu, Malaysia',
      description:
          'Crispy clay-oven baked sesame bagels stuffed with savory minced meat gravy, baked daily using century-old wood-fired earthen jars.',
      latitude: 2.2895,
      longitude: 111.8290,
      imageUrl:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=700&q=80',
      isApproved: true,
      contributor: 'David Lau',
      culturalSignificance:
          'Known as the "Foochow Bagel", historically baked for soldiers traveling across rivers.',
    ),
    Discovery(
      id: 'd_oaxaca_crafts',
      title: 'Oaxaca Alebrijes & Loom Weaving',
      category: CulturalCategory.crafts,
      location: 'San Martin Tilcajete, Oaxaca, Mexico',
      description:
          'Folk art workshops hand-carving fantastical copal wood creatures and dyeing raw wool rugs using cochineal bugs and natural pomegranate.',
      latitude: 17.0608,
      longitude: -96.7256,
      imageUrl:
          'https://images.unsplash.com/photo-1582560475093-ba66accbc424?auto=format&fit=crop&w=700&q=80',
      isApproved: true,
      contributor: 'Mateo Hernandez',
      culturalSignificance:
          'Zapotec indigenous craft traditions passed down through ancestral village guilds.',
    ),
    Discovery(
      id: 'd_penang_murals',
      title: 'Children on a Bicycle Mural',
      category: CulturalCategory.murals,
      location: 'Armenian Street, George Town, Malaysia',
      description:
          'Internationally acclaimed wall art painted on historic lime-washed shophouse walls, celebrating playful innocence and everyday street life.',
      latitude: 5.4141,
      longitude: 100.3364,
      imageUrl:
          'https://images.unsplash.com/photo-1561055657-b9e0bf0fa360?auto=format&fit=crop&w=700&q=80',
      isApproved: true,
      contributor: 'Sara Lim',
      culturalSignificance:
          'UNESCO World Heritage cultural landmark bridging historic preservation with creative street culture.',
    ),
  ];
}
