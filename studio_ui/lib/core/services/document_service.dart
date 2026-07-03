import '../../models/ids.dart';
import '../../models/editor_document.dart';

class DocumentService {
  final Map<DocumentId, EditorDocument> _documents = {};
  final Map<DocumentId, List<Map<String, dynamic>>> _outlines = {};
  final Map<DocumentId, List<String>> _diagnostics = {};

  void cacheDocument(DocumentId id, EditorDocument doc) {
    _documents[id] = doc;
  }

  EditorDocument? getDocument(DocumentId id) {
    return _documents[id];
  }

  void removeDocument(DocumentId id) {
    _documents.remove(id);
    _outlines.remove(id);
    _diagnostics.remove(id);
  }

  void cacheOutline(DocumentId id, List<Map<String, dynamic>> outline) {
    _outlines[id] = outline;
  }

  List<Map<String, dynamic>>? getOutline(DocumentId id) {
    return _outlines[id];
  }

  void cacheDiagnostics(DocumentId id, List<String> diags) {
    _diagnostics[id] = diags;
  }

  List<String>? getDiagnostics(DocumentId id) {
    return _diagnostics[id];
  }

  void clear() {
    _documents.clear();
    _outlines.clear();
    _diagnostics.clear();
  }
}
