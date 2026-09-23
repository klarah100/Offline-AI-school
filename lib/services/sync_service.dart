import 'database.dart';
import 'connectivity_service.dart';

class SyncService {
  final AppDatabase database;
  final ConnectivityService connectivity;

  SyncService({
    required this.database,
    required this.connectivity,
  });

  Future<int> syncPending() async {
    if (!await connectivity.isOnline()) return 0;

    final pending = await database.pendingAttempts();
    if (pending.isEmpty) return 0;

    // Provider-agnostic MVP transport. Replace this section with the
    // authenticated backend adapter before marking records synced.
    await database.markAttemptsSynced();
    return pending.length;
  }
}
