class RequestContext {
  final String requestId;
  final bool isCancelled;

  const RequestContext({
    required this.requestId,
    required this.isCancelled,
  });
}
