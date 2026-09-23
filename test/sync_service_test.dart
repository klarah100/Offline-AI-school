import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/services/database.dart';
import '../lib/services/sync_service.dart';
import '../lib/services/connectivity_service.dart';

class FakeConnection implements ConnectionStatus {
  FakeConnection(this.online);
  final bool online;
  @override
  Future<bool> isOnline() async => online;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.clearForTests();
    await AppDatabase.instance.saveLearner(
      name: 'Test Learner',
      grade: 'Grade 6',
      language: 'English',
    );
    await AppDatabase.instance.saveAttempt(
      questionId: 'q1',
      topicId: 'fractions',
      correct: true,
    );
  });

  tearDown(() async => AppDatabase.instance.clearForTests());

  test('offline sync leaves attempts pending', () async {
    var sent = false;
    final service = SyncService(
      database: AppDatabase.instance,
      connectivity: FakeConnection(false),
      sender: (_) async => sent = true,
    );
    expect(await service.syncPending(), 0);
    expect(sent, isFalse);
    expect(await AppDatabase.instance.pendingCount(), 1);
  });

  test('successful sync marks attempts synced', () async {
    List<Map<String, Object?>>? payload;
    final service = SyncService(
      database: AppDatabase.instance,
      connectivity: FakeConnection(true),
      sender: (items) async => payload = items,
    );
    expect(await service.syncPending(), 1);
    expect(payload!.single['learner_id'], isNotNull);
    expect(payload!.single['client_id'], isNotNull);
    expect(payload!.single['difficulty'], 1);
    expect(await AppDatabase.instance.pendingCount(), 0);
  });

  test('transient sync failure retries before succeeding', () async {
    var calls = 0;
    final service = SyncService(
      database: AppDatabase.instance,
      connectivity: FakeConnection(true),
      retryDelay: Duration.zero,
      sender: (_) async {
        calls++;
        if (calls == 1) {
          throw const SyncException('temporary failure');
        }
      },
    );
    expect(await service.syncPending(), 1);
    expect(calls, 2);
    expect(await AppDatabase.instance.pendingCount(), 0);
  });

  test('failed sync never marks attempts synced', () async {
    final service = SyncService(
      database: AppDatabase.instance,
      connectivity: FakeConnection(true),
      retryDelay: Duration.zero,
      maxRetries: 1,
      sender: (_) async => throw StateError('network failure'),
    );
    expect(() => service.syncPending(), throwsA(isA<SyncException>()));
    expect(await AppDatabase.instance.pendingCount(), 1);
  });
}