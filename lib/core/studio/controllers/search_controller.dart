import 'dart:io';
import '../services/search_service.dart';
import '../dto/api_response.dart';

class SearchController {
  final SearchService service;

  SearchController(this.service);

  Future<void> handleSearch(HttpRequest request, String requestId) async {
    try {
      final query = request.uri.queryParameters['q'] ?? '';
      final mode = request.uri.queryParameters['mode'] ?? 'symbol';
      final pageParam = request.uri.queryParameters['page'] ?? '1';
      final pageSizeParam = request.uri.queryParameters['pageSize'] ?? '20';

      final page = int.tryParse(pageParam) ?? 1;
      final pageSize = int.tryParse(pageSizeParam) ?? 20;

      final results = await service.searchCodebase(
        query: query,
        mode: mode,
        page: page,
        pageSize: pageSize,
      );

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: {"results": results},
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      final response = ApiResponse(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {},
        errors: [e.toString()],
      );
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    }
  }
}
