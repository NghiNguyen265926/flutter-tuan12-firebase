import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import '../models/product.dart';
import '../utils/app_logger.dart';

class ProductService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('products');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Lắng nghe realtime danh sách sản phẩm (mới nhất trước)
  Stream<List<Product>> watchProducts() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromDoc).toList());
  }

  /// Upload ảnh lên Storage -> lấy URL -> lưu document vào Firestore
  Future<void> addProduct({
    required String name,
    required double price,
    File? image,
  }) async {
    String? url;
    String? imagePath;
    if (image != null) {
      final ext = path.extension(image.path);
      imagePath = 'products/${DateTime.now().millisecondsSinceEpoch}$ext';
      final ref = _storage.ref().child(imagePath);
      await ref.putFile(image);
      url = await ref.getDownloadURL();
      logger.i('Image uploaded: $url');
    }
    await _col.add({
      'name': name,
      'price': price,
      'imageUrl': url,
      'imagePath': imagePath,
      'createdAt': FieldValue.serverTimestamp(),
    });
    logger.i('Insert product successfully');
  }

  /// Xóa document trong Firestore và ảnh trên Storage
  Future<void> deleteProduct(Product product) async {
    await _col.doc(product.id).delete();
    if (product.imagePath != null) {
      try {
        await _storage.ref(product.imagePath!).delete();
      } catch (e) {
        logger.w('Không xóa được ảnh: $e');
      }
    }
  }
}
