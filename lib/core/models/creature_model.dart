enum CreatureRarity {
  common,
  rare,
  legendary;

  String get label {
    switch (this) {
      case CreatureRarity.common:
        return 'Common';
      case CreatureRarity.rare:
        return 'Rare';
      case CreatureRarity.legendary:
        return 'Legendary';
    }
  }

  String get badgeText {
    switch (this) {
      case CreatureRarity.common:
        return 'Common';
      case CreatureRarity.rare:
        return 'Rare';
      case CreatureRarity.legendary:
        return 'Legendary';
    }
  }
}

class CulturalCreature {
  final String id;
  final String name;
  final String title;
  final String country;
  final String culturalOrigin;
  final String eligibleLocation;
  final double latitude;
  final double longitude;
  final CreatureRarity rarity;
  final String imageUrl;   // Empty image link: ready for insert image!
  final String imageAsset; // Empty asset path: ready for insert image!
  final bool isCollected;
  final DateTime? collectedAt;
  final String lore;

  const CulturalCreature({
    required this.id,
    required this.name,
    required this.title,
    required this.country,
    required this.culturalOrigin,
    required this.eligibleLocation,
    required this.latitude,
    required this.longitude,
    required this.rarity,
    this.imageUrl = '',   // Empty image link
    this.imageAsset = '', // Empty asset path
    this.isCollected = false,
    this.collectedAt,
    required this.lore,
  });

  bool get hasCustomImage => imageUrl.trim().isNotEmpty || imageAsset.trim().isNotEmpty;

  CulturalCreature copyWith({
    String? id,
    String? name,
    String? title,
    String? country,
    String? culturalOrigin,
    String? eligibleLocation,
    double? latitude,
    double? longitude,
    CreatureRarity? rarity,
    String? imageUrl,
    String? imageAsset,
    bool? isCollected,
    DateTime? collectedAt,
    String? lore,
  }) {
    return CulturalCreature(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      country: country ?? this.country,
      culturalOrigin: culturalOrigin ?? this.culturalOrigin,
      eligibleLocation: eligibleLocation ?? this.eligibleLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rarity: rarity ?? this.rarity,
      imageUrl: imageUrl ?? this.imageUrl,
      imageAsset: imageAsset ?? this.imageAsset,
      isCollected: isCollected ?? this.isCollected,
      collectedAt: collectedAt ?? this.collectedAt,
      lore: lore ?? this.lore,
    );
  }

  factory CulturalCreature.fromMap(Map<String, dynamic> map) {
    CreatureRarity rarity = CreatureRarity.common;
    final rStr = (map['rarity'] as String?)?.toLowerCase() ?? '';
    if (rStr == 'rare') {
      rarity = CreatureRarity.rare;
    } else if (rStr == 'legendary') {
      rarity = CreatureRarity.legendary;
    }

    return CulturalCreature(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Cultural Creature',
      title: map['title']?.toString() ?? 'Wandering Spirit',
      country: map['country']?.toString() ?? 'Global',
      culturalOrigin: map['cultural_origin']?.toString() ?? '',
      eligibleLocation: map['eligible_location']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      rarity: rarity,
      imageUrl: map['image_url']?.toString() ?? '',
      imageAsset: map['image_asset']?.toString() ?? '',
      isCollected: map['is_collected'] == true,
      collectedAt: map['collected_at'] != null
          ? DateTime.tryParse(map['collected_at'].toString())
          : null,
      lore: map['lore']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'country': country,
      'cultural_origin': culturalOrigin,
      'eligible_location': eligibleLocation,
      'latitude': latitude,
      'longitude': longitude,
      'rarity': rarity.name,
      'image_url': imageUrl,
      'image_asset': imageAsset,
      'is_collected': isCollected,
      'collected_at': collectedAt?.toIso8601String(),
      'lore': lore,
    };
  }

  static List<CulturalCreature> get placeholderCreatures => curatedGlobalCreatures;

  // Curated global Hunt collectibles with empty image links ready for user image insertion
  // (Zero emojis!)
  static List<CulturalCreature> get curatedGlobalCreatures => [
    const CulturalCreature(
      id: 'c_taiyaki',
      name: 'Taiyaki Spirit',
      title: 'Sweet Sea Spirit',
      country: 'Japan',
      culturalOrigin: 'Edo Tokyo Street Confections',
      eligibleLocation: 'Tsukiji Market & Asakusa, Tokyo',
      latitude: 35.6655,
      longitude: 139.7708,
      rarity: CreatureRarity.rare,
      imageUrl: '', // Empty image link
      imageAsset: '',
      isCollected: true,
      lore:
          'Inspired by traditional fish-shaped waffle cakes filled with sweet red bean paste. Legend says holding one brings prosperity and warm river breezes.',
    ),
    const CulturalCreature(
      id: 'c_maneki',
      name: 'Lucky Maneki Cat',
      title: 'Fortune Guardian',
      country: 'Japan',
      culturalOrigin: 'Gotokuji Edo Folk Heritage',
      eligibleLocation: 'Gotokuji Temple, Tokyo',
      latitude: 35.6480,
      longitude: 139.6486,
      rarity: CreatureRarity.legendary,
      imageUrl: '', // Empty image link
      imageAsset: '',
      isCollected: true,
      lore:
          'A beloved beckoning feline carrying a Sakura fan and golden bell, celebrated since the 17th century for guiding travelers and blessing homes with good fortune.',
    ),
    const CulturalCreature(
      id: 'c_burger',
      name: 'Cowboy Slider',
      title: 'Desert Trail Guide',
      country: 'USA',
      culturalOrigin: 'Route 66 American Diner Tradition',
      eligibleLocation: 'Route 66 Historic Mile, Arizona',
      latitude: 35.1983,
      longitude: -111.6513,
      rarity: CreatureRarity.rare,
      imageUrl: '', // Empty image link
      imageAsset: '',
      isCollected: true,
      lore:
          'Wearing a miniature Stetson hat amidst desert sagebrush, this cheery wanderer honors classic roadside drive-ins and open road explorer heritage.',
    ),
    const CulturalCreature(
      id: 'c_bao',
      name: 'Bao Bao Dumpling',
      title: 'Steamer Joy',
      country: 'China',
      culturalOrigin: 'Jiangnan Dim Sum & Bamboo Steamers',
      eligibleLocation: 'Yuyuan Old Street, Shanghai',
      latitude: 31.2272,
      longitude: 121.4922,
      rarity: CreatureRarity.common,
      imageUrl: '', // Empty image link
      imageAsset: '',
      isCollected: true,
      lore:
          'Peeking out from aromatic woven bamboo steamers, Bao Bao embodies familial warmth and festival reunion feasts celebrated under glowing red lanterns.',
    ),
    const CulturalCreature(
      id: 'c_elephant',
      name: 'Royal Chang',
      title: 'Sacred Tusker',
      country: 'Thailand',
      culturalOrigin: 'Siam Royal Temple Ceremonies',
      eligibleLocation: 'Wat Arun River Temple, Bangkok',
      latitude: 13.7437,
      longitude: 100.4888,
      rarity: CreatureRarity.rare,
      imageUrl: '', // Empty image link
      imageAsset: '',
      isCollected: true,
      lore:
          'Adorned in ornate gold filigree and fresh lotus blossoms, Chang symbolizes wisdom, royal peace, and spiritual guardian blessings along the Chao Phraya River.',
    ),
    const CulturalCreature(
      id: 'c_owl',
      name: 'Athena Owl',
      title: 'Wisdom Totem',
      country: 'Greece',
      culturalOrigin: 'Ancient Hellenic Philosophy & Coins',
      eligibleLocation: 'Acropolis Parthenon, Athens',
      latitude: 37.9715,
      longitude: 23.7267,
      rarity: CreatureRarity.common,
      imageUrl: '', // Empty image link
      imageAsset: '',
      isCollected: true,
      lore:
          'Crowned with olive laurels above ancient marble columns, this solemn little owl accompanied philosophers through classical dialogues on democracy and truth.',
    ),
    const CulturalCreature(
      id: 'c_nandi',
      name: 'Nandi Sentinel',
      title: 'Temple Protector',
      country: 'India',
      culturalOrigin: 'Dravidian Sacred Temple Sculpture',
      eligibleLocation: 'Meenakshi Amman Gopuram, Madurai',
      latitude: 9.9195,
      longitude: 78.1193,
      rarity: CreatureRarity.rare,
      imageUrl: '', // Empty image link
      imageAsset: '',
      isCollected: false,
      lore:
          'Carved from timeless granite and garlanded in marigolds, this noble bull guardian protects sacred shrines and blesses travelers with steadfast devotion.',
    ),
    const CulturalCreature(
      id: 'c_moose',
      name: 'Timber Moose',
      title: 'Boreal Wanderer',
      country: 'Canada',
      culturalOrigin: 'First Nations & Northern Forest Heritage',
      eligibleLocation: 'Banff Bow Valley Heritage Woods, Alberta',
      latitude: 51.1784,
      longitude: -115.5708,
      rarity: CreatureRarity.common,
      imageUrl: '', // Empty image link
      imageAsset: '',
      isCollected: false,
      lore:
          'Roaming deep pine needles and snowmelt streams, the gentle Timber Moose embodies northern resilience and quiet harmony with primeval wilderness.',
    ),
    const CulturalCreature(
      id: 'c_hornbill',
      name: 'Kenyah Hornbill Totem',
      title: 'Sky Messenger',
      country: 'Malaysia',
      culturalOrigin: 'Borneo Orang Ulu & Dayak Ancestry',
      eligibleLocation: 'Rajang Waterfront, Sibu, Sarawak',
      latitude: 2.2889,
      longitude: 111.8289,
      rarity: CreatureRarity.legendary,
      imageUrl: '', // Empty image link
      imageAsset: '',
      isCollected: false,
      lore:
          'Known as the Rhinoceros Hornbill, this sacred bird bridges earthly river life with the heavens, depicted in ancestral Kenyah and Iban woodcarvings.',
    ),
    const CulturalCreature(
      id: 'c_croissant',
      name: 'Croissant Petit',
      title: 'Golden Flake',
      country: 'France',
      culturalOrigin: 'Parisian Boulangerie Craft',
      eligibleLocation: 'Montmartre Hillside Bakeries, Paris',
      latitude: 48.8867,
      longitude: 2.3431,
      rarity: CreatureRarity.common,
      imageUrl: '', // Empty image link
      imageAsset: '',
      isCollected: false,
      lore:
          'Laminated with French churned butter and baked to a golden crescent curve, this joyful spirit celebrates café morning culture and cobblestone strolls.',
    ),
  ];
}
