import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  checkFirebaseConnected();
  runApp(const MyApp());
}

/// Mục 1.4 trong tài liệu: kiểm tra tình trạng kết nối đến Firebase
void checkFirebaseConnected() {
  final bool isConnected = Firebase.apps.isNotEmpty;
  logger.i('Firebase connected: $isConnected');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFE91E63),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
