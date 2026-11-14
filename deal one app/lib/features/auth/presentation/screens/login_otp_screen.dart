import 'package:flutter/material.dart';

import '../pages/login/login_page.dart';

/// Backward-compatible wrapper preserving the legacy `LoginOtpScreen` symbol
/// while delegating to the modular [LoginPage].
class LoginOtpScreen extends StatelessWidget {
  const LoginOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}
