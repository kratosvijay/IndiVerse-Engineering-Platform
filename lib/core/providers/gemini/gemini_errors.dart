import '../../models/exceptions.dart';

class GeminiErrorTranslator {
  static AIException translate(int statusCode, String body) {
    final message = "Gemini API error (Status $statusCode): $body";
    if (statusCode == 429) {
      return RateLimitException(
        message,
        retryAfter: const Duration(seconds: 60),
        remainingRequests: 0,
        quotaType: "requests_per_minute",
        providerMessage: body,
      );
    }
    if (statusCode == 401 || statusCode == 403) {
      return AuthenticationException(message);
    }
    if (statusCode >= 500) {
      return ProviderException(message);
    }
    return ProviderException(message);
  }
}
