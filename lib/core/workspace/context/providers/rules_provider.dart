import 'dart:io';
import '../workspace_context.dart';

class RulesProvider implements ContextProvider {
  @override
  Future<List<ContextContribution>> build(String rootPath) async {
    final results = <ContextContribution>[];
    final dir = Directory('$rootPath/rules');
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.md')) {
          final text = await entity.readAsString();
          results.add(ContextContribution(
            providerId: "rules",
            content: text,
            tokens: text.length ~/ 4,
            priority: 95,
            sourcePath: entity.path,
          ));
        }
      }
    }
    return results;
  }
}
