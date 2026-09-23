import 'database.dart';
import 'connectivity_service.dart';

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
    // Deliberately does nothing until a real authenticated backend is configured.
    // Records must never be marked synced without a successful server acknowledgement.
  }

  Future<int> syncPending() async {
    if (!await connectivity.isOnline()) return 0;
    final pending = await database.pendingAttempts();
    if (pending.isEmpty) return 0;

    await sender(pending);
    await database.markAttemptsSynced(
      pending.map((row) => row['id']).whereType<int>(),
    );
    return pending.length;
  }
}
