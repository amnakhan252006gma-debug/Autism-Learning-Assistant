import 'package:flutter/material.dart';

import 'auth_screen.dart';

/// Backwards-compatible entry point retained for existing routes/tests.
/// Authentication now lives in one screen so login/register cannot diverge.
class ChildLoginScreen extends StatelessWidget {
  const ChildLoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthScreen();
}
