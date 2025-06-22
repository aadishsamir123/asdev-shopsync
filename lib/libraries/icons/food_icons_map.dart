import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';

/// Icon mapping data structure for food and beverage icons
class FoodIconMapping {
  final String identifier;
  final String displayName;
  final IconData icon;

  const FoodIconMapping({
    required this.identifier,
    required this.displayName,
    required this.icon,
  });
}

class LucideFoodIconMap {
  static const Map<String, FoodIconMapping> _foodIconMap = {
    // Fruits
    'apple': FoodIconMapping(
      identifier: 'apple',
      displayName: 'Apple',
      icon: LucideIcons.apple,
    ),
    'banana': FoodIconMapping(
      identifier: 'banana',
      displayName: 'Banana',
      icon: LucideIcons.banana,
    ),
    'cherry': FoodIconMapping(
      identifier: 'cherry',
      displayName: 'Cherry',
      icon: LucideIcons.cherry,
    ),
    'citrus': FoodIconMapping(
      identifier: 'citrus',
      displayName: 'Citrus',
      icon: LucideIcons.citrus,
    ),
    'grape': FoodIconMapping(
      identifier: 'grape',
      displayName: 'Grape',
      icon: LucideIcons.grape,
    ),
    'lemon': FoodIconMapping(
      identifier: 'lemon',
      displayName: 'Lemon',
      icon: LucideIcons.citrus,
    ),
    'orange': FoodIconMapping(
      identifier: 'orange',
      displayName: 'Orange',
      icon: LucideIcons.citrus,
    ),
    'strawberry': FoodIconMapping(
      identifier: 'strawberry',
      displayName: 'Strawberry',
      icon: LucideIcons.heart,
    ),
    'watermelon': FoodIconMapping(
      identifier: 'watermelon',
      displayName: 'Watermelon',
      icon: LucideIcons.circle,
    ),

    // Vegetables
    'bean': FoodIconMapping(
      identifier: 'bean',
      displayName: 'Bean',
      icon: LucideIcons.bean,
    ),
    'carrot': FoodIconMapping(
      identifier: 'carrot',
      displayName: 'Carrot',
      icon: LucideIcons.carrot,
    ),
    'corn': FoodIconMapping(
      identifier: 'corn',
      displayName: 'Corn',
      icon: LucideIcons.wheat,
    ),
    'lettuce': FoodIconMapping(
      identifier: 'lettuce',
      displayName: 'Lettuce',
      icon: LucideIcons.leaf,
    ),
    'mushroom': FoodIconMapping(
      identifier: 'mushroom',
      displayName: 'Mushroom',
      icon: LucideIcons.leaf,
    ),
    'onion': FoodIconMapping(
      identifier: 'onion',
      displayName: 'Onion',
      icon: LucideIcons.circle,
    ),
    'potato': FoodIconMapping(
      identifier: 'potato',
      displayName: 'Potato',
      icon: LucideIcons.circle,
    ),
    'radish': FoodIconMapping(
      identifier: 'radish',
      displayName: 'Radish',
      icon: LucideIcons.carrot,
    ),
    'salad': FoodIconMapping(
      identifier: 'salad',
      displayName: 'Salad',
      icon: LucideIcons.salad,
    ),

    // Proteins & Meat
    'beef': FoodIconMapping(
      identifier: 'beef',
      displayName: 'Beef',
      icon: LucideIcons.beef,
    ),
    'drumstick': FoodIconMapping(
      identifier: 'drumstick',
      displayName: 'Chicken Drumstick',
      icon: LucideIcons.drumstick,
    ),
    'fish': FoodIconMapping(
      identifier: 'fish',
      displayName: 'Fish',
      icon: LucideIcons.fish,
    ),
    'ham': FoodIconMapping(
      identifier: 'ham',
      displayName: 'Ham',
      icon: LucideIcons.ham,
    ),
    'popcorn': FoodIconMapping(
      identifier: 'popcorn',
      displayName: 'Popcorn',
      icon: LucideIcons.popcorn,
    ),
    'soup': FoodIconMapping(
      identifier: 'soup',
      displayName: 'Soup',
      icon: LucideIcons.soup,
    ),

    // Eggs & Dairy
    'egg': FoodIconMapping(
      identifier: 'egg',
      displayName: 'Egg',
      icon: LucideIcons.egg,
    ),
    'eggFried': FoodIconMapping(
      identifier: 'eggFried',
      displayName: 'Fried Egg',
      icon: LucideIcons.eggFried,
    ),
    'milk': FoodIconMapping(
      identifier: 'milk',
      displayName: 'Milk',
      icon: LucideIcons.milk,
    ),
    'milkOff': FoodIconMapping(
      identifier: 'milkOff',
      displayName: 'No Milk',
      icon: LucideIcons.milkOff,
    ),

    // Baked Goods & Desserts
    'cake': FoodIconMapping(
      identifier: 'cake',
      displayName: 'Cake',
      icon: LucideIcons.cake,
    ),
    'cakeSlice': FoodIconMapping(
      identifier: 'cakeSlice',
      displayName: 'Cake Slice',
      icon: LucideIcons.cakeSlice,
    ),
    'candy': FoodIconMapping(
      identifier: 'candy',
      displayName: 'Candy',
      icon: LucideIcons.candy,
    ),
    'candyCane': FoodIconMapping(
      identifier: 'candyCane',
      displayName: 'Candy Cane',
      icon: LucideIcons.candyCane,
    ),
    'cookie': FoodIconMapping(
      identifier: 'cookie',
      displayName: 'Cookie',
      icon: LucideIcons.cookie,
    ),
    'croissant': FoodIconMapping(
      identifier: 'croissant',
      displayName: 'Croissant',
      icon: LucideIcons.croissant,
    ),
    'donut': FoodIconMapping(
      identifier: 'donut',
      displayName: 'Donut',
      icon: LucideIcons.donut,
    ),
    'iceCreamBowl': FoodIconMapping(
      identifier: 'iceCreamBowl',
      displayName: 'Ice Cream Bowl',
      icon: LucideIcons.iceCreamBowl,
    ),
    'iceCreamCone': FoodIconMapping(
      identifier: 'iceCreamCone',
      displayName: 'Ice Cream Cone',
      icon: LucideIcons.iceCreamCone,
    ),
    'lollipop': FoodIconMapping(
      identifier: 'lollipop',
      displayName: 'Lollipop',
      icon: LucideIcons.lollipop,
    ),
    'pancakes': FoodIconMapping(
      identifier: 'pancakes',
      displayName: 'Pancakes',
      icon: LucideIcons.layers,
    ),
    'pizza': FoodIconMapping(
      identifier: 'pizza',
      displayName: 'Pizza',
      icon: LucideIcons.pizza,
    ),
    'pretzel': FoodIconMapping(
      identifier: 'pretzel',
      displayName: 'Pretzel',
      icon: LucideIcons.circle,
    ),
    'sandwich': FoodIconMapping(
      identifier: 'sandwich',
      displayName: 'Sandwich',
      icon: LucideIcons.sandwich,
    ),

    // Beverages - Hot
    'coffee': FoodIconMapping(
      identifier: 'coffee',
      displayName: 'Coffee',
      icon: LucideIcons.coffee,
    ),
    'cupSoda': FoodIconMapping(
      identifier: 'cupSoda',
      displayName: 'Soda Cup',
      icon: LucideIcons.cupSoda,
    ),
    'teacup': FoodIconMapping(
      identifier: 'teacup',
      displayName: 'Teacup',
      icon: LucideIcons.coffee,
    ),

    // Beverages - Alcoholic
    'beer': FoodIconMapping(
      identifier: 'beer',
      displayName: 'Beer',
      icon: LucideIcons.beer,
    ),
    'beerOff': FoodIconMapping(
      identifier: 'beerOff',
      displayName: 'No Alcohol',
      icon: LucideIcons.beerOff,
    ),
    'martini': FoodIconMapping(
      identifier: 'martini',
      displayName: 'Martini',
      icon: LucideIcons.martini,
    ),
    'wine': FoodIconMapping(
      identifier: 'wine',
      displayName: 'Wine',
      icon: LucideIcons.wine,
    ),
    'wineOff': FoodIconMapping(
      identifier: 'wineOff',
      displayName: 'No Wine',
      icon: LucideIcons.wineOff,
    ),

    // Cooking & Kitchen
    'amphora': FoodIconMapping(
      identifier: 'amphora',
      displayName: 'Amphora',
      icon: LucideIcons.amphora,
    ),
    'chefHat': FoodIconMapping(
      identifier: 'chefHat',
      displayName: 'Chef Hat',
      icon: LucideIcons.chefHat,
    ),
    'cookingPot': FoodIconMapping(
      identifier: 'cookingPot',
      displayName: 'Cooking Pot',
      icon: LucideIcons.cookingPot,
    ),
    'utensils': FoodIconMapping(
      identifier: 'utensils',
      displayName: 'Utensils',
      icon: LucideIcons.utensils,
    ),
    'utensilsCrossed': FoodIconMapping(
      identifier: 'utensilsCrossed',
      displayName: 'Crossed Utensils',
      icon: LucideIcons.utensilsCrossed,
    ),

    // Nuts & Snacks
    'nut': FoodIconMapping(
      identifier: 'nut',
      displayName: 'Nut',
      icon: LucideIcons.nut,
    ),
    'nutOff': FoodIconMapping(
      identifier: 'nutOff',
      displayName: 'No Nuts',
      icon: LucideIcons.nutOff,
    ),

    // Special Categories
    'vegan': FoodIconMapping(
      identifier: 'vegan',
      displayName: 'Vegan',
      icon: LucideIcons.vegan,
    ),
    'wheat': FoodIconMapping(
      identifier: 'wheat',
      displayName: 'Wheat',
      icon: LucideIcons.wheat,
    ),
    'wheatOff': FoodIconMapping(
      identifier: 'wheatOff',
      displayName: 'Gluten Free',
      icon: LucideIcons.wheatOff,
    ),
  };

  /// Get a food icon mapping by identifier
  static FoodIconMapping? getIcon(String identifier) {
    return _foodIconMap[identifier];
  }

  /// Get just the IconData by identifier
  static IconData? getIconData(String identifier) {
    return _foodIconMap[identifier]?.icon;
  }

  /// Get the display name by identifier
  static String? getDisplayName(String identifier) {
    return _foodIconMap[identifier]?.displayName;
  }

  /// Get all available food icon identifiers
  static List<String> getAllIdentifiers() {
    return _foodIconMap.keys.toList();
  }

  /// Get all food icon mappings
  static List<FoodIconMapping> getAllIcons() {
    return _foodIconMap.values.toList();
  }

  /// Search food icons by display name or identifier
  static List<FoodIconMapping> searchFoodIcons(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _foodIconMap.values
        .where((mapping) =>
            mapping.displayName.toLowerCase().contains(lowercaseQuery) ||
            mapping.identifier.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  /// Get food icons by category
  static List<FoodIconMapping> getFoodIconsByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return [
          'apple',
          'banana',
          'cherry',
          'citrus',
          'grape',
          'lemon',
          'orange',
          'strawberry',
          'watermelon'
        ]
            .map((id) => _foodIconMap[id])
            .where((mapping) => mapping != null)
            .cast<FoodIconMapping>()
            .toList();

      case 'vegetables':
        return [
          'bean',
          'carrot',
          'corn',
          'lettuce',
          'mushroom',
          'onion',
          'potato',
          'radish',
          'salad'
        ]
            .map((id) => _foodIconMap[id])
            .where((mapping) => mapping != null)
            .cast<FoodIconMapping>()
            .toList();

      case 'proteins':
        return ['beef', 'drumstick', 'fish', 'ham', 'egg', 'eggFried']
            .map((id) => _foodIconMap[id])
            .where((mapping) => mapping != null)
            .cast<FoodIconMapping>()
            .toList();

      case 'desserts':
        return [
          'cake',
          'cakeSlice',
          'candy',
          'candyCane',
          'cookie',
          'croissant',
          'donut',
          'iceCreamBowl',
          'iceCreamCone',
          'lollipop',
          'pancakes'
        ]
            .map((id) => _foodIconMap[id])
            .where((mapping) => mapping != null)
            .cast<FoodIconMapping>()
            .toList();

      case 'beverages':
        return [
          'coffee',
          'cupSoda',
          'teacup',
          'beer',
          'beerOff',
          'martini',
          'wine',
          'wineOff',
          'milk',
          'milkOff'
        ]
            .map((id) => _foodIconMap[id])
            .where((mapping) => mapping != null)
            .cast<FoodIconMapping>()
            .toList();

      case 'cooking':
        return [
          'amphora',
          'chefHat',
          'cookingPot',
          'utensils',
          'utensilsCrossed'
        ]
            .map((id) => _foodIconMap[id])
            .where((mapping) => mapping != null)
            .cast<FoodIconMapping>()
            .toList();

      case 'dietary':
        return [
          'vegan',
          'wheat',
          'wheatOff',
          'nutOff',
          'beerOff',
          'wineOff',
          'milkOff'
        ]
            .map((id) => _foodIconMap[id])
            .where((mapping) => mapping != null)
            .cast<FoodIconMapping>()
            .toList();

      default:
        return [];
    }
  }

  /// Get popular food icons for quick access
  static List<FoodIconMapping> getPopularFoodIcons() {
    return [
      'apple',
      'coffee',
      'pizza',
      'cake',
      'beer',
      'fish',
      'salad',
      'cookie',
      'milk',
      'sandwich'
    ]
        .map((id) => _foodIconMap[id])
        .where((mapping) => mapping != null)
        .cast<FoodIconMapping>()
        .toList();
  }
}
