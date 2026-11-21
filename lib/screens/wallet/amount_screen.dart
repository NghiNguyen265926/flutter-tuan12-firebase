import 'package:flutter/material.dart';

import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/format.dart';
import '../../utils/ui.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/num_pad.dart';

enum MoneyAction { topup, withdraw, transfer }

/// Màn hình nhập số tiền (Nạp tiền / Rút tiền / Chuyển khoản) - dùng bàn phím số
class AmountScreen extends StatefulWidget {
  const AmountScreen({super.key, required this.action, this.initialEmail = ''});

  final MoneyAction action;
  final String initialEmail;

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  final WalletService _service = WalletService();
  late final TextEditingController _emailCtrl =
      TextEditingController(text: widget.initialEmail);
  final TextEditingController _noteCtrl = TextEditingController();
  String _input = '0';
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.action) {
      case MoneyAction.topup:
        return 'Top Up';
      case MoneyAction.withdraw:
        return 'Withdraw';
      case MoneyAction.transfer:
        return 'Send Money';
    }
  }

  String get _buttonText {
    switch (widget.action) {
      case MoneyAction.topup:
        return 'Top up';
      case MoneyAction.withdraw:
        return 'Withdraw';
      case MoneyAction.transfer:
        return 'Send money';
    }
  }

  void _onKey(String k) {
    setState(() {
      if (k == '<') {
        _input = _input.length <= 1 ? '0' : _input.substring(0, _input.length - 1);
      } else if (k == '.') {
        if (!_input.contains('.')) _input += '.';
      } else {
        if (_input == '0') {
          _input = k;
        } else {
          final dot = _input.indexOf('.');
          if (dot != -1 && _input.length - dot > 2) return; // tối đa 2 số lẻ
          if (_input.length >= 10) return;
          _input += k;
        }
      }
    });
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_input) ?? 0;
    if (amount <= 0) {
      showMsg(context, 'Vui lòng nhập số tiền lớn hơn 0', error: true);
      return;
    }
    if (widget.action == MoneyAction.transfer &&
        _emailCtrl.text.trim().isEmpty) {
      showMsg(context, 'Vui lòng nhập email người nhận', error: true);
      return;
    }
    setState(() => _loading = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (widget.action) {
        case MoneyAction.topup:
          await _service.topUp(amount);
          break;
        case MoneyAction.withdraw:
          await _service.withdraw(amount);
          break;
        case MoneyAction.transfer:
          await _service.transfer(
            toEmail: _emailCtrl.text,
            amount: amount,
            note: _noteCtrl.text.trim(),
          );
          break;
      }
      navigator.pop();
      messenger.showSnackBar(
          SnackBar(content: Text('$_buttonText thành công: ${formatMoney(amount)}')));
    } on WalletException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    } catch (e) {
      logger.e('Transaction error: $e');
      if (mounted) showMsg(context, 'Lỗi: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(_title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Số dư hiện tại
              StreamBuilder(
                stream: _service.watchUser(),
                builder: (context, snap) {
                  final bal =
                      ((snap.data?.data()?['balance'] ?? 0) as num).toDouble();
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined),
                        const SizedBox(width: 10),
                        const Text('Wallet balance'),
                        const Spacer(),
                        Text(formatMoney(bal),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
              if (widget.action == MoneyAction.transfer) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Email người nhận',
                        isDense: true,
                        border: OutlineInputBorder()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Ghi chú (tuỳ chọn)',
                        isDense: true,
                        border: OutlineInputBorder()),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Text('\$$_input',
                  style: const TextStyle(
                      fontSize: 38, fontWeight: FontWeight.bold)),
              const SizedBox(height: 28),
              NumPad(onKey: _onKey),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style:
                        FilledButton.styleFrom(backgroundColor: kWalletPurple),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_buttonText),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
