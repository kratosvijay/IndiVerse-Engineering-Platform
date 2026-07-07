import 'dart:io';
import '../diagnostics/diagnostic_models.dart';
import '../studio/services/code_intelligence_service.dart';

class CallRecord {
  final String name;
  final int openParenOffset;
  int activeParam;
  final int braceDepth;
  final int bracketDepth;
  final int genericDepth;

  CallRecord({
    required this.name,
    required this.openParenOffset,
    required this.activeParam,
    required this.braceDepth,
    required this.bracketDepth,
    required this.genericDepth,
  });
}

class SignatureHelpProvider {
  final CodeIntelligenceService _service;

  static const Map<String, SignatureInformation> _knownSdkMethods = {
    'print': SignatureInformation(
      label: 'print(Object? object)',
      documentation:
          'Prints a string representation of the object to the console.',
      parameters: [
        ParameterInformation(
          label: 'Object? object',
          documentation: 'The object to print.',
        ),
      ],
    ),
    'Color.fromARGB': SignatureInformation(
      label: 'Color.fromARGB(alpha, red, green, blue)',
      documentation:
          'Construct a color from the lower 8 bits of four integers.',
      parameters: [
        ParameterInformation(
            label: 'alpha', documentation: 'Alpha channel (0-255).'),
        ParameterInformation(
            label: 'red', documentation: 'Red channel (0-255).'),
        ParameterInformation(
            label: 'green', documentation: 'Green channel (0-255).'),
        ParameterInformation(
            label: 'blue', documentation: 'Blue channel (0-255).'),
      ],
    ),
    'showDialog': SignatureInformation(
      label: 'showDialog(BuildContext context, WidgetBuilder builder)',
      documentation:
          'Displays a Material dialog above the current contents of the app.',
      parameters: [
        ParameterInformation(
          label: 'BuildContext context',
          documentation: 'The context.',
        ),
        ParameterInformation(
          label: 'WidgetBuilder builder',
          documentation: 'The builder.',
        ),
      ],
    ),
  };

  SignatureHelpProvider(this._service);

  SignatureHelp? getSignatureHelp(String path, int line, int column) {
    String content = '';
    try {
      final absolutePath =
          path.startsWith('/') ? path : '${Directory.current.path}/$path';
      final file = File(absolutePath);
      if (file.existsSync()) {
        content = file.readAsStringSync();
      }
    } catch (_) {}

    if (content.isEmpty) return null;

    final lines = content.split('\n');
    final cursorOffset = _getOffset(lines, line, column);
    if (cursorOffset < 0 || cursorOffset > content.length) return null;

    // Run forward parser up to cursorOffset to find active call stack
    final activeCall = _parseActiveCall(content, cursorOffset);
    if (activeCall == null) return null;

    final identifier = activeCall.name;
    final activeParameter = activeCall.activeParam;

    // Layered Resolution:
    // 1. SDK Built-in Signatures
    SignatureInformation? sigInfo = _knownSdkMethods[identifier];

    // 2. Current Document Parser
    if (sigInfo == null) {
      sigInfo = findSignatureInContent(content, identifier);
    }

    // 3. Workspace Symbol Index
    if (sigInfo == null) {
      final symbols = _service.symbolIndex.allSymbols();
      final String searchName =
          identifier.contains('.') ? identifier.split('.').last : identifier;
      for (final sym in symbols) {
        if (sym.name == searchName) {
          try {
            final file = File('${Directory.current.path}/${sym.filePath}');
            if (file.existsSync()) {
              final fileContent = file.readAsStringSync();
              sigInfo = findSignatureInContent(fileContent, identifier);
              if (sigInfo != null) break;
            }
          } catch (_) {}
        }
      }
    }

    if (sigInfo == null) return null;

    return SignatureHelp(
      signatures: [sigInfo],
      activeSignature: 0,
      activeParameter: activeParameter,
    );
  }

  int _getOffset(List<String> lines, int line, int column) {
    int offset = 0;
    for (int i = 0; i < line - 1; i++) {
      if (i >= lines.length) break;
      offset += lines[i].length + 1; // +1 for the newline character
    }
    offset += column - 1;
    return offset;
  }

  CallRecord? _parseActiveCall(String content, int cursorOffset) {
    final callStack = <CallRecord>[];
    String? inString;
    bool inLineComment = false;
    bool inBlockComment = false;
    int braceDepth = 0;
    int bracketDepth = 0;
    int genericDepth = 0;

    const controlKeywords = {'if', 'for', 'while', 'switch', 'catch'};

    for (int i = 0; i < cursorOffset; i++) {
      final char = content[i];
      final hasNext = i + 1 < content.length;
      final nextChar = hasNext ? content[i + 1] : '';

      // Handle comments
      if (inLineComment) {
        if (char == '\n') {
          inLineComment = false;
        }
        continue;
      }
      if (inBlockComment) {
        if (char == '*' && nextChar == '/') {
          inBlockComment = false;
          i++;
        }
        continue;
      }

      // Handle strings
      if (inString != null) {
        if (char == '\\') {
          i++; // Skip escaped char
        } else if (char == inString) {
          inString = null;
        }
        continue;
      }

      // Check start of string or comment
      if (char == '/' && nextChar == '/') {
        inLineComment = true;
        i++;
        continue;
      }
      if (char == '/' && nextChar == '*') {
        inBlockComment = true;
        i++;
        continue;
      }
      if (char == "'" || char == '"') {
        inString = char;
        continue;
      }

      // Syntax structures
      if (char == '{') {
        braceDepth++;
      } else if (char == '}') {
        if (braceDepth > 0) braceDepth--;
      } else if (char == '[') {
        bracketDepth++;
      } else if (char == ']') {
        if (bracketDepth > 0) bracketDepth--;
      } else if (char == '<') {
        genericDepth++;
      } else if (char == '>') {
        if (genericDepth > 0) genericDepth--;
      } else if (char == '(') {
        // Extract identifier before paren
        final identifier = _extractIdentifier(content, i);
        if (identifier.isNotEmpty && !controlKeywords.contains(identifier)) {
          callStack.add(CallRecord(
            name: identifier,
            openParenOffset: i,
            activeParam: 0,
            braceDepth: braceDepth,
            bracketDepth: bracketDepth,
            genericDepth: genericDepth,
          ));
        }
      } else if (char == ')') {
        if (callStack.isNotEmpty) {
          callStack.removeLast();
        }
      } else if (char == ',') {
        if (callStack.isNotEmpty) {
          final top = callStack.last;
          if (braceDepth == top.braceDepth &&
              bracketDepth == top.bracketDepth &&
              genericDepth == top.genericDepth) {
            top.activeParam++;
          }
        }
      }
    }

    return callStack.isNotEmpty ? callStack.last : null;
  }

  String _extractIdentifier(String content, int openParenOffset) {
    int idx = openParenOffset - 1;
    while (idx >= 0 && RegExp(r'\s').hasMatch(content[idx])) {
      idx--;
    }
    int end = idx + 1;
    while (idx >= 0 && RegExp(r'[a-zA-Z0-9_.]').hasMatch(content[idx])) {
      idx--;
    }
    return content.substring(idx + 1, end).trim();
  }

  SignatureInformation? findSignatureInContent(
      String content, String identifier) {
    String searchName = identifier;
    String? className;
    if (identifier.contains('.')) {
      final parts = identifier.split('.');
      className = parts[0];
      searchName = parts[1];
    }

    String searchScope = content;
    if (className != null) {
      final classMatch = RegExp('class\\s+$className\\b').firstMatch(content);
      if (classMatch != null) {
        searchScope = content.substring(classMatch.start);
      }
    }

    final regexes = <RegExp>[];
    if (className != null) {
      regexes.add(RegExp('\\b$className\\.$searchName\\s*\\(([^)]*)\\)'));
      regexes.add(RegExp('\\b$searchName\\s*\\(([^)]*)\\)'));
    } else {
      regexes.add(RegExp('\\b$searchName\\s*\\(([^)]*)\\)'));
    }

    for (final regex in regexes) {
      for (final match in regex.allMatches(searchScope)) {
        final paramBlock = match.group(1);
        if (paramBlock == null) continue;

        final matchIndex = match.start;
        final beforeMatch = searchScope.substring(0, matchIndex);
        final lineStart = beforeMatch.lastIndexOf('\n') + 1;
        final lineContent = searchScope.substring(
          lineStart,
          match.end + 50 > searchScope.length
              ? searchScope.length
              : match.end + 50,
        );

        if (lineContent.contains('import') ||
            lineContent.trim().startsWith('//')) {
          continue;
        }

        final params = parseParameters(paramBlock);
        return SignatureInformation(
          label: '$identifier(${params.map((p) => p.label).join(', ')})',
          parameters: params,
        );
      }
    }
    return null;
  }

  List<ParameterInformation> parseParameters(String paramBlock) {
    final params = <ParameterInformation>[];
    if (paramBlock.trim().isEmpty) return params;

    final parts = <String>[];
    int depth = 0;
    var current = StringBuffer();
    for (int i = 0; i < paramBlock.length; i++) {
      final char = paramBlock[i];
      if (char == '<' || char == '(' || char == '{' || char == '[') {
        depth++;
      } else if (char == '>' || char == ')' || char == '}' || char == ']') {
        depth--;
      }

      if (char == ',' && depth == 0) {
        parts.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    if (current.isNotEmpty) {
      parts.add(current.toString().trim());
    }

    for (final part in parts) {
      if (part.isEmpty) continue;
      params.add(ParameterInformation(label: part));
    }
    return params;
  }
}
