import 'language_intelligence_models.dart';

class ProviderDiagnostics {
  final String providerId;
  final int revision;
  final List<Diagnostic> diagnostics;

  ProviderDiagnostics({
    required this.providerId,
    required this.revision,
    required this.diagnostics,
  });
}

class FileDiagnosticsCollection {
  final String path;
  final Map<String, ProviderDiagnostics> _providers = {};

  Map<String, ProviderDiagnostics> get providers => _providers;

  FileDiagnosticsCollection({required this.path});

  void update(String providerId, int revision, List<Diagnostic> diagnostics) {
    _providers[providerId] = ProviderDiagnostics(
      providerId: providerId,
      revision: revision,
      diagnostics: diagnostics,
    );
  }

  void cleanProvider(String providerId) {
    _providers.remove(providerId);
  }

  void cleanStaleRevisions(int currentRevision) {
    _providers.removeWhere(
      (providerId, value) => value.revision < currentRevision,
    );
  }

  List<Diagnostic> getActiveDiagnostics() {
    return _providers.values.expand((p) => p.diagnostics).toList();
  }
}

class DiagnosticCollection {
  final Map<String, FileDiagnosticsCollection> _files = {};

  Map<String, FileDiagnosticsCollection> get files => _files;

  Map<String, List<Diagnostic>> get groupedDiagnostics {
    final result = <String, List<Diagnostic>>{};
    _files.forEach((path, collection) {
      final active = collection.getActiveDiagnostics();
      if (active.isNotEmpty) {
        result[path] = active;
      }
    });
    return result;
  }

  List<Diagnostic> getForFile(String path) {
    return _files[path]?.getActiveDiagnostics() ?? [];
  }

  List<Diagnostic> getAll() {
    return _files.values.expand((f) => f.getActiveDiagnostics()).toList();
  }

  void updateForFile({
    required String path,
    required String providerId,
    required int revision,
    required List<Diagnostic> diagnostics,
  }) {
    final collection = _files.putIfAbsent(
      path,
      () => FileDiagnosticsCollection(path: path),
    );
    collection.update(providerId, revision, diagnostics);
  }

  void cleanFile(String path) {
    _files.remove(path);
  }

  void cleanStaleRevisions(String path, int currentRevision) {
    _files[path]?.cleanStaleRevisions(currentRevision);
  }

  void clear() {
    _files.clear();
  }
}
