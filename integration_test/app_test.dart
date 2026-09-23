import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_ai_school/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and completes learner setup', (tester) async {
    await tester.pumpWidget(const OfflineAISchoolApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Let’s personalize your learning'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Pilot Learner');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.textContaining('Diagnostic 1/5'), findsOneWidget);
    expect(find.text('Let’s find your starting point'), findsOneWidget);
  });
}
