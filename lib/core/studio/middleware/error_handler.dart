import 'dart:io';
import '../dto/api_response.dart';

class ErrorHandler {
  static void handle(HttpRequest request, Object error, String requestId) {
    final response = ApiResponse(
      success: false,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: const {},
      errors: [error.toString()],
    );

    request.response
      ..statusCode = HttpStatus.internalServerError
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }
}
