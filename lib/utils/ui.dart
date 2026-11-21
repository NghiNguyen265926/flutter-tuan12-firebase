import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

void showMsg(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : null,
    ));
}

/// Hộp thoại "Quên mật khẩu" - gửi email đặt lại mật khẩu
Future<void> showForgotPasswordDialog(BuildContext context,
    {String initialEmail = ''}) async {
  final ctrl = TextEditingController(text: initialEmail);
  final email = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Quên mật khẩu'),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Gửi')),
      ],
    ),
  );
  if (email == null || email.isEmpty) return;
  try {
    await AuthService.instance.sendPasswordReset(email);
    if (context.mounted) {
      showMsg(context, 'Đã gửi email đặt lại mật khẩu tới $email');
    }
  } on FirebaseAuthException catch (e) {
    if (context.mounted) showMsg(context, AuthService.message(e), error: true);
  }
}
