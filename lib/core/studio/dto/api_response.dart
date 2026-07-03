import 'dart:convert';

class ApiResponse {
  final bool success;
  final String timestamp;
  final String requestId;
  final String version;
  final Map<String, dynamic> data;
  final List<String> errors;

  ApiResponse({
    required this.success,
    required this.timestamp,
    required this.requestId,
    this.version = "1.0.1",
    required this.data,
    this.errors = const [],
  });

  Map<String, dynamic> toJson() => {
        "success": success,
        "timestamp": timestamp,
        "requestId": requestId,
        "version": version,
        "data": data,
        "errors": errors,
      };

  String toJsonString() => jsonEncode(toJson());
}
