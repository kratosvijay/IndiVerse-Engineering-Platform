import '../diagnostics/diagnostic_models.dart';
import '../studio/services/code_intelligence_service.dart';

abstract class CompletionContributor {
  List<CompletionItem> getCompletions(
    DocumentSnapshot document,
    Position position,
    String prefix,
  );
}

class KeywordContributor implements CompletionContributor {
  static const _dartKeywords = [
    'void',
    'main',
    'class',
    'import',
    'final',
    'const',
    'var',
    'dynamic',
    'if',
    'else',
    'for',
    'while',
    'return',
    'print',
    'Colors',
    'Scaffold',
    'Future',
    'Stream',
    'true',
    'false',
    'null',
  ];

  static const _jsonKeywords = ['true', 'false', 'null'];
  static const _yamlKeywords = ['true', 'false'];

  @override
  List<CompletionItem> getCompletions(
    DocumentSnapshot document,
    Position position,
    String prefix,
  ) {
    final results = <CompletionItem>[];
    final extension = document.path.split('.').last.toLowerCase();
    List<String> keywords = const [];

    if (extension == 'dart') {
      keywords = _dartKeywords;
    } else if (extension == 'json') {
      keywords = _jsonKeywords;
    } else if (extension == 'yaml' || extension == 'yml') {
      keywords = _yamlKeywords;
    }

    for (final kw in keywords) {
      if (kw.toLowerCase().startsWith(prefix.toLowerCase())) {
        results.add(CompletionItem(
          label: kw,
          kind: CompletionItemKind.keyword,
          detail: 'Keyword',
          insertText: kw,
        ));
      }
    }

    return results;
  }
}

class ScopeContributor implements CompletionContributor {
  final SymbolIndex symbolIndex;

  ScopeContributor({required this.symbolIndex});

  @override
  List<CompletionItem> getCompletions(
    DocumentSnapshot document,
    Position position,
    String prefix,
  ) {
    final results = <CompletionItem>[];
    final extension = document.path.split('.').last.toLowerCase();

    // 1. Add workspace index symbols for Dart files
    if (extension == 'dart') {
      final allSymbols = symbolIndex.allSymbols();
      for (final sym in allSymbols) {
        if (sym.name.toLowerCase().contains(prefix.toLowerCase())) {
          CompletionItemKind kind = CompletionItemKind.text;
          if (sym.kind == 'Class') {
            kind = CompletionItemKind.classType;
          } else if (sym.kind == 'Function' || sym.kind == 'Method') {
            kind = CompletionItemKind.function;
          } else if (sym.kind == 'Enum') {
            kind = CompletionItemKind.enumType;
          }

          results.add(CompletionItem(
            label: sym.name,
            kind: kind,
            detail: '${sym.kind} in ${sym.filePath.split('/').last}',
            insertText: sym.name,
          ));
        }
      }
    }

    // 2. Scan current document content for local word suggestions
    final content = document.content;
    final wordRegex = RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]{2,}\b');
    final matches = wordRegex.allMatches(content);
    final seen = <String>{};

    for (final m in matches) {
      final word = m.group(0)!;
      if (word.toLowerCase().startsWith(prefix.toLowerCase()) &&
          word != prefix &&
          !seen.contains(word)) {
        seen.add(word);
        results.add(CompletionItem(
          label: word,
          kind: CompletionItemKind.variable,
          detail: 'Local Symbol',
          insertText: word,
        ));
      }
    }

    return results;
  }
}

class SnippetContributor implements CompletionContributor {
  @override
  List<CompletionItem> getCompletions(
    DocumentSnapshot document,
    Position position,
    String prefix,
  ) {
    final results = <CompletionItem>[];
    final extension = document.path.split('.').last.toLowerCase();

    if (extension == 'dart') {
      if ('main'.startsWith(prefix.toLowerCase())) {
        results.add(const CompletionItem(
          label: 'main',
          kind: CompletionItemKind.snippet,
          detail: 'void main() snippet',
          documentation: 'Generates a main entry point function.',
          insertText: 'void main() {\n  \$0\n}',
          insertTextFormat: 2,
        ));
      }
      if ('for'.startsWith(prefix.toLowerCase())) {
        results.add(const CompletionItem(
          label: 'for',
          kind: CompletionItemKind.snippet,
          detail: 'for loop snippet',
          documentation: 'Generates a standard for loop.',
          insertText: 'for (var i = 0; i < \${1:count}; i++) {\n  \$0\n}',
          insertTextFormat: 2,
        ));
      }
    } else if (extension == 'md' || extension == 'markdown') {
      if ('link'.startsWith(prefix.toLowerCase())) {
        results.add(const CompletionItem(
          label: 'link',
          kind: CompletionItemKind.snippet,
          detail: 'Markdown Link',
          insertText: '[\${1:text}](\${2:url})',
          insertTextFormat: 2,
        ));
      }
      if ('image'.startsWith(prefix.toLowerCase())) {
        results.add(const CompletionItem(
          label: 'image',
          kind: CompletionItemKind.snippet,
          detail: 'Markdown Image',
          insertText: '![\${1:alt}](\${2:url})',
          insertTextFormat: 2,
        ));
      }
    }

    return results;
  }
}
