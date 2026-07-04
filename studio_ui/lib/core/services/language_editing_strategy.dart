abstract class LanguageEditingStrategy {
  String get extension;

  String get lineCommentPrefix;
  String get blockCommentStart;
  String get blockCommentEnd;

  Map<String, String> get bracketPairs;

  bool shouldIndentAfter(String line);
}

class DartStrategy extends LanguageEditingStrategy {
  @override
  String get extension => 'dart';

  @override
  String get lineCommentPrefix => '//';

  @override
  String get blockCommentStart => '/*';

  @override
  String get blockCommentEnd => '*/';

  @override
  Map<String, String> get bracketPairs => {
    '(': ')',
    '{': '}',
    '[': ']',
    '"': '"',
    "'": "'",
    '<': '>',
  };

  @override
  bool shouldIndentAfter(String line) {
    final trimmed = line.trim();
    return trimmed.endsWith('{') ||
        trimmed.endsWith('(') ||
        trimmed.endsWith('[');
  }
}

class JsonStrategy extends LanguageEditingStrategy {
  @override
  String get extension => 'json';

  @override
  String get lineCommentPrefix => '//';

  @override
  String get blockCommentStart => '/*';

  @override
  String get blockCommentEnd => '*/';

  @override
  Map<String, String> get bracketPairs => {
    '(': ')',
    '{': '}',
    '[': ']',
    '"': '"',
  };

  @override
  bool shouldIndentAfter(String line) {
    final trimmed = line.trim();
    return trimmed.endsWith('{') ||
        trimmed.endsWith('[') ||
        trimmed.endsWith(':');
  }
}

class YamlStrategy extends LanguageEditingStrategy {
  @override
  String get extension => 'yaml';

  @override
  String get lineCommentPrefix => '#';

  @override
  String get blockCommentStart => '';

  @override
  String get blockCommentEnd => '';

  @override
  Map<String, String> get bracketPairs => {
    '(': ')',
    '{': '}',
    '[': ']',
    '"': '"',
    "'": "'",
  };

  @override
  bool shouldIndentAfter(String line) {
    final trimmed = line.trim();
    return trimmed.endsWith(':') || trimmed.endsWith('-');
  }
}

class MarkdownStrategy extends LanguageEditingStrategy {
  @override
  String get extension => 'md';

  @override
  String get lineCommentPrefix => '';

  @override
  String get blockCommentStart => '<!--';

  @override
  String get blockCommentEnd => '-->';

  @override
  Map<String, String> get bracketPairs => {
    '(': ')',
    '{': '}',
    '[': ']',
    '"': '"',
    "'": "'",
    '<': '>',
    '*': '*',
    '_': '_',
    '`': '`',
  };

  @override
  bool shouldIndentAfter(String line) => false;
}

class DefaultLanguageStrategy extends LanguageEditingStrategy {
  @override
  String get extension => '';

  @override
  String get lineCommentPrefix => '//';

  @override
  String get blockCommentStart => '/*';

  @override
  String get blockCommentEnd => '*/';

  @override
  Map<String, String> get bracketPairs => {
    '(': ')',
    '{': '}',
    '[': ']',
    '"': '"',
    "'": "'",
  };

  @override
  bool shouldIndentAfter(String line) {
    final trimmed = line.trim();
    return trimmed.endsWith('{') || trimmed.endsWith('(');
  }
}

class LanguageEditingStrategyRegistry {
  static final List<LanguageEditingStrategy> _strategies = [
    DartStrategy(),
    JsonStrategy(),
    YamlStrategy(),
    MarkdownStrategy(),
  ];

  static LanguageEditingStrategy getStrategy(String extension) {
    final cleanExt = extension.replaceAll('.', '').trim().toLowerCase();
    return _strategies.firstWhere(
      (s) => s.extension == cleanExt,
      orElse: () => DefaultLanguageStrategy(),
    );
  }
}
