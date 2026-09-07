import 'dart:convert';

import 'package:flutter/material.dart';

import 'parent_dashboard.dart';
import '../services/api/api_services.dart';
import '../services/app_session.dart';
import '../services/backend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_page.dart';
import '../widgets/child_button.dart';
import 'role_dashboard_screen.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

/// Parent / teacher / therapist sign-in screen.
///
/// Signing in enables the backend integration: children are loaded from the
/// server and learning results are synced to it. Without an account the app
/// continues to work fully offline.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController();

  static const List<(String, String)> _roles = [
    ('parent', 'Parent'),
    ('teacher', 'Teacher'),
    ('therapist', 'Therapist'),
  ];

  bool _isRegister = false;
  bool _busy = false;
  bool _showPassword = false;
  bool _showServerSettings = false;
  String _role = 'parent';

  @override
  void initState() {
    super.initState();
    _serverController.text =
        ApiClient.instance.baseUrl ?? ApiClient.defaultBaseUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);

    FocusScope.of(context).unfocus();

    try {
      await ApiClient.instance.setBaseUrl(_serverController.text.trim());

      final session = AppSession.instance;

      if (_isRegister) {
        await session.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role,
        );
      } else {
        await session.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (!mounted) return;

      await _routeAfterAuth();
    } on ApiException catch (error) {
      _showError(_errorMessage(error));
    } on ApiConnectionException catch (error) {
      _showError(error.message);
    } catch (error, stackTrace) {
      debugPrint('Auth request failed: $error');
      debugPrint(stackTrace.toString());

      _showError(
        'Could not reach the server (${error.runtimeType}). '
        'Check the address and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _routeAfterAuth() async {
    final user = AppSession.instance.user;

    if (user == null || !mounted) return;

    final role = user.role.toLowerCase();

    // Parents go directly to the Parent Dashboard.
    if (role == 'parent') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentDashboard()),
      );
      return;
    }

    // Teachers and therapists use their role dashboard.
    if (role == 'teacher' || role == 'therapist') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RoleDashboardScreen(role: role)),
      );
      return;
    }

    // Fallback for child/local users.
    final children = await BackendService.instance.getChildren();

    if (!mounted) return;

    if (children.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
      return;
    }

    if (children.length == 1) {
      final child = children.first;

      await BackendService.instance.selectChild(child);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            childId: child['id'] as int,
            childName: (child['name'] ?? 'Child').toString(),
          ),
        ),
      );
      return;
    }

    _showChildPicker(children);
  }

  void _showChildPicker(List<Map<String, dynamic>> children) {
    // Capture the navigator before entering the async callback.
    final navigator = Navigator.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose a child',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppTheme.spaceSM),

              ...children.map(
                (child) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text((child['avatar'] ?? '•').toString()),
                  ),
                  title: Text((child['name'] ?? 'Child').toString()),
                  subtitle: Text('Age ${child['age'] ?? '-'}'),
                  onTap: () async {
                    await BackendService.instance.selectChild(child);

                    if (!mounted) return;

                    Navigator.pop(sheetContext);

                    navigator.pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(
                          childId: child['id'] as int,
                          childName: (child['name'] ?? 'Child').toString(),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppTheme.spaceSM),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);

                  navigator.pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const ProfileSetupScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add New Child'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _errorMessage(ApiException error) {
    try {
      final body = jsonDecode(error.body);

      if (body is Map<String, dynamic> && body['detail'] is String) {
        return body['detail'] as String;
      }
    } catch (_) {
      // Fall through to the generic message.
    }

    if (error.statusCode == 401) {
      return 'Incorrect email or password.';
    }

    return 'The server rejected the request (${error.statusCode}).';
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPage(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isRegister ? 'Create Account' : 'Sign In'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLG,
                AppTheme.spaceSM,
                AppTheme.spaceLG,
                AppTheme.spaceXXL,
              ),
              children: [
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: .18),
                          blurRadius: 22,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRegister
                          ? Icons.person_add_rounded
                          : Icons.family_restroom_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spaceLG),

                Text(
                  _isRegister ? 'Create your account' : 'Welcome back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: AppTheme.spaceSM),

                Text(
                  _isRegister
                      ? 'Sign up to sync your child\u2019s learning progress.'
                      : 'Sign in to sync your child\u2019s learning progress.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: AppTheme.spaceXL),

                if (_isRegister) ...[
                  _buildLabel('Your name'),

                  TextFormField(
                    key: const ValueKey('auth_name_field'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Please enter a name'
                        : null,
                  ),

                  const SizedBox(height: AppTheme.spaceMD),

                  _buildLabel('I am a\u2026'),

                  Wrap(
                    spacing: AppTheme.spaceSM,
                    runSpacing: AppTheme.spaceSM,
                    children: [
                      for (final (value, label) in _roles)
                        ChoiceChip(
                          label: Text(label),
                          selected: _role == value,
                          onSelected: (_) => setState(() => _role = value),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spaceMD),
                ],

                _buildLabel('Email'),

                TextFormField(
                  key: const ValueKey('auth_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'Please enter a valid email'
                      : null,
                ),

                const SizedBox(height: AppTheme.spaceMD),

                _buildLabel('Password'),

                TextFormField(
                  key: const ValueKey('auth_password_field'),
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  textInputAction: _isRegister
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onFieldSubmitted: (_) => _busy ? null : _submit(),
                  validator: (value) => (value == null || value.length < 6)
                      ? 'Use at least 6 characters'
                      : null,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spaceLG),

                _buildServerSection(),

                const SizedBox(height: AppTheme.spaceLG),

                ChildButton(
                  label: _isRegister ? 'Create Account' : 'Sign In',
                  icon: _isRegister
                      ? Icons.person_add_rounded
                      : Icons.login_rounded,
                  onTap: _busy ? () {} : _submit,
                ),

                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: AppTheme.spaceMD),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                  ),

                const SizedBox(height: AppTheme.spaceLG),

                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _isRegister = !_isRegister;
                          _showPassword = false;
                        }),
                  child: Text(
                    _isRegister
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildServerSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusMD),
            ),
            onTap: () =>
                setState(() => _showServerSettings = !_showServerSettings),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceLG,
                vertical: AppTheme.spaceMD,
              ),
              child: Row(
                children: [
                  Icon(Icons.dns_rounded, size: 22, color: AppTheme.primary),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Text(
                      'Server address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showServerSettings ? .5 : 0,
                    duration: AppTheme.animationFast,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: AppTheme.animationFast,
            crossFadeState: _showServerSettings
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLG,
                0,
                AppTheme.spaceLG,
                AppTheme.spaceMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where the Autism Learning Assistant API is running.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceSM),

                  TextFormField(
                    key: const ValueKey('auth_server_field'),
                    controller: _serverController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: 'http://10.0.2.2:8000',
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
