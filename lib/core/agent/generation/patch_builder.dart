import 'generation_models.dart';
import '../../diagnostics/diagnostic_models.dart';

class PatchBuilder {
  const PatchBuilder();

  // Transforms a list of GeneratedPatches into a single unified WorkspaceEdit
  WorkspaceEdit buildWorkspaceEdit(List<GeneratedPatch> patches) {
    final fileEdits = <String, List<TextEdit>>{};

    for (final patch in patches) {
      if (!patch.deletesFile) {
        fileEdits[patch.filePath] = patch.edits;
      }
    }

    return WorkspaceEdit(
      changes: fileEdits,
    );
  }
}
