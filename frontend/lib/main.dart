import 'package:flutter/material.dart';
import 'services/backend_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackendService.instance.initialize();
  runApp(const AutismLearningAssistant());
}

class AutismLearningAssistant extends StatelessWidget {
  const AutismLearningAssistant({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autism Learning Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const SplashScreen(),
    );
  }
}
