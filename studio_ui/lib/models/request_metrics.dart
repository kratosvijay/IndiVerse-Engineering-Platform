class RequestMetrics {
  final String requestId;
  final DateTime started;
  final DateTime? firstToken;
  final DateTime? completed;
  final int retries;
  final bool cancelled;

  const RequestMetrics({
    required this.requestId,
    required this.started,
    this.firstToken,
    this.completed,
    this.retries = 0,
    this.cancelled = false,
  });

  int? get latencyMs => completed?.difference(started).inMilliseconds;
  int? get ttftMs => firstToken?.difference(started).inMilliseconds;
  int? get streamDurationMs => (completed != null && firstToken != null)
      ? completed!.difference(firstToken!).inMilliseconds
      : null;

  RequestMetrics copyWith({
    DateTime? firstToken,
    DateTime? completed,
    int? retries,
    bool? cancelled,
  }) {
    return RequestMetrics(
      requestId: requestId,
      started: started,
      firstToken: firstToken ?? this.firstToken,
      completed: completed ?? this.completed,
      retries: retries ?? this.retries,
      cancelled: cancelled ?? this.cancelled,
    );
  }
}
