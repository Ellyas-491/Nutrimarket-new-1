import 'dart:convert';

class FoodProduct {
  final String id;
  final String name;
  final String category; // Healthy Meals, Healthy Snacks, Drinks, Bakery & Cereals
  final double price;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final int calories; // kcal
  final double protein; // g
  final double carbs; // g
  final double fat; // g
  final double fiber; // g
  final double sugar; // g
  final double sodium; // mg
  final List<String> suitableFor; // High Protein, Low Sugar, Diabetes-friendly, Low Sodium, Gluten-Free, Vegan, Vegetarian
  final List<String> ingredients;
  final List<String> allergens;
  final String nutritionistName;
  final String nutritionistReview;
  final String verificationStatus; // VERIFIED, PENDING, REJECTED

  const FoodProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.suitableFor,
    required this.ingredients,
    required this.allergens,
    required this.nutritionistName,
    required this.nutritionistReview,
    this.verificationStatus = 'VERIFIED',
  });

  String get formattedPrice {
    final priceInt = price.toInt();
    final buffer = StringBuffer();
    final str = priceInt.toString();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp$buffer';
  }

  bool get isVerified {
    final s = verificationStatus.toUpperCase().trim();
    return s == 'VERIFIED' || s.isEmpty || s == 'TRUE' || s == '1' || s == 'AKTIF' || s == 'APPROVED';
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return [];
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
          }
        } catch (_) {}
      }
      return trimmed
          .split(',')
          .map((e) => e.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll("'", '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [value.toString()];
  }

  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      final clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? defaultValue;
    }
    return defaultValue;
  }

  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    if (value is String) {
      final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(clean) ?? defaultValue;
    }
    return defaultValue;
  }

  factory FoodProduct.fromMap(Map<String, dynamic> map) {
    final status = (map['verification_status'] ?? map['verificationStatus'] ?? 'VERIFIED').toString();
    return FoodProduct(
      id: (map['id'] ?? map['product_id'] ?? map['productId'] ?? '').toString(),
      name: (map['name'] ?? map['title'] ?? map['product_name'] ?? '').toString(),
      category: (map['category'] ?? map['category_name'] ?? 'Healthy Meals').toString(),
      price: _parseDouble(map['price'] ?? map['product_price']),
      rating: _parseDouble(map['rating'] ?? map['rate'], 4.8),
      reviewCount: _parseInt(map['review_count'] ?? map['reviewCount'] ?? map['reviews']),
      imageUrl: (map['image_url'] ?? map['imageUrl'] ?? map['image'] ?? map['photo'] ?? '').toString(),
      calories: _parseInt(map['calories'] ?? map['kalori'] ?? map['cal']),
      protein: _parseDouble(map['protein']),
      carbs: _parseDouble(map['carbs'] ?? map['karbohidrat'] ?? map['karbo']),
      fat: _parseDouble(map['fat'] ?? map['lemak']),
      fiber: _parseDouble(map['fiber'] ?? map['serat']),
      sugar: _parseDouble(map['sugar'] ?? map['gula']),
      sodium: _parseDouble(map['sodium'] ?? map['natrium']),
      suitableFor: _parseList(map['suitable_for'] ?? map['suitableFor'] ?? map['diet_tags'] ?? map['tags']),
      ingredients: _parseList(map['ingredients'] ?? map['bahan'] ?? map['komposisi']),
      allergens: _parseList(map['allergens'] ?? map['alergen']),
      nutritionistName: (map['nutritionist_name'] ?? map['nutritionistName'] ?? 'Ahli Gizi NutriMarket').toString(),
      nutritionistReview: (map['nutritionist_review'] ?? map['nutritionistReview'] ?? map['review'] ?? '').toString(),
      verificationStatus: status.isEmpty ? 'VERIFIED' : status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'rating': rating,
      'review_count': reviewCount,
      'image_url': imageUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'suitable_for': suitableFor,
      'ingredients': ingredients,
      'allergens': allergens,
      'nutritionist_name': nutritionistName,
      'nutritionist_review': nutritionistReview,
      'verification_status': verificationStatus,
    };
  }
}
