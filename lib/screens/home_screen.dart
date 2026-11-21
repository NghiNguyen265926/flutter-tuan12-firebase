import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'products/product_list_screen.dart';
import 'upload/upload_screen.dart';
import 'wallet/wallet_entry.dart';

/// Màn hình chính: chọn bài tập
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final who = user == null
        ? ''
        : user.isAnonymous
            ? 'Khách (ẩn danh)'
            : (user.displayName?.isNotEmpty == true
                ? '${user.displayName} (${user.email})'
                : user.email ?? user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Lab - Chương 5'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.instance.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Đã đăng nhập'),
              subtitle: Text(who),
            ),
          ),
          const SizedBox(height: 8),
          _menu(
            context,
            icon: Icons.cloud_upload_outlined,
            title: 'Bài tập 2 - Upload file',
            subtitle: 'Firebase Storage: tiến trình %, pause/resume/stop',
            page: const UploadScreen(),
          ),
          _menu(
            context,
            icon: Icons.pedal_bike,
            title: 'Bài tập 3 - Quản lý sản phẩm',
            subtitle: 'Firebase Storage + Firestore: danh sách, thêm, xóa',
            page: const ProductListScreen(),
          ),
          _menu(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Bài về nhà - Ví điện tử zhippay',
            subtitle: 'Nạp/rút/chuyển tiền, profile, thống kê dòng tiền',
            page: const WalletEntry(),
          ),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Widget page}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}
