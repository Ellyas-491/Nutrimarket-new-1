import 'package:clev_ai/features/products/models/food_product.dart';

class CartItem {
  final FoodProduct product;
  int quantity;
  String sellerNotes;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.sellerNotes = '',
  });

  double get totalPrice => product.price * quantity;
}
