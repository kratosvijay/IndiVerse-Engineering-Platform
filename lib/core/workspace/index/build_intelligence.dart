enum DiagnosticSeverity {
  error,
  warning,
  info
}

enum DiagnosticOrigin {
  analyzer,
  compiler,
  flutterTest,
  runtime
}

class BuildDiagnostic {
  final DiagnosticSeverity severity;
  final String message;
  final String? filePath;
  final int? line;
  final int? column;
  final String? errorCode;
  final String? stackTrace;
  final DiagnosticOrigin origin;

  const BuildDiagnostic({
    required this.severity,
    required this.message,
    this.filePath,
    this.line,
    this.column,
    this.errorCode,
    this.stackTrace,
    required this.origin,
  });

  Map<String, dynamic> toJson() => {
        'severity': severity.name,
        'message': message,
        'filePath': filePath,
        'line': line,
        'column': column,
        'errorCode': errorCode,
        'stackTrace': stackTrace,
        'origin': origin.name,
      };
}

class BuildIntelligence {
  final List<BuildDiagnostic> _diagnostics = [];
  String? _compilerOutput;

  void addDiagnostic(BuildDiagnostic diagnostic) {
    _diagnostics.add(diagnostic);
  }

  void addDiagnostics(List<BuildDiagnostic> list) {
    _diagnostics.addAll(list);
  }

  void setCompilerOutput(String? output) {
    _compilerOutput = output;
  }

  void clear() {
    _diagnostics.clear();
    _compilerOutput = null;
  }

  List<BuildDiagnostic> get diagnostics => List.unmodifiable(_diagnostics);
  
  List<BuildDiagnostic> getErrors() =>
      _diagnostics.where((d) => d.severity == DiagnosticSeverity.error).toList();

  List<BuildDiagnostic> getByOrigin(DiagnosticOrigin origin) =>
      _diagnostics.where((d) => d.origin == origin).toList();

  String? get compilerOutput => _compilerOutput;

  bool get hasBuildFailures =>
      _diagnostics.any((d) => d.severity == DiagnosticSeverity.error) ||
      (_compilerOutput != null && _compilerOutput!.contains("Failed"));
}
