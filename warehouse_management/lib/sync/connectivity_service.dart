import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _onlineController = StreamController<bool>.broadcast();
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;

  Stream<bool> get onlineStream => _onlineController.stream;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    // Check initial connectivity
    _isOnline = await _checkConnectivity();
    _onlineController.add(_isOnline);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) async {
      final wasOnline = _isOnline;
      _isOnline = _isConnected(result);

      if (wasOnline != _isOnline) {
        _onlineController.add(_isOnline);
        print('Connectivity changed: ${_isOnline ? 'ONLINE' : 'OFFLINE'}');

        // Trigger sync when coming back online
        if (!wasOnline && _isOnline) {
          print('Device back online - triggering sync');
          // Sync will be triggered by listeners
        }
      }
    });
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _isConnected(result);
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  bool _isConnected(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  Future<bool> checkOnline() async {
    return await _checkConnectivity();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineController.close();
  }
}
