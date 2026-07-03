import 'dart:io';
import '../workspace_context.dart';

class PromptProvider implements ContextProvider {
  @override
  Future<List<ContextContribution>> build(String rootPath) async {
    final results = <ContextContribution>[];
    final dir = Directory('$rootPath/prompts');
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.md')) {
          final text = await entity.readAsString();
          results.add(ContextContribution(
            providerId: "prompt",
            content: text,
            tokens: text.length ~/ 4,
            priority: 70,
            sourcePath: entity.path,
          ));
        }
      }
    }
    return results;
  }
}
