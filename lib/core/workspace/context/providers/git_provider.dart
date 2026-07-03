import 'dart:io';
import '../workspace_context.dart';

class GitProvider implements ContextProvider {
  @override
  Future<List<ContextContribution>> build(String rootPath) async {
    final file = File('$rootPath/.git/HEAD');
    if (await file.exists()) {
      final text = await file.readAsString();
      return [
        ContextContribution(
          providerId: "git",
          content: "Active branch information: $text",
          tokens: text.length ~/ 4,
          priority: 60,
          sourcePath: file.path,
        )
      ];
    }
    return [];
  }
}
