import 'generation_models.dart';
import '../../diagnostics/diagnostic_models.dart';

class FileGenerator {
  const FileGenerator();

  Future<GeneratedPatch> generatePatch({
    required String filePath,
    required String originalText,
    required String generatedText,
    bool createsFile = false,
    bool deletesFile = false,
  }) async {
    // Computes incremental replacement TextEdits
    final edits = <TextEdit>[];
    if (!deletesFile && generatedText.isNotEmpty) {
      edits.add(TextEdit(
        range: Range(
          start: const Position(line: 1, column: 1),
          end: Position(line: originalText.split('\n').length + 1, column: 1),
        ),
        newText: generatedText,
      ));
    }

    return GeneratedPatch(
      filePath: filePath,
      originalText: originalText,
      generatedText: generatedText,
      edits: edits,
      createsFile: createsFile,
      deletesFile: deletesFile,
    );
  }
}
