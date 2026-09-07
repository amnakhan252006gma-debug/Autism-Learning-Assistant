import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/child_button.dart';
import '../services/backend_service.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '7');
  String _selectedEmoji = '😊';
  bool _loading = false;
  String? _error;
  static const _emojis = ['😊', '🌟', '🦁', '🐶', '🦄', '🐸', '🐼', '🐵'];
  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    if (name.isEmpty || age == null || age < 1) {
      setState(() => _error = 'Please enter a valid name and age.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final child = await BackendService.instance.createChild(
        name: name,
        age: age,
        avatar: _selectedEmoji,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            childId: child['id'] as int,
            childName: child['name'].toString(),
          ),
        ),
      );
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Profile')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            Text(_selectedEmoji, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: AppTheme.spaceLG),
            const Text(
              'Pick Your Avatar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: AppTheme.spaceSM,
              runSpacing: AppTheme.spaceSM,
              alignment: WrapAlignment.center,
              children: _emojis
                  .map(
                    (e) => AvatarPicker(
                      emoji: e,
                      selected: e == _selectedEmoji,
                      onTap: () => setState(() => _selectedEmoji = e),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            const Text(
              'Your Name',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
              decoration: const InputDecoration(
                hintText: 'Type your name',
                filled: true,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Age',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
              decoration: const InputDecoration(hintText: 'Age', filled: true),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: AppTheme.spaceLG),
            ChildButton(
              label: _loading ? 'Saving...' : "Let's Go!",
              icon: Icons.arrow_forward_rounded,
              onTap: _loading ? () {} : _onContinue,
            ),
          ],
        ),
      ),
    ),
  );
}
