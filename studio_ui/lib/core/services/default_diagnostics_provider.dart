import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/language_intelligence_models.dart';
import 'language_intelligence_providers.dart';
import 'workbench_providers.dart';

class DefaultDiagnosticsProvider implements DiagnosticsProvider {
  final int port;

  @override
  final String id = 'default-diagnostics';
  @override
  final String language = '*';
  @override
  final int version = 1;
  @override
  final int priority = 1;
  @override
  ProviderState state = ProviderState.ready;
  @override
  final ProviderMetrics metrics = ProviderMetrics();

  DefaultDiagnosticsProvider({required this.port});

  @override
  Future<void> initialize() async {}
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}

  @override
  Future<OperationResult<List<Diagnostic>>> provideDiagnostics(
    ProviderExecutionContext context,
  ) async {
    final doc = context.request.context.document;
    final revision = doc.version.localRevision;

    try {
      final res = await http.get(
        Uri.parse(
          'http://localhost:$port/api/v1/code/diagnostics?path=${doc.path}&revision=$revision',
        ),
      );
      if (res.statusCode == 200) {
        final envelope = jsonDecode(res.body);
        if (envelope["success"] == true) {
          final listData = envelope["data"]["diagnostics"] as List? ?? [];
          final list = listData
              .map((x) => Diagnostic.fromJson(x as Map<String, dynamic>))
              .toList();
          return OperationResult.ok(list);
        }
      }
      return const OperationResult.ok([]);
    } catch (e) {
      return OperationResult.fail(
        WorkbenchError(code: 'INTERNAL_ERROR', message: e.toString()),
      );
    }
  }
}
