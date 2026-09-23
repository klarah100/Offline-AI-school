enum ConnectionState { offline, online }

class SyncItem {
  final String id;
  final Map<String, Object?> payload;

  const SyncItem({required this.id, required this.payload});
}

class SyncService {
  final List<SyncItem> _queue = [];

  ConnectionState connection = ConnectionState.offline;

  List<SyncItem> get pending => List.unmodifiable(_queue);

  void queue(String id, Map<String, Object?> payload) {
    _queue.add(SyncItem(id: id, payload: payload));
  }

  Future<int> sync() async {
    if (connection == ConnectionState.offline) return 0;

    final count = _queue.length;
    _queue.clear();
    return count;
  }
}
