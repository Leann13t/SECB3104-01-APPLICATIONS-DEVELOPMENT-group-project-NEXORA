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

  Color get color {
    switch (this) {
      case CulturalCategory.food:
        return const Color(0xFFD8F2FF);
      case CulturalCategory.heritage:
        return const Color(0xFFD4F6E6);
      case CulturalCategory.murals:
        return const Color(0xFFFFE0ED);
      case CulturalCategory.crafts:
        return const Color(0xFFFFF0D1);
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
  });

  // Sample data clearly marked as temporary placeholder data
  static List<Discovery> get placeholderDiscoveries => const [
    Discovery(
      id: 'd1',
      title: 'Sibu Heritage Lane',
      category: CulturalCategory.heritage,
      location: 'Sibu, Sarawak',
      description: 'A charming street featuring preserved colonial-era shophouses, traditional Foochow craftsmanship, and heritage signboards.',
      latitude: 2.2878,
      longitude: 111.8305,
      imageUrl: 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?auto=format&fit=crop&w=600&q=80',
      isApproved: true,
      culturalSignificance: 'One of the earliest trade settlements established along the Rajang River.',
    ),
    Discovery(
      id: 'd2',
      title: 'Traditional Craft Corner',
      category: CulturalCategory.crafts,
      location: 'Sibu Central Market, Sarawak',
      description: 'Master artisans weaving intricate rattan baskets, beadwork, and indigenous wood carvings representing local Dayak heritage.',
      latitude: 2.2901,
      longitude: 111.8267,
      imageUrl: 'https://images.unsplash.com/photo-1590736969955-71cc94801759?auto=format&fit=crop&w=600&q=80',
      isApproved: true,
      culturalSignificance: 'Preserving multi-generational weaving knowledge and indigenous plant utilization.',
    ),
    Discovery(
      id: 'd3',
      title: 'Laksa Taman Sentosa',
      category: CulturalCategory.food,
      location: 'Jalan Sentosa, Sibu',
      description: 'Iconic Sarawak Laksa with rich spiced sambal broth, fresh prawns, shredded omelette, and homemade sambal belacan.',
      latitude: 2.3021,
      longitude: 111.8340,
      imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80',
      isApproved: true,
      culturalSignificance: 'A beloved culinary staple blending indigenous spices with regional Foochow preparation.',
    ),
    Discovery(
      id: 'd4',
      title: 'Community Mural Corner',
      category: CulturalCategory.murals,
      location: 'Waterfront Lane, Sibu',
      description: 'Vibrant local street art depicting traditional wharf workers, hornbills, and everyday river life painted by young Sarawakian artists.',
      latitude: 2.2889,
      longitude: 111.8289,
      imageUrl: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=600&q=80',
      isApproved: true,
      culturalSignificance: 'Honoring the riverine heritage and everyday unsung heroes of the town.',
    ),
    Discovery(
      id: 'd5',
      title: 'Tua Pek Kong Pagoda',
      category: CulturalCategory.heritage,
      location: 'Jalan Temple, Sibu',
      description: 'A stunning 7-storey landmark pagoda overlooking the Rajang River, built with traditional southeastern Chinese temple architecture.',
      latitude: 2.2865,
      longitude: 111.8275,
      imageUrl: 'https://images.unsplash.com/photo-1548013146-72479768bada?auto=format&fit=crop&w=600&q=80',
      isApproved: true,
      culturalSignificance:
          'The oldest Chinese temple complex in Sibu, dating back to 1871.',
    ),
    Discovery(
      id: 'd6',
      title: 'Ah Huat Sibu Kompia',
      category: CulturalCategory.food,
      location: 'Market Road, Sibu',
      description: 'Crispy clay-oven baked sesame bagels stuffed with savory minced pork gravy, baked daily according to century-old wood-fired methods.',
      latitude: 2.2895,
      longitude: 111.8290,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      isApproved: true,
      culturalSignificance: 'Known as the "Foochow Bagel", historically baked for soldiers traveling across rivers.',
    ),
  ];
}
