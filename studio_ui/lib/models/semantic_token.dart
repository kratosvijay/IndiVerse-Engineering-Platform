import 'package:flutter/widgets.dart';
import 'editor_document.dart';

enum SemanticTokenType {
  namespace,
  classType, // 'class' is a keyword
  enumType, // 'enum' is a keyword
  mixin,
  extension,
  interface,
  constructor,
  method,
  function,
  property,
  field,
  variable,
  parameter,
  typeParameter,
  annotation,
  keyword,
  operator,
  number,
  string,
  comment,
  regexp,
  label,
}

enum SemanticTokenModifier {
  declaration,
  definition,
  readonly,
  staticToken, // 'static' is a keyword
  deprecated,
  abstractToken, // 'abstract' is a keyword
  asyncToken, // 'async' is a keyword
  modification,
  documentation,
  defaultLibrary,
}

class SemanticToken {
  final Position start;
  final int length;
  final SemanticTokenType type;
  final Set<SemanticTokenModifier> modifiers;

  const SemanticToken({
    required this.start,
    required this.length,
    required this.type,
    required this.modifiers,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticToken &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          length == other.length &&
          type == other.type &&
          modifiers.length == other.modifiers.length &&
          modifiers.containsAll(other.modifiers);

  @override
  int get hashCode =>
      start.hashCode ^ length.hashCode ^ type.hashCode ^ modifiers.hashCode;
}

class SemanticStyle {
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final TextDecoration? decoration;
  final Color? color;

  const SemanticStyle({
    this.fontWeight,
    this.fontStyle,
    this.decoration,
    this.color,
  });
}

enum SemanticCacheState { loading, ready, timedOut, failed, stale }
