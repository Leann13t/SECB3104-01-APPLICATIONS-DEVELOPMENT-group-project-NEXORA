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
}

class CulturalCreature {
  final String id;
  final String name;
  final String title;
  final String culturalOrigin;
  final String eligibleLocation;
  final CreatureRarity rarity;
  final String emoji;
  final bool isCollected;
  final String lore;

  const CulturalCreature({
    required this.id,
    required this.name,
    required this.title,
    required this.culturalOrigin,
    required this.eligibleLocation,
    required this.rarity,
    required this.emoji,
    this.isCollected = false,
    required this.lore,
  });

  // Placeholder data clearly marked for development & prototype testing
  static List<CulturalCreature> get placeholderCreatures => const [
    CulturalCreature(
      id: 'c1',
      name: 'Paku Midin Sprite',
      title: 'Forest Forager',
      culturalOrigin: 'Dayak Jungle Heritage',
      eligibleLocation: 'Sibu Central Market',
      rarity: CreatureRarity.common,
      emoji: '🌿',
      isCollected: true,
      lore: 'Born from wild fiddlehead ferns gathered along misty rainforest riverbanks.',
    ),
    CulturalCreature(
      id: 'c2',
      name: 'Kompia Baker Kobold',
      title: 'Hearth Guardian',
      culturalOrigin: 'Foochow Culinary Tradition',
      eligibleLocation: 'Ah Huat Clay Oven Bakery',
      rarity: CreatureRarity.rare,
      emoji: '🥯',
      isCollected: true,
      lore: 'Inhabits traditional charcoal clay urns, blessing dough with golden crispness.',
    ),
    CulturalCreature(
      id: 'c3',
      name: 'Kenyah Hornbill Guardian',
      title: 'Sky Totem',
      culturalOrigin: 'Orang Ulu Ancestral Craft',
      eligibleLocation: 'Sarawak River Waterfront Heritage',
      rarity: CreatureRarity.legendary,
      emoji: '🦜',
      isCollected: true,
      lore: 'A revered spiritual creature carrying sacred blessings across the great Rajang river.',
    ),
    CulturalCreature(
      id: 'c4',
      name: 'Sambal Laksa Imp',
      title: 'Spiced Ember',
      culturalOrigin: 'Sarawak Spices & Sambal Belacan',
      eligibleLocation: 'Taman Sentosa Laksa Haven',
      rarity: CreatureRarity.common,
      emoji: '🌶️',
      isCollected: false,
      lore: 'Carries fragrant tamarind, coriander seeds, and fiery chili embers in its shell.',
    ),
    CulturalCreature(
      id: 'c5',
      name: 'Rattan Weaver Nymph',
      title: 'Basket Artisan',
      culturalOrigin: 'Iban Pua Kumbu & Weaving',
      eligibleLocation: 'Traditional Craft Corner',
      rarity: CreatureRarity.rare,
      emoji: '🧺',
      isCollected: false,
      lore: 'Weaves river reeds into protective talismans during harvest festivals.',
    ),
    CulturalCreature(
      id: 'c6',
      name: 'Dragon River Spirit',
      title: 'Wharf Protector',
      culturalOrigin: 'Rajang Riverine Culture',
      eligibleLocation: 'Tua Pek Kong Waterfront',
      rarity: CreatureRarity.legendary,
      emoji: '🐉',
      isCollected: false,
      lore: 'Guards the old wooden wharves and grants calm currents to trading express boats.',
    ),
  ];
}
