import 'package:wavezly/services/dashboard_service.dart';

/// Singleton cache for preloaded data during app bootstrap.
/// Holds dashboard summary fetched during splash/auth transition.
class BootstrapCache {
  static final BootstrapCache _instance = BootstrapCache._internal();
  factory BootstrapCache() => _instance;
  BootstrapCache._internal();

  DashboardSummary? _preloadedSummary;
  Future<void>? _preloadFuture;

  /// Get preloaded summary and clear cache (consume once).
  DashboardSummary? consumePreloadedSummary() {
    final summary = _preloadedSummary;
    _preloadedSummary = null;
    return summary;
  }

  /// Peek at preloaded summary without consuming it.
  /// Used by AuthWrapper to check if data is available for immediate navigation.
  DashboardSummary? peekPreloadedSummary() {
    return _preloadedSummary;
  }

  /// Check if preload is currently in progress.
  bool get isPreloading => _preloadFuture != null;

  /// Ensure preload is started and return the in-flight future.
  /// Deduplicates multiple calls - returns existing future if already running.
  /// Safe to call multiple times - only starts preload once.
  Future<void> ensurePreloadStarted() {
    if (_preloadFuture != null) {
      // Preload already in progress - return existing future
      return _preloadFuture!;
    }

    // Start new preload
    _preloadFuture = _executePreload();
    return _preloadFuture!;
  }

  /// Internal preload execution - uses fast local-first approach.
  Future<void> _executePreload() async {
    try {
      final service = DashboardService();
      // Use fast local-first method (cache + local DB, no remote wait)
      _preloadedSummary = await service.getSummaryLocalOrCached().timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw Exception('Preload timeout'),
      );
    } catch (e) {
      // Silent fail - app will use persistent cache or load normally
      _preloadedSummary = null;
    } finally {
      _preloadFuture = null; // Reset future so future calls can retry
    }
  }

  /// Legacy method for backwards compatibility - delegates to ensurePreloadStarted.
  Future<void> preloadDashboardSummary() async {
    return ensurePreloadStarted();
  }

  /// Clear cached data (useful for testing or logout).
  void clear() {
    _preloadedSummary = null;
    _preloadFuture = null;
  }
}
