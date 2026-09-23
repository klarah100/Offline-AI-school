import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_ai_school/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app starts and shows learner setup', (tester) async {
    await tester.pumpWidget(const OfflineAISchoolApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Let’s personalize your learning'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
