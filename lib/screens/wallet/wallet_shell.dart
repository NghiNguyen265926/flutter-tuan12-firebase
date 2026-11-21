import 'package:flutter/material.dart';

import '../../widgets/balance_card.dart';
import 'account_tab.dart';
import 'dashboard_tab.dart';
import 'stats_tab.dart';
import 'wallet_tab.dart';

/// Khung ứng dụng ví với thanh điều hướng 4 tab
class WalletShell extends StatefulWidget {
  const WalletShell({super.key});

  @override
  State<WalletShell> createState() => _WalletShellState();
}

class _WalletShellState extends State<WalletShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Không dùng IndexedStack để mỗi lần đổi tab dữ liệu được tải lại
    final tabs = <Widget>[
      const DashboardTab(),
      const WalletTab(),
      const StatsTab(),
      const AccountTab(),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: tabs[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        indicatorColor: kWalletPurple.withOpacity(0.15),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Statistics'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Account'),
        ],
      ),
    );
  }
}
