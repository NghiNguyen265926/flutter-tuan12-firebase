import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/ui.dart';
import 'register_screen.dart';

/// Bài tập 5.1 - Giao diện đăng nhập
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _pink = Color(0xFFE91E63);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _auth = AuthService.instance;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      logger.e('Auth error: ${e.code} - ${e.message}');
      if (mounted) showMsg(context, AuthService.message(e), error: true);
    } catch (e) {
      logger.e('Error: $e');
      if (mounted) showMsg(context, 'Đã có lỗi: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _signIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      showMsg(context, 'Vui lòng nhập email và mật khẩu', error: true);
      return;
    }
    _run(() async {
      await _auth.signIn(email, password);
    });
  }

  void _googleSignIn() {
    _run(() async {
      final cred = await _auth.signInWithGoogle();
      if (cred == null && mounted) {
        showMsg(context, 'Bạn đã hủy đăng nhập Google');
      }
    });
  }

  void _guest() {
    _run(() async {
      await _auth.signInAnonymously();
    });
  }

  void _notSupported(String name) {
    showMsg(context, 'Đăng nhập $name chưa được cấu hình trong bài này');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Appwrite App'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading) const LinearProgressIndicator(color: _pink),
                const SizedBox(height: 12),
                _field(_emailController, 'Email', false),
                const SizedBox(height: 12),
                _field(_passwordController, 'Password', true),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: _loading ? null : _signIn,
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text('Sign in'),
                  ),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                  child: const Text('Create Account',
                      style: TextStyle(color: _pink, fontSize: 12)),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => showForgotPasswordDialog(context,
                          initialEmail: _emailController.text.trim()),
                  child: const Text('Forgot password?',
                      style: TextStyle(color: _pink, fontSize: 12)),
                ),
                TextButton(
                  onPressed: _loading ? null : _guest,
                  child: const Text('Read Messages as Guest',
                      style: TextStyle(color: _pink, fontSize: 12)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(
                      onTap: _loading ? null : _googleSignIn,
                      child: const Text('G',
                          style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                    _SocialButton(
                      onTap: () => _notSupported('Apple'),
                      child: const Icon(Icons.apple, size: 18),
                    ),
                    _SocialButton(
                      onTap: () => _notSupported('GitHub'),
                      child: const Icon(Icons.code, size: 18),
                    ),
                    _SocialButton(
                      onTap: () => _notSupported('Twitter'),
                      child: const Icon(Icons.alternate_email,
                          size: 18, color: Color(0xFF1DA1F2)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, bool obscure) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType:
          obscure ? TextInputType.visiblePassword : TextInputType.emailAddress,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.white,
        elevation: 1.5,
        borderRadius: BorderRadius.circular(3),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: 46, height: 30, child: Center(child: child)),
        ),
      ),
    );
  }
}
