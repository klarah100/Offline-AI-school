import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database.dart';
import 'connectivity_service.dart';
import 'auth_service.dart';

typedef SyncSender = Future<void> Function(List<Map<String, Object?>> attempts);

class SyncException implements Exception {
  final String message;
  final int? statusCode;
  const SyncException(this.message, {this.statusCode});
  bool get retryable => statusCode == null || statusCode == 408 || statusCode == 429 || (statusCode! >= 500);
  @override
  String toString() => message;
}

class SyncService {
  final AppDatabase database;
  final ConnectionStatus connectivity;
  final SyncSender sender;
  final Duration retryDelay;

  SyncService({
    required this.database,
    required this.connectivity,
    SyncSender? sender,
    this.retryDelay = const Duration(milliseconds: 250),
    AuthService? auth,
  }) : sender = sender ??
        (auth == null ? _defaultSender : (items) => _authenticatedSender(auth, items));

  static Future<void> _authenticatedSender(
    AuthService auth,
    List<Map<String, Object?>> attempts,
  ) async {
    if (!auth.isConfigured) {
      throw const SyncException('Sync server is not configured.');
    }

    final payload = attempts.map((a) => {
      'client_id': a['client_id'],
      'learner_id': a['learner_id'],
      'question_id': a['question_id'],
      'topic_id': a['topic_id'],
      'correct': a['correct'] == 1,
      'timestamp': a['timestamp'],
      'attempt_type': a['attempt_type'],
      'selected_answer': a['selected_answer'],
      'duration_ms': a['duration_ms'],
      'difficulty': a['difficulty'],
    }).toList();

    try {
      final response = await auth.postAuthenticated(
        '/v1/sync/attempts',
        body: {'attempts': payload},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SyncException(
          'Sync server rejected the batch (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } catch (error) {
      if (error is SyncException) rethrow;
      if (error is StateError) throw SyncException(error.message);
      throw SyncException('Sync transport failed: $error');
    }
  }

  static Future<void> _defaultSender(List<Map<String, Object?>> attempts) async {
    final baseUrl = const String.fromEnvironment('OFFLINE_AI_API_URL', defaultValue: '');
    if (baseUrl.isEmpty) {
      throw const SyncException(
        'No sync server configured. Learning data will remain on this device.',
      );
    }

    final payload = attempts.map((a) => {
      'client_id': a['client_id'],
      'learner_id': a['learner_id'],
      'question_id': a['question_id'],
      'topic_id': a['topic_id'],
      'correct': a['correct'] == 1,
      'timestamp': a['timestamp'],
      'attempt_type': a['attempt_type'],
      'selected_answer': a['selected_answer'],
      'duration_ms': a['duration_ms'],
      'difficulty': a['difficulty'],
    }).toList();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/sync/attempts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'attempts': payload}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SyncException(
          'Sync server rejected the batch (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } catch (error) {
      if (error is SyncException) rethrow;
      throw SyncException('Sync transport failed: $error');
    }
  }

  Future<int> syncPending({int maxRetries = 3}) async {
    if (!await connectivity.isOnline()) return 0;
    final pending = await database.pendingAttempts();
    if (pending.isEmpty) return 0;

    SyncException? lastError;
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await sender(pending);
        await database.markAttemptsSynced(
          pending.map((r) => r['id']).whereType<int>(),
        );
        return pending.length;
      } catch (error) {
        final syncError = error is SyncException
            ? error
            : SyncException('Sync failed: $error');
        lastError = syncError;
        if (!syncError.retryable || attempt == maxRetries - 1) {
          throw syncError;
        }
        await Future<void>.delayed(retryDelay * (1 << attempt));
        if (!await connectivity.isOnline()) break;
      }
    }
    throw lastError ?? const SyncException('Sync failed.');
  }
}
