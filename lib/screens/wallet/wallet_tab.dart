import 'package:flutter/material.dart';

import '../../services/wallet_service.dart';
import '../../widgets/balance_card.dart';
import 'amount_screen.dart';

/// Tab Wallet: số dư + nạp tiền, rút tiền, chuyển khoản
class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = WalletService();

    Widget action(IconData icon, String title, String sub, MoneyAction a) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.black12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFF1F0FF),
            child: Icon(icon, color: kWalletPurple),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AmountScreen(action: a)),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('My Wallet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        StreamBuilder(
          stream: service.watchUser(),
          builder: (context, snap) {
            final bal = ((snap.data?.data()?['balance'] ?? 0) as num).toDouble();
            return BalanceCard(balance: bal);
          },
        ),
        const SizedBox(height: 16),
        action(Icons.add_circle_outline, 'Nạp tiền (Top up)',
            'Thêm tiền vào ví', MoneyAction.topup),
        action(Icons.south_west, 'Rút tiền (Withdraw)',
            'Rút tiền từ ví về tài khoản', MoneyAction.withdraw),
        action(Icons.north_east, 'Chuyển khoản (Transfer)',
            'Chuyển tiền cho người dùng khác bằng email', MoneyAction.transfer),
      ],
    );
  }
}
