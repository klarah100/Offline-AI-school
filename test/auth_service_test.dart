import 'package:flutter_test/flutter_test.dart';
import 'package:offline_ai_school/services/auth_service.dart';

void main() {
  test('parses authenticated learner metadata', () {
    final user = AuthUser.fromJson({
      'id': 'u1',
      'username': 'learner.one',
      'displayName': 'Learner One',
      'role': 'learner',
      'schoolId': 'school-1',
      'learnerId': 'learner-1',
      'grade': 'Grade 6',
    });

    expect(user.id, 'u1');
    expect(user.role, 'learner');
    expect(user.learnerId, 'learner-1');
    expect(user.grade, 'Grade 6');
  });
}