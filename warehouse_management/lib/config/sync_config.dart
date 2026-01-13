class SyncConfig {
  // Sync timing
  static const int syncIntervalMinutes = 5;
  static const int syncIntervalMilliseconds = syncIntervalMinutes * 60 * 1000;

  // Batch processing
  static const int batchSize = 50;
  static const int maxRetries = 3;

  // Retry backoff (exponential)
  static const int initialRetryDelaySeconds = 60; // 1 minute
  static const int maxRetryDelaySeconds = 900; // 15 minutes

  // Sync operations
  static const String operationInsert = 'INSERT';
  static const String operationUpdate = 'UPDATE';
  static const String operationDelete = 'DELETE';

  // Sync status
  static const String statusPending = 'pending';
  static const String statusProcessing = 'processing';
  static const String statusCompleted = 'completed';
  static const String statusFailed = 'failed';

  // Tables to sync
  static const List<String> syncTables = [
    'products',
    'product_groups',
    'locations',
    'customers',
    'customer_transactions',
    'sales',
    'sale_items',
  ];

  // Retry delay calculation (exponential backoff)
  static int getRetryDelay(int retryCount) {
    final delay = initialRetryDelaySeconds * (1 << retryCount); // 2^retryCount
    return delay > maxRetryDelaySeconds ? maxRetryDelaySeconds : delay;
  }
}
