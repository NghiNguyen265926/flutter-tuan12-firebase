import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/format.dart';
import '../../utils/ui.dart';
import 'product_form_screen.dart';

/// Bài tập 5.3 - Danh sách sản phẩm (Storage + Firestore)
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  static const Color _purple = Color(0xFF6A3DF0);

  Future<void> _confirmDelete(
      BuildContext context, ProductService service, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc muốn xóa "${p.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await service.deleteProduct(p);
      if (context.mounted) showMsg(context, 'Đã xóa "${p.name}"');
    } catch (e) {
      logger.e('Delete product error: $e');
      if (context.mounted) showMsg(context, 'Lỗi: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ProductService();
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1FF),
      appBar: AppBar(
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Products',
            style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF5B2EE8)],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.shopping_cart_outlined,
                color: Colors.white, size: 18),
            label: const Text('Cart', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: service.watchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!;
          if (products.isEmpty) {
            return const Center(child: Text('Chưa có sản phẩm nào'));
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListView.separated(
                itemCount: products.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 80, endIndent: 16),
                itemBuilder: (_, i) {
                  final p = products[i];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 56,
                        height: 56,
                        color: const Color(0xFFEDE7FF),
                        child: p.imageUrl != null
                            ? Image.network(
                                p.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.pedal_bike,
                                    color: _purple),
                              )
                            : const Icon(Icons.pedal_bike, color: _purple),
                      ),
                    ),
                    title: Text(p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(formatMoney(p.price)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () => _confirmDelete(context, service, p),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
