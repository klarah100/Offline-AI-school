import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectionStatus { Future<bool> isOnline(); }

class ConnectivityService implements ConnectionStatus {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _online = StreamController<bool>.broadcast();

  Stream<bool> get online => _online.stream;

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> start() async {
    _online.add(await isOnline());
    _connectivity.onConnectivityChanged.listen((results) {
      _online.add(results.any((result) => result != ConnectivityResult.none));
    });
  }

  void dispose() => _online.close();
}
