import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Online / offline source. The network interface can be up while the
/// internet is down, so the real implementation also checks reachability.
abstract class ConnectivitySource {
  Stream<bool> get onlineChanges;
  Future<bool> checkOnline();
}

class PlusConnectivitySource implements ConnectivitySource {
  PlusConnectivitySource([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get onlineChanges async* {
    await for (final results in _connectivity.onConnectivityChanged) {
      yield await _reachable(results);
    }
  }

  @override
  Future<bool> checkOnline() async =>
      _reachable(await _connectivity.checkConnectivity());

  Future<bool> _reachable(List<ConnectivityResult> results) async {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return false;
    }
    // Reachable if DNS resolves OR a plain TCP connection succeeds; either
    // alone can fail on some networks (IPv6-only, DNS filtering).
    try {
      final addresses = await InternetAddress.lookup(
        'www.themealdb.com',
      ).timeout(const Duration(seconds: 4));
      if (addresses.isNotEmpty) return true;
    } catch (_) {}
    try {
      final addresses = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 4));
      if (addresses.isNotEmpty) return true;
    } catch (_) {}
    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (_) {}
    // If the device has an active network connection (mobile data or wifi)
    // but strict probes were filtered, assume online and let the actual
    // HTTP requests proceed instead of prematurely locking the UI offline.
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
  }
}

enum ConnectionStatus { online, offline }

class ConnectivityCubit extends Cubit<ConnectionStatus> {
  ConnectivityCubit(this._source) : super(ConnectionStatus.online) {
    _sub = _source.onlineChanges.listen(_map);
    _source.checkOnline().then(_map);
  }

  final ConnectivitySource _source;
  late final StreamSubscription<bool> _sub;

  void _map(bool online) {
    if (!isClosed) {
      emit(online ? ConnectionStatus.online : ConnectionStatus.offline);
    }
  }

  bool get isOnline => state == ConnectionStatus.online;

  /// Re-checks reachability on demand (e.g. a Retry button).
  Future<void> refresh() async => _map(await _source.checkOnline());

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
