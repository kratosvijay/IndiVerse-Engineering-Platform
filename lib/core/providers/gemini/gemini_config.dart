class GeminiConfig {
  final String baseUrl;
  final String apiVersion;
  final Duration timeout;
  final int retryCount;
  final Map<String, String> extraHeaders;

  const GeminiConfig({
    this.baseUrl = "https://generativelanguage.googleapis.com",
    this.apiVersion = "v1beta",
    this.timeout = const Duration(seconds: 30),
    this.retryCount = 3,
    this.extraHeaders = const {},
  });
}
