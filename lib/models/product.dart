import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.imagePath,
  });

  final String id;
  final String name;
  final double price;
  final String? imageUrl; // link tải ảnh từ Storage
  final String? imagePath; // đường dẫn trên Storage (để xóa)

  factory Product.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Product(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      price: ((d['price'] ?? 0) as num).toDouble(),
      imageUrl: d['imageUrl'] as String?,
      imagePath: d['imagePath'] as String?,
    );
  }
}
