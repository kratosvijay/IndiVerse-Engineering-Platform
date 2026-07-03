import 'dart:io';

class RequestLogger {
  static String logAndGenerateId(HttpRequest request) {
    final requestId = "req-${DateTime.now().microsecondsSinceEpoch}";
    print(
        "[Studio Server] [${DateTime.now().toIso8601String()}] [$requestId] ${request.method} ${request.uri.path}");
    return requestId;
  }
}
