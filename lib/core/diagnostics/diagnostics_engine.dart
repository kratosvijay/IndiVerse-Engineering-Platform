import 'dart:io';
import 'diagnostic_models.dart';

abstract class DiagnosticRule {
  bool supports(String language);
  Iterable<Diagnostic> analyze(DocumentSnapshot document);
}

abstract class DiagnosticSource {
  String get id;
  Iterable<Diagnostic> run(DocumentSnapshot document);
}

class DartSyntaxRule implements DiagnosticRule {
  @override
  bool supports(String language) => language == 'dart';

  @override
  Iterable<Diagnostic> analyze(DocumentSnapshot document) {
    final diagnostics = <Diagnostic>[];
    final lines = document.lines;

    int braceCount = 0;
    int parenCount = 0;
    int bracketCount = 0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Skip commented lines simple check
      if (line.trim().startsWith('//') ||
          line.trim().startsWith('/*') ||
          line.trim().startsWith('*')) {
        continue;
      }
      for (int j = 0; j < line.length; j++) {
        final char = line[j];
        if (char == '{')
          braceCount++;
        else if (char == '}')
          braceCount--;
        else if (char == '(')
          parenCount++;
        else if (char == ')')
          parenCount--;
        else if (char == '[')
          bracketCount++;
        else if (char == ']') bracketCount--;
      }
    }

    if (braceCount != 0 || parenCount != 0 || bracketCount != 0) {
      String mismatchMsg = 'Syntax Mismatch:';
      if (braceCount != 0) mismatchMsg += ' unclosed curly braces ({})';
      if (parenCount != 0) mismatchMsg += ' unclosed parentheses (())';
      if (bracketCount != 0) mismatchMsg += ' unclosed brackets ([])';

      diagnostics.add(Diagnostic(
        id: '${document.path}-syntax-mismatch',
        range: Range(
          start: Position(line: lines.length, column: 1),
          end: Position(line: lines.length, column: lines.last.length + 1),
        ),
        severity: DiagnosticSeverity.error,
        code: 'DART_SYNTAX_MISMATCH',
        source: 'regex',
        message: mismatchMsg,
      ));
    }
    return diagnostics;
  }
}

class DartDeprecationRule implements DiagnosticRule {
  @override
  bool supports(String language) => language == 'dart';

  @override
  Iterable<Diagnostic> analyze(DocumentSnapshot document) {
    final diagnostics = <Diagnostic>[];
    final lines = document.lines;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final idx = line.indexOf('.withOpacity(');
      if (idx != -1) {
        diagnostics.add(Diagnostic(
          id: '${document.path}-line-${i + 1}-deprecation',
          range: Range(
            start: Position(line: i + 1, column: idx + 2),
            end: Position(line: i + 1, column: idx + 13),
          ),
          severity: DiagnosticSeverity.warning,
          code: 'DART_DEPRECATED_WITH_OPACITY',
          source: 'regex',
          message:
              "'withOpacity' is deprecated. Use '.withValues()' to avoid precision loss.",
          tags: [DiagnosticTag.deprecated],
        ));
      }
    }
    return diagnostics;
  }
}

class JsonSyntaxRule implements DiagnosticRule {
  @override
  bool supports(String language) => language == 'json';

  @override
  Iterable<Diagnostic> analyze(DocumentSnapshot document) {
    final diagnostics = <Diagnostic>[];
    final content = document.content;

    final trailingCommaRegex = RegExp(r',(\s*[\]}])');
    final unquotedKeyRegex = RegExp(r'(?:\{|,)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:');

    for (final match in trailingCommaRegex.allMatches(content)) {
      final offset = match.start;
      final pos = _offsetToPosition(content, offset);
      diagnostics.add(Diagnostic(
        id: '${document.path}-json-trailing-comma-${offset}',
        range: Range(
          start: pos,
          end: Position(line: pos.line, column: pos.column + 1),
        ),
        severity: DiagnosticSeverity.error,
        code: 'JSON_TRAILING_COMMA',
        source: 'regex',
        message: 'Trailing comma is not allowed in JSON.',
      ));
    }

    for (final match in unquotedKeyRegex.allMatches(content)) {
      final key = match.group(1)!;
      final offset = content.indexOf(key, match.start);
      final pos = _offsetToPosition(content, offset);
      diagnostics.add(Diagnostic(
        id: '${document.path}-json-unquoted-key-${offset}',
        range: Range(
          start: pos,
          end: Position(line: pos.line, column: pos.column + key.length),
        ),
        severity: DiagnosticSeverity.error,
        code: 'JSON_UNQUOTED_KEY',
        source: 'regex',
        message: 'Keys must be double-quoted in JSON.',
      ));
    }
    return diagnostics;
  }

  Position _offsetToPosition(String content, int offset) {
    int line = 1;
    int col = 1;
    for (int i = 0; i < offset && i < content.length; i++) {
      if (content[i] == '\n') {
        line++;
        col = 1;
      } else {
        col++;
      }
    }
    return Position(line: line, column: col);
  }
}

class YamlIndentationRule implements DiagnosticRule {
  @override
  bool supports(String language) => language == 'yaml';

  @override
  Iterable<Diagnostic> analyze(DocumentSnapshot document) {
    final diagnostics = <Diagnostic>[];
    final lines = document.lines;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final tabIdx = line.indexOf('\t');
      if (tabIdx != -1) {
        diagnostics.add(Diagnostic(
          id: '${document.path}-line-${i + 1}-yaml-tab',
          range: Range(
            start: Position(line: i + 1, column: tabIdx + 1),
            end: Position(line: i + 1, column: tabIdx + 2),
          ),
          severity: DiagnosticSeverity.error,
          code: 'YAML_TAB_CHARACTER',
          source: 'regex',
          message: 'Tabs are not allowed in YAML. Use spaces for indentation.',
        ));
      }
    }
    return diagnostics;
  }
}

class MarkdownLinkRule implements DiagnosticRule {
  @override
  bool supports(String language) => language == 'markdown';

  @override
  Iterable<Diagnostic> analyze(DocumentSnapshot document) {
    final diagnostics = <Diagnostic>[];
    final lines = document.lines;
    final linkRegex = RegExp(r'\[([^\]]+)\]\(([^\)]+)\)');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final match in linkRegex.allMatches(line)) {
        final linkTarget = match.group(2)!;
        if (linkTarget.startsWith('.') ||
            (linkTarget.contains('/') && !linkTarget.startsWith('http'))) {
          final fileDir = document.path.contains('/')
              ? document.path.substring(0, document.path.lastIndexOf('/'))
              : '';
          final cleanTarget = linkTarget.split('#')[0];
          final targetRelPath =
              fileDir.isEmpty ? cleanTarget : '$fileDir/$cleanTarget';
          final fullPath = '${Directory.current.path}/$targetRelPath';
          if (!File(fullPath).existsSync() &&
              !Directory(fullPath).existsSync()) {
            diagnostics.add(Diagnostic(
              id: '${document.path}-line-${i + 1}-markdown-broken-link',
              range: Range(
                start: Position(line: i + 1, column: match.start + 1),
                end: Position(line: i + 1, column: match.end + 1),
              ),
              severity: DiagnosticSeverity.warning,
              code: 'MD_BROKEN_LINK',
              source: 'regex',
              message: 'Markdown link refers to missing file: $linkTarget',
            ));
          }
        }
      }
    }
    return diagnostics;
  }
}

class GenericTodoRule implements DiagnosticRule {
  @override
  bool supports(String language) => true;

  @override
  Iterable<Diagnostic> analyze(DocumentSnapshot document) {
    final diagnostics = <Diagnostic>[];
    final lines = document.lines;
    final todoRegex = RegExp(r'\b(TODO|FIXME):?\s*(.*)', caseSensitive: false);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = todoRegex.firstMatch(line);
      if (match != null) {
        final tag = match.group(1)!.toUpperCase();
        final msg = match.group(2)!.trim();
        diagnostics.add(Diagnostic(
          id: '${document.path}-line-${i + 1}-todo',
          range: Range(
            start: Position(line: i + 1, column: match.start + 1),
            end: Position(line: i + 1, column: match.end + 1),
          ),
          severity: DiagnosticSeverity.information,
          code: 'GENERIC_TODO_MARKER',
          source: 'regex',
          message: '$tag: ${msg.isEmpty ? "Task description missing" : msg}',
        ));
      }
    }
    return diagnostics;
  }
}

class RegexSource implements DiagnosticSource {
  @override
  final String id = 'regex';
  final List<DiagnosticRule> rules = [];

  RegexSource() {
    rules.addAll([
      DartSyntaxRule(),
      DartDeprecationRule(),
      JsonSyntaxRule(),
      YamlIndentationRule(),
      MarkdownLinkRule(),
      GenericTodoRule(),
    ]);
  }

  @override
  Iterable<Diagnostic> run(DocumentSnapshot document) {
    final language = _detectLanguage(document.path);
    final results = <Diagnostic>[];
    for (final rule in rules) {
      if (rule.supports(language) || rule is GenericTodoRule) {
        results.addAll(rule.analyze(document));
      }
    }
    return results;
  }

  String _detectLanguage(String path) {
    if (path.endsWith('.dart')) return 'dart';
    if (path.endsWith('.json')) return 'json';
    if (path.endsWith('.yaml') || path.endsWith('.yml')) return 'yaml';
    if (path.endsWith('.md')) return 'markdown';
    return 'generic';
  }
}

class DiagnosticsEngine {
  final List<DiagnosticSource> sources = [];

  DiagnosticsEngine() {
    sources.add(RegexSource());
  }

  List<Diagnostic> run(DocumentSnapshot document) {
    final results = <Diagnostic>[];
    for (final source in sources) {
      results.addAll(source.run(document));
    }
    return results;
  }
}
