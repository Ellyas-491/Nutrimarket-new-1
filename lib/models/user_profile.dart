class UserProfile {
  final String name;
  final String email;
  final String avatarUrl;
  final int age;
  final double heightCm;
  final double weightKg;
  final String activityLevel;
  final String dietaryType; // General, Diabetes Tipe 2, Prediabetes, High Protein, Low Sodium
  final List<String> dietaryPreferences;
  final List<String> foodAllergies; // Peanut, Seafood, Milk, Egg, Soy, Gluten
  final String healthGoal;
  final bool isPremium;
  final bool isSetupCompleted;
  final String address;
  final String addressLabel;
  final String addressDetail;

  // Real Macro & Nutrition Targets
  final int targetCalories;
  final int maxSugarGrams;
  final int maxSodiumMg;
  final int targetProteinGrams;
  final int targetFiberGrams;

  // Real AI Preferences
  final String aiResponseStyle; // Medis & Edukatif, Ringkas & Solutif, Ramah & Kasual
  final bool autoValidateCart;
  final bool aiVoiceOutput;

  // Real Checkout & Delivery Preferences
  final String defaultPaymentMethod;
  final bool ecoPackaging;
  final bool includeCutlery;
  final bool contactlessDelivery;

  // Security
  final String pinCode;
  final bool biometricsEnabled;

  const UserProfile({
    required this.name,
    this.email = 'user@nutrimarket.id',
    this.avatarUrl = '',
    this.age = 0,
    this.heightCm = 0,
    this.weightKg = 0,
    this.activityLevel = 'Moderate',
    this.dietaryType = 'General Sehat',
    this.dietaryPreferences = const ['Rendah Gula', 'Tinggi Serat'],
    this.foodAllergies = const [],
    this.healthGoal = 'Gaya Hidup Sehat Seimbang',
    this.isPremium = false,
    this.isSetupCompleted = false,
    this.address = '',
    this.addressLabel = 'Pilih Alamat',
    this.addressDetail = '',
    this.targetCalories = 2000,
    this.maxSugarGrams = 25,
    this.maxSodiumMg = 2000,
    this.targetProteinGrams = 75,
    this.targetFiberGrams = 30,
    this.aiResponseStyle = 'Medis & Edukatif',
    this.autoValidateCart = true,
    this.aiVoiceOutput = false,
    this.defaultPaymentMethod = 'QRIS Instant Pay',
    this.ecoPackaging = true,
    this.includeCutlery = false,
    this.contactlessDelivery = false,
    this.pinCode = '123456',
    this.biometricsEnabled = true,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    int? age,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? dietaryType,
    List<String>? dietaryPreferences,
    List<String>? foodAllergies,
    String? healthGoal,
    bool? isPremium,
    bool? isSetupCompleted,
    String? address,
    String? addressLabel,
    String? addressDetail,
    int? targetCalories,
    int? maxSugarGrams,
    int? maxSodiumMg,
    int? targetProteinGrams,
    int? targetFiberGrams,
    String? aiResponseStyle,
    bool? autoValidateCart,
    bool? aiVoiceOutput,
    String? defaultPaymentMethod,
    bool? ecoPackaging,
    bool? includeCutlery,
    bool? contactlessDelivery,
    String? pinCode,
    bool? biometricsEnabled,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      dietaryType: dietaryType ?? this.dietaryType,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      healthGoal: healthGoal ?? this.healthGoal,
      isPremium: isPremium ?? this.isPremium,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      address: address ?? this.address,
      addressLabel: addressLabel ?? this.addressLabel,
      addressDetail: addressDetail ?? this.addressDetail,
      targetCalories: targetCalories ?? this.targetCalories,
      maxSugarGrams: maxSugarGrams ?? this.maxSugarGrams,
      maxSodiumMg: maxSodiumMg ?? this.maxSodiumMg,
      targetProteinGrams: targetProteinGrams ?? this.targetProteinGrams,
      targetFiberGrams: targetFiberGrams ?? this.targetFiberGrams,
      aiResponseStyle: aiResponseStyle ?? this.aiResponseStyle,
      autoValidateCart: autoValidateCart ?? this.autoValidateCart,
      aiVoiceOutput: aiVoiceOutput ?? this.aiVoiceOutput,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      ecoPackaging: ecoPackaging ?? this.ecoPackaging,
      includeCutlery: includeCutlery ?? this.includeCutlery,
      contactlessDelivery: contactlessDelivery ?? this.contactlessDelivery,
      pinCode: pinCode ?? this.pinCode,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? defaultEmail}) {
    final rawAge = (map['age'] as num?)?.toInt() ?? 0;
    return UserProfile(
      name: map['full_name'] as String? ?? 'Pengguna NutriMarket',
      email: map['email'] as String? ?? defaultEmail ?? 'user@nutrimarket.id',
      avatarUrl: map['avatar_url'] as String? ?? '',
      age: rawAge,
      heightCm: (map['height_cm'] as num?)?.toDouble() ?? 0.0,
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0.0,
      activityLevel: map['activity_level'] as String? ?? 'Moderate',
      dietaryType: map['dietary_type'] as String? ?? 'General Sehat',
      dietaryPreferences: (map['dietary_preferences'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Rendah Gula', 'Tinggi Serat'],
      foodAllergies: (map['food_allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      healthGoal: map['health_goal'] as String? ?? 'Gaya Hidup Sehat Seimbang',
      isPremium: map['is_premium'] as bool? ?? false,
      isSetupCompleted: map['is_setup_completed'] as bool? ?? (rawAge > 0),
      address: map['address'] as String? ?? '',
      addressLabel: map['address_label'] as String? ?? 'Pilih Alamat',
      addressDetail: map['address_detail'] as String? ?? '',
      targetCalories: (map['target_calories'] as num?)?.toInt() ?? 2000,
      maxSugarGrams: (map['max_sugar_grams'] as num?)?.toInt() ?? 25,
      maxSodiumMg: (map['max_sodium_mg'] as num?)?.toInt() ?? 2000,
      targetProteinGrams: (map['target_protein_grams'] as num?)?.toInt() ?? 75,
      targetFiberGrams: (map['target_fiber_grams'] as num?)?.toInt() ?? 30,
      aiResponseStyle: map['ai_response_style'] as String? ?? 'Medis & Edukatif',
      autoValidateCart: map['auto_validate_cart'] as bool? ?? true,
      aiVoiceOutput: map['ai_voice_output'] as bool? ?? false,
      defaultPaymentMethod: map['default_payment_method'] as String? ?? 'QRIS Instant Pay',
      ecoPackaging: map['eco_packaging'] as bool? ?? true,
      includeCutlery: map['include_cutlery'] as bool? ?? false,
      contactlessDelivery: map['contactless_delivery'] as bool? ?? false,
      pinCode: map['pin_code'] as String? ?? '123456',
      biometricsEnabled: map['biometrics_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'activity_level': activityLevel,
      'dietary_type': dietaryType,
      'dietary_preferences': dietaryPreferences,
      'food_allergies': foodAllergies,
      'health_goal': healthGoal,
      'is_premium': isPremium,
      'is_setup_completed': isSetupCompleted,
      'address': address,
      'address_label': addressLabel,
      'address_detail': addressDetail,
      'target_calories': targetCalories,
      'max_sugar_grams': maxSugarGrams,
      'max_sodium_mg': maxSodiumMg,
      'target_protein_grams': targetProteinGrams,
      'target_fiber_grams': targetFiberGrams,
      'ai_response_style': aiResponseStyle,
      'auto_validate_cart': autoValidateCart,
      'ai_voice_output': aiVoiceOutput,
      'default_payment_method': defaultPaymentMethod,
      'eco_packaging': ecoPackaging,
      'include_cutlery': includeCutlery,
      'contactless_delivery': contactlessDelivery,
      'pin_code': pinCode,
      'biometrics_enabled': biometricsEnabled,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  String toContextPrompt() {
    return '''
User Profile & Health Parameters:
- Name: $name ($email)
- Age: $age years
- Height: ${heightCm.toInt()} cm | Weight: ${weightKg.toInt()} kg
- Activity Level: $activityLevel
- Condition/Dietary Requirement: $dietaryType
- Health Goal: $healthGoal
- Preferred Dietary Tags: ${dietaryPreferences.isEmpty ? 'None' : dietaryPreferences.join(', ')}
- Food Allergies / Intolerances: ${foodAllergies.isEmpty ? 'None' : foodAllergies.join(', ')}
- Daily Nutrition Limits: Max $maxSugarGrams g Sugar, Max $maxSodiumMg mg Sodium, Target $targetCalories kcal, Min $targetProteinGrams g Protein, Min $targetFiberGrams g Fiber
- Tone Preference: $aiResponseStyle
- Subscription Tier: ${isPremium ? 'NutriMarket Plus Member (VIP)' : 'Standard User'}
''';
  }
}
