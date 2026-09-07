import 'package:flutter_test/flutter_test.dart';
import 'package:autism_learning_assistant/main.dart';

void main() {
  testWidgets('App starts with SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const AutismLearningAssistant());

    // Pump a single frame to let the animation start
    await tester.pump();

    // Verify the splash screen shows the app title
    expect(find.text('Learning\nAssistant'), findsOneWidget);
    expect(find.text('Learn · Play · Grow'), findsOneWidget);

    // Advance past the 2-second navigation timer so no timers are pending
    await tester.pump(const Duration(seconds: 3));
  });
}
