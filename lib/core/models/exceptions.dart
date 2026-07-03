abstract class AIException implements Exception {
  final String message;
  const AIException(this.message);

  @override
  String toString() => "AIException: $message";
}

class ProviderException extends AIException {
  const ProviderException(String message) : super(message);
}

class RateLimitException extends AIException {
  final Duration? retryAfter;
  final int? remainingRequests;
  final String? quotaType;
  final String? providerMessage;

  const RateLimitException(
    String message, {
    this.retryAfter,
    this.remainingRequests,
    this.quotaType,
    this.providerMessage,
  }) : super(message);

  @override
  String toString() =>
      "RateLimitException: $message (Retry After: $retryAfter, Remaining: $remainingRequests, Quota: $quotaType)";
}

class AuthenticationException extends AIException {
  const AuthenticationException(String message) : super(message);
}

class CapabilityException extends AIException {
  const CapabilityException(String message) : super(message);
}

class BudgetExceededException extends AIException {
  const BudgetExceededException(String message) : super(message);
}

class TimeoutException extends AIException {
  const TimeoutException(String message) : super(message);
}
