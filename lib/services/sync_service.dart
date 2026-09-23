import 'database.dart';
import 'connectivity_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

typedef SyncSender = Future<void> Function(List<Map<String, Object?>> attempts);

class SyncService {
  final AppDatabase database;
  final ConnectivityService connectivity;
  final SyncSender sender;

  SyncService({
    required this.database,
    required this.connectivity,
    SyncSender? sender,
  }) : sender = sender ?? _defaultSender;

  static Future<void> _defaultSender(List<Map<String, Object?>> attempts) async {
    final baseUrl = const String.fromEnvironment('OFFLINE_AI_API_URL', defaultValue: '');
    if (baseUrl.isEmpty) {
      throw StateError('No sync server configured. Learning data will remain on this device.');
    }
    final learnerId = attempts.first['learner_id']?.toString() ?? 'unknown';
    final payload = attempts.map((a) => {
      'learner_id': learnerId,
      'question_id': a['question_id'],
      'topic_id': a['topic_id'],
      'correct': a['correct'] == 1,
      'timestamp': a['timestamp'],
    }).toList();
    final response = await http.post(
      Uri.parse('$baseUrl/v1/sync/attempts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'attempts': payload}),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Sync server rejected the batch (${response.statusCode}).');
    }
  }

  Future<int> syncPending() async {
    if (!await connectivity.isOnline()) return 0;
    final rawPending = await database.pendingAttempts();
    final learnerId = await database.learnerId();
    final pending = rawPending.map((row) => {...row, 'learner_id': learnerId}).toList();
    if (pending.isEmpty) return 0;

    await sender(pending);
    await database.markAttemptsSynced(
      pending.map((row) => row['id']).whereType<int>(),
    );
    return pending.length;
  }
}
