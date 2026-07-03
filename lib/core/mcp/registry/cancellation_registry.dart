class CancellationRegistry {
  final Map<String, bool> _cancellations = {};
  void cancel(String id) => _cancellations[id] = true;
  bool isCancelled(String id) => _cancellations[id] ?? false;
}
