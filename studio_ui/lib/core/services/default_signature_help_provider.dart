import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/language_intelligence_models.dart';
import 'language_intelligence_providers.dart';
import 'workbench_providers.dart';

class DefaultSignatureHelpProvider implements SignatureHelpProvider {
  final int port;

  @override
  final String id = 'default-signature';
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

  DefaultSignatureHelpProvider({required this.port});

  @override
  Future<void> initialize() async {}
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}

  @override
  Future<OperationResult<SignatureHelp>> provideSignatureHelp(
    ProviderExecutionContext context,
  ) async {
    final doc = context.request.context.document;
    final pos = context.request.context.position;
    final revision = doc.version.localRevision;
    final token = context.request.context.token;

    try {
      final client = http.Client();
      final url = Uri.parse(
        'http://localhost:$port/api/v1/code/signatureHelp?path=${Uri.encodeComponent(doc.path)}&line=${pos.line}&column=${pos.column}&revision=$revision',
      );

      final responseFuture = client.get(url);

      final http.Response res = await responseFuture.timeout(
        const Duration(seconds: 3),
      );

      if (token.isCancelled) {
        return const OperationResult.fail(
          WorkbenchError(code: 'CANCELLED', message: 'Request was cancelled.'),
        );
      }

      if (doc.version.localRevision != revision) {
        return const OperationResult.fail(
          WorkbenchError(
            code: 'STALE_REVISION',
            message: 'Revision has changed.',
          ),
        );
      }

      if (res.statusCode == 200) {
        final envelope = jsonDecode(res.body);
        if (envelope["success"] == true) {
          final data = envelope["data"] as Map<String, dynamic>;
          final signatureHelpData =
              data["signatureHelp"] as Map<String, dynamic>;
          final signatureHelp = SignatureHelp.fromJson(signatureHelpData);
          return OperationResult.ok(signatureHelp);
        }
      }

      return const OperationResult.ok(SignatureHelp(signatures: []));
    } catch (e) {
      if (token.isCancelled) {
        return const OperationResult.fail(
          WorkbenchError(code: 'CANCELLED', message: 'Request was cancelled.'),
        );
      }
      return OperationResult.fail(
        WorkbenchError(code: 'INTERNAL_ERROR', message: e.toString()),
      );
    }
  }
}
