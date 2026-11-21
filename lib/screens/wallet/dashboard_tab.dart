import 'package:flutter/material.dart';

import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../utils/ui.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/tx_tile.dart';
import 'amount_screen.dart';
import 'transactions_screen.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final service = WalletService();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            const Text('zhippay',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F0FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.card_giftcard, size: 14),
                  SizedBox(width: 4),
                  Text('rewards', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.notifications_none),
          ],
        ),
        const SizedBox(height: 16),

        // Số dư + 4 nút nhanh
        StreamBuilder(
          stream: service.watchUser(),
          builder: (context, snap) {
            final bal = ((snap.data?.data()?['balance'] ?? 0) as num).toDouble();
            return BalanceCard(
              balance: bal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Top Up',
                    onTap: () =>
                        _open(context, const AmountScreen(action: MoneyAction.topup)),
                  ),
                  _QuickAction(
                    icon: Icons.north_east,
                    label: 'Transfer',
                    onTap: () => _open(
                        context, const AmountScreen(action: MoneyAction.transfer)),
                  ),
                  _QuickAction(
                    icon: Icons.south_west,
                    label: 'Withdraw',
                    onTap: () => _open(
                        context, const AmountScreen(action: MoneyAction.withdraw)),
                  ),
                  _QuickAction(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () => _open(context, const TransactionsScreen()),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Upgrade account
        InkWell(
          onTap: () => showMsg(context, 'Tính năng sắp ra mắt'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.workspace_premium_outlined, color: kWalletPurple),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upgrade Account',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Upgrade account for more features',
                          style: TextStyle(fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        StreamBuilder<List<WalletTx>>(
          stream: service.watchTransactions(limit: 50),
          builder: (context, snap) {
            final txs = snap.data ?? const <WalletTx>[];
            // Danh sách email đã chuyển gần đây (không trùng)
            final recent = <String>[];
            for (final t in txs) {
              if (t.type == TxType.transferOut &&
                  t.counterparty.isNotEmpty &&
                  !recent.contains(t.counterparty)) {
                recent.add(t.counterparty);
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transfer again',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 76,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _Avatar(
                        label: 'Add new',
                        child: const Icon(Icons.add, color: kWalletPurple),
                        onTap: () => _open(context,
                            const AmountScreen(action: MoneyAction.transfer)),
                      ),
                      for (final email in recent.take(8))
                        _Avatar(
                          label: email.split('@').first,
                          child: Text(email[0].toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kWalletPurple)),
                          onTap: () => _open(
                              context,
                              AmountScreen(
                                  action: MoneyAction.transfer,
                                  initialEmail: email)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Latest transaction',
                        style:
                            TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _open(context, const TransactionsScreen()),
                      child: const Text('see all'),
                    ),
                  ],
                ),
                if (txs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Chưa có giao dịch nào',
                        style: TextStyle(color: Colors.black45)),
                  )
                else
                  for (final t in txs.take(5)) TxTile(tx: t),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label, required this.child, required this.onTap});

  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF1F0FF),
                child: child),
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: Text(label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
