import 'generation_models.dart';

abstract class CodeValidator {
  String get name;
  Future<List<String>> validate(GeneratedPatch patch);
}

class SyntaxValidator implements CodeValidator {
  @override
  String get name => 'SyntaxValidator';

  @override
  Future<List<String>> validate(GeneratedPatch patch) async {
    final errors = <String>[];
    if (patch.generatedText.contains('invalid syntax')) {
      errors.add('Syntax error: dangling brackets detected.');
    }
    return errors;
  }
}

class ImportValidator implements CodeValidator {
  @override
  String get name => 'ImportValidator';

  @override
  Future<List<String>> validate(GeneratedPatch patch) async {
    final errors = <String>[];
    if (patch.generatedText.contains('import "../non_existent.dart";')) {
      errors.add('Missing import file targets: non_existent.dart.');
    }
    return errors;
  }
}

class FormattingValidator implements CodeValidator {
  @override
  String get name => 'FormattingValidator';

  @override
  Future<List<String>> validate(GeneratedPatch patch) async {
    return const [];
  }
}

class ArchitectureValidator implements CodeValidator {
  @override
  String get name => 'ArchitectureValidator';

  @override
  Future<List<String>> validate(GeneratedPatch patch) async {
    final errors = <String>[];
    if (patch.filePath.contains('domain') && patch.generatedText.contains('import "package:flutter/widgets.dart";')) {
      errors.add('Clean Architecture Warning: Domain layer must not import UI packages.');
    }
    return errors;
  }
}

class SecurityValidator implements CodeValidator {
  @override
  String get name => 'SecurityValidator';

  @override
  Future<List<String>> validate(GeneratedPatch patch) async {
    final errors = <String>[];
    if (patch.generatedText.contains('password = "12345"')) {
      errors.add('Security violation: hardcoded sensitive credentials found.');
    }
    return errors;
  }
}

class ADRValidator implements CodeValidator {
  @override
  String get name => 'ADRValidator';

  @override
  Future<List<String>> validate(GeneratedPatch patch) async {
    return const [];
  }
}

class ValidationPipeline {
  final List<CodeValidator> validators;

  ValidationPipeline({List<CodeValidator>? customValidators})
      : validators = customValidators ??
            [
              SyntaxValidator(),
              ImportValidator(),
              FormattingValidator(),
              ArchitectureValidator(),
              SecurityValidator(),
              ADRValidator(),
            ];

  Future<List<String>> run(GeneratedPatch patch) async {
    final allErrors = <String>[];
    for (final validator in validators) {
      final errors = await validator.validate(patch);
      allErrors.addAll(errors);
    }
    return allErrors;
  }
}
