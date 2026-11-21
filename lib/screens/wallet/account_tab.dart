import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/wallet_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/ui.dart';
import '../../widgets/balance_card.dart';

/// Màn hình quản lý profile
class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final WalletService _service = WalletService();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  String _email = '';
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final snap = await _service.watchUser().first;
      final d = snap.data() ?? {};
      _nameCtrl.text = (d['displayName'] ?? '') as String;
      _phoneCtrl.text = (d['phone'] ?? '') as String;
      _email = (d['email'] ?? AuthService.instance.currentUser?.email ?? '') as String;
    } catch (e) {
      logger.e('Load profile error: $e');
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (mounted) showMsg(context, 'Đã cập nhật thông tin');
    } catch (e) {
      logger.e('Update profile error: $e');
      if (mounted) showMsg(context, 'Lỗi: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    // Đóng toàn bộ màn hình ví rồi đăng xuất -> AuthGate quay về trang đăng nhập
    Navigator.of(context).popUntil((r) => r.isFirst);
    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final initial =
        _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Account',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFF1F0FF),
            child: Text(initial,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: kWalletPurple)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(_email.isEmpty ? 'Tài khoản khách' : _email,
              style: const TextStyle(color: Colors.black54)),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
              labelText: 'Họ và tên', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
              labelText: 'Số điện thoại', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 46,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kWalletPurple),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Lưu thay đổi'),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _email.isEmpty
              ? null
              : () => showForgotPasswordDialog(context, initialEmail: _email),
          icon: const Icon(Icons.lock_reset),
          label: const Text('Đổi / quên mật khẩu (gửi email)'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label:
              const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }
}
