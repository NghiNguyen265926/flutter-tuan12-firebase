import 'package:flutter/material.dart';

import '../../services/wallet_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/ui.dart';
import '../../widgets/balance_card.dart';
import 'wallet_shell.dart';

/// Chưa có ví -> màn hình giới thiệu; đã có ví -> vào thẳng ứng dụng
class WalletEntry extends StatefulWidget {
  const WalletEntry({super.key});

  @override
  State<WalletEntry> createState() => _WalletEntryState();
}

class _WalletEntryState extends State<WalletEntry> {
  final WalletService _service = WalletService();
  bool? _exists;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final exists = await _service.userExists();
      if (mounted) setState(() => _exists = exists);
    } catch (e) {
      logger.e('Check wallet error: $e');
      if (mounted) setState(() => _exists = false);
    }
  }

  Future<void> _createWallet() async {
    setState(() => _creating = true);
    try {
      await _service.ensureUserDoc();
      if (mounted) setState(() => _exists = true);
    } catch (e) {
      logger.e('Create wallet error: $e');
      if (mounted) showMsg(context, 'Không tạo được ví: $e', error: true);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_exists == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_exists == true) return const WalletShell();
    return _Onboarding(onStart: _createWallet, loading: _creating);
  }
}

class _Onboarding extends StatelessWidget {
  const _Onboarding({required this.onStart, required this.loading});

  final VoidCallback onStart;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 200,
                  height: 260,
                  decoration: BoxDecoration(
                    color: kWalletPurple,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('\$4,5790',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Icon(Icons.account_balance_wallet,
                          color: Colors.white70, size: 64),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Your next generation of financial platform',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Simple user experience meets personal finance of the future backed by decentralized finance',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kWalletPurple),
                  onPressed: loading ? null : onStart,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Sign up to zhippay'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
