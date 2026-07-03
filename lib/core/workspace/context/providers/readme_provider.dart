import 'dart:io';
import '../workspace_context.dart';

class ReadmeProvider implements ContextProvider {
  @override
  Future<List<ContextContribution>> build(String rootPath) async {
    final file = File('$rootPath/README.md');
    if (await file.exists()) {
      final text = await file.readAsString();
      return [
        ContextContribution(
          providerId: "readme",
          content: text,
          tokens: text.length ~/ 4,
          priority: 80,
          sourcePath: file.path,
        )
      ];
    }
    return [];
  }
}
