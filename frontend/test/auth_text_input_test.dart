import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autism_learning_assistant/main.dart';
import 'package:autism_learning_assistant/screens/auth_screen.dart';
import 'package:autism_learning_assistant/screens/profile_setup_screen.dart';
import 'package:autism_learning_assistant/theme/app_theme.dart';

/// Reproduction test for "users cannot type their name or any text" on the
/// account/signup screens. Simulates real taps (hit testing) followed by
/// keyboard input on every text field.
void main() {
  setUpAll(() {
    // Keep widget tests hermetic: never fetch Google Fonts over HTTP.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreenUnderTest(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.themeData, home: screen),
    );
    // Let the AnimatedPage entrance animation finish.
    await tester.pumpAndSettle();
  }

  /// Taps the field, asserts it actually gained focus (proves nothing is
  /// blocking touches), then types [text] through the keyboard channel.
  Future<void> typeIntoField(WidgetTester tester, Key key, String text) async {
    final field = find.byKey(key);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    expect(
      editable.focusNode.hasFocus,
      isTrue,
      reason: 'tapping the field must give it keyboard focus',
    );

    await tester.enterText(field, text);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: field, matching: find.text(text)),
      findsOneWidget,
      reason: 'typed text must appear inside the field',
    );
  }

  testWidgets('auth screen: register fields accept typing', (tester) async {
    await pumpScreenUnderTest(tester, const AuthScreen());

    // Switch to the create-account (signup) mode.
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);

    await typeIntoField(tester, const ValueKey('auth_name_field'), 'Test Parent');
    await typeIntoField(tester, const ValueKey('auth_email_field'), 'a@b.co');
    await typeIntoField(tester, const ValueKey('auth_password_field'), 'secret1');
  });

  testWidgets('auth screen: login fields accept typing', (tester) async {
    await pumpScreenUnderTest(tester, const AuthScreen());

    await typeIntoField(tester, const ValueKey('auth_email_field'), 'a@b.co');
    await typeIntoField(tester, const ValueKey('auth_password_field'), 'secret1');

    // The collapsible server field must also accept typing once revealed.
    await tester.tap(find.text('Server address'));
    await tester.pumpAndSettle();
    // Note: typed text must differ from the field's hintText, otherwise the
    // hint itself satisfies find.text as well.
    await typeIntoField(
      tester,
      const ValueKey('auth_server_field'),
      'http://192.168.1.20:9000',
    );
  });

  testWidgets(
    'real app entry: splash → login screen → auth screen typing works',
    (tester) async {
      await pumpScreenUnderTest(tester, const AutismLearningAssistant());

      // Advance past the 2-second splash navigation timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Who is learning today?'), findsOneWidget);

      await tester.tap(find.text('Sign in to sync progress'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);

      await tester.tap(find.text('New here? Create an account'));
      await tester.pumpAndSettle();

      await typeIntoField(
        tester,
        const ValueKey('auth_name_field'),
        'Real App Test',
      );
      await typeIntoField(
        tester,
        const ValueKey('auth_email_field'),
        'real@app.test',
      );
    },
  );

  testWidgets('profile setup screen: name field accepts typing', (
    tester,
  ) async {
    await pumpScreenUnderTest(tester, const ProfileSetupScreen());

    final field = find.byType(TextField);
    // Clear the pre-filled demo name ("Alex") like a user would.
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);

    await tester.enterText(field, 'Maya');
    await tester.pumpAndSettle();
    expect(find.text('Maya'), findsOneWidget);
  });
}
