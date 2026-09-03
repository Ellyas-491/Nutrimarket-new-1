import 'package:flutter/foundation.dart';
import 'package:clev_ai/features/products/models/food_product.dart';
import 'package:clev_ai/data/local/local_storage_service.dart';
import 'package:clev_ai/data/remote/supabase_service.dart';

class ProductRepository extends ChangeNotifier {
  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  
  ProductRepository._internal();

  final List<FoodProduct> _products = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<FoodProduct> get products => List.unmodifiable(_products);

  List<FoodProduct> get verifiedProducts =>
      _products.where((p) => p.isVerified).toList();

  Future<void> initFromSupabase() async {
    // 1. Muat cache produk lokal terlebih dahulu agar UI instan saat offline
    _loadFromLocalStorage();

    // 2. Refresh dari Supabase Cloud jika ada koneksi
    await refreshFromSupabase();
  }

  void _loadFromLocalStorage() {
    try {
      final cachedJsonList = LocalStorageService().getCachedProducts();
      if (cachedJsonList.isNotEmpty) {
        final cached = cachedJsonList.map((m) => FoodProduct.fromMap(m)).toList();
        _products.clear();
        _products.addAll(cached);
        debugPrint('[ProductRepository] Memuat ${_products.length} produk dari Local Storage cache.');
        notifyListeners();
      } else if (_products.isEmpty) {
        // Fallback default menu jika fresh install tanpa cache
        _products.clear();
        _products.addAll(_defaultFallbackProducts);
        _saveToLocalStorage();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ProductRepository] Error loading cached products: $e');
    }
  }

  void _saveToLocalStorage() {
    try {
      final listMap = _products.map((p) => p.toMap()).toList();
      LocalStorageService().saveCachedProducts(listMap);
    } catch (e) {
      debugPrint('[ProductRepository] Error saving cached products: $e');
    }
  }

  Future<void> refreshFromSupabase() async {
    _isLoading = true;
    notifyListeners();

    final supabase = SupabaseService();
    if (supabase.isConfigured) {
      try {
        final cloudProducts = await supabase.fetchProducts();
        debugPrint('[ProductRepository] Memuat ${cloudProducts.length} produk dari Supabase Database.');
        if (cloudProducts.isNotEmpty) {
          _products.clear();
          _products.addAll(cloudProducts);
          _saveToLocalStorage();
          _isLoading = false;
          notifyListeners();
          return;
        } else {
          debugPrint('[ProductRepository] Database Supabase kosong atau RLS belum diatur.');
        }
      } catch (e) {
        debugPrint('[ProductRepository] Gagal load dari Supabase (offline / network error): $e');
      }
    } else {
      debugPrint('[ProductRepository] Supabase belum terkonfigurasi di .env');
    }

    // Pastikan jika offline dan kosong, muat dari cache lokal
    if (_products.isEmpty) {
      _loadFromLocalStorage();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(FoodProduct product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.insert(0, product);
    }
    notifyListeners();

    // Simpan ke Supabase Database
    final supabase = SupabaseService();
    if (supabase.isConfigured) {
      try {
        await supabase.addProduct(product);
      } catch (e) {
        debugPrint('[ProductRepository] Gagal simpan makanan baru ke Supabase: $e');
      }
    }
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();

    final supabase = SupabaseService();
    if (supabase.isConfigured) {
      try {
        await supabase.deleteProduct(id);
      } catch (e) {
        debugPrint('[ProductRepository] Gagal hapus makanan dari Supabase: $e');
      }
    }
  }

  String _mapCategoryKey(String category) {
    final lower = category.toLowerCase().trim();
    if (lower == 'all' || lower == 'semua' || lower == 'semua produk' || lower == 'semua kategori') {
      return 'All';
    }
    if (lower == 'makanan utama' || lower == 'healthy meals' || lower == 'makanan') {
      return 'Healthy Meals';
    }
    if (lower == 'camilan sehat' || lower == 'healthy snacks' || lower == 'snack' || lower == 'camilan') {
      return 'Healthy Snacks';
    }
    if (lower == 'minuman' || lower == 'drinks' || lower == 'beverages' || lower == 'healthy beverages') {
      return 'Drinks';
    }
    return category;
  }

  List<FoodProduct> getProductsByCategory(String category) {
    final target = _mapCategoryKey(category);
    if (target == 'All') {
      return verifiedProducts;
    }
    return verifiedProducts.where((p) => p.category == target).toList();
  }

  List<FoodProduct> filterProducts({
    String? category,
    String? searchQuery,
    List<String>? suitableTags,
  }) {
    final targetCat = category != null ? _mapCategoryKey(category) : 'All';

    return verifiedProducts.where((product) {
      if (targetCat != 'All') {
        if (product.category != targetCat) return false;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchName = product.name.toLowerCase().contains(q);
        final matchCat = product.category.toLowerCase().contains(q);
        final matchTags = product.suitableFor.any((t) => t.toLowerCase().contains(q));
        if (!matchName && !matchCat && !matchTags) return false;
      }
      if (suitableTags != null && suitableTags.isNotEmpty) {
        for (final tag in suitableTags) {
          if (!product.suitableFor.contains(tag)) return false;
        }
      }
      return true;
    }).toList();
  }

  FoodProduct? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static const List<FoodProduct> _defaultFallbackProducts = [
    FoodProduct(
      id: 'prod_quinoa_bowl',
      name: 'Salmon Quinoa Super Bowl',
      category: 'Healthy Meals',
      price: 68000,
      rating: 4.9,
      reviewCount: 142,
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop&q=80',
      calories: 420,
      protein: 34.0,
      carbs: 38.0,
      fat: 12.0,
      fiber: 7.5,
      sugar: 3.0,
      sodium: 380.0,
      suitableFor: ['High Protein', 'Low Sugar', 'Diabetes-friendly'],
      ingredients: ['Norwegian Salmon', 'Organic Quinoa', 'Edamame', 'Avocado', 'Chia Seeds', 'Olive Oil'],
      allergens: ['Seafood / Ikan'],
      nutritionistName: 'dr. Alana Rahma, Sp.GK',
      nutritionistReview: 'Kaya asam lemak Omega-3 dan asam amino esensial. Sangat direkomendasikan untuk stabilitas gula darah.',
      verificationStatus: 'VERIFIED',
    ),
    FoodProduct(
      id: 'prod_chicken_breast',
      name: 'Grilled Herb Chicken & Sweet Potato',
      category: 'Healthy Meals',
      price: 54000,
      rating: 4.8,
      reviewCount: 98,
      imageUrl: 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=600&auto=format&fit=crop&q=80',
      calories: 390,
      protein: 38.0,
      carbs: 32.0,
      fat: 7.0,
      fiber: 6.0,
      sugar: 4.0,
      sodium: 320.0,
      suitableFor: ['High Protein', 'Low Fat', 'Diabetes-friendly'],
      ingredients: ['Dada Ayam Tanpa Kulit', 'Ubi Jalar Panggang', 'Brokoli Kukus', 'Rosemary', 'Bawang Putih'],
      allergens: [],
      nutritionistName: 'dr. Kevin Wijaya, M.Gizi',
      nutritionistReview: 'Rendah lemak jenuh dengan protein murni tinggi, sangat optimal untuk metabolisme dan pembentukan otot.',
      verificationStatus: 'VERIFIED',
    ),
    FoodProduct(
      id: 'prod_green_glow',
      name: 'Cold-Pressed Green Glow Detox',
      category: 'Drinks',
      price: 32000,
      rating: 4.9,
      reviewCount: 76,
      imageUrl: 'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=600&auto=format&fit=crop&q=80',
      calories: 95,
      protein: 2.5,
      carbs: 18.0,
      fat: 0.5,
      fiber: 4.0,
      sugar: 6.0,
      sodium: 45.0,
      suitableFor: ['Low Calorie', 'Low Sugar', 'Vegan', 'Gluten-Free'],
      ingredients: ['Kale Organik', 'Bayam Hijau', 'Mentimun', 'Apel Hijau Malang', 'Lemon', 'Jahe'],
      allergens: [],
      nutritionistName: 'dr. Alana Rahma, Sp.GK',
      nutritionistReview: 'Tanpa gula tambahan ataupun pengawet, kaya antioksidan klorofil untuk hidrasi seluler tubuh.',
      verificationStatus: 'VERIFIED',
    ),
    FoodProduct(
      id: 'prod_granola_chia',
      name: 'Greek Yogurt & Berry Chia Parfait',
      category: 'Healthy Snacks',
      price: 38000,
      rating: 4.8,
      reviewCount: 88,
      imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600&auto=format&fit=crop&q=80',
      calories: 240,
      protein: 16.0,
      carbs: 26.0,
      fat: 5.0,
      fiber: 6.0,
      sugar: 5.0,
      sodium: 60.0,
      suitableFor: ['High Protein', 'Low Sugar', 'Vegetarian'],
      ingredients: ['Greek Yogurt Plain', 'Wild Blueberry', 'Strawberry', 'Biji Chia', 'Almond Slice', 'Oatmeal Panggang'],
      allergens: ['Produk Susu / Milk', 'Kacang / Nuts'],
      nutritionistName: 'dr. Kevin Wijaya, M.Gizi',
      nutritionistReview: 'Mengandung probiotik alami untuk kesehatan mikrobioma pencernaan dan serat larut prebiotik.',
      verificationStatus: 'VERIFIED',
    ),
  ];
}
