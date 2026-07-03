import 'ai_response.dart';

class ExecutionResult {
  final Duration latency;
  final int retries;
  final List<String> errors;
  final String providerName;
  final AIResponse response;

  const ExecutionResult({
    required this.latency,
    required this.retries,
    required this.errors,
    required this.providerName,
    required this.response,
  });
}
