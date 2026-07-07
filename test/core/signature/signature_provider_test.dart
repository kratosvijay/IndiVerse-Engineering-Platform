import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/studio/services/code_intelligence_service.dart';
import 'package:indiverse_developer_platform/core/signature/signature_help_provider.dart';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';
import 'dart:io';

void main() {
  group('SignatureHelpProvider Tests', () {
    late CodeIntelligenceService service;
    late SignatureHelpProvider provider;
    late File tempFile;

    setUp(() {
      final sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );
      service = CodeIntelligenceService(sdk);
      provider = SignatureHelpProvider(service);
      tempFile = File('test_signature_temp.dart');
    });

    tearDown(() {
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    });

    test('SDK Built-in Signatures - print', () {
      tempFile.writeAsStringSync('void main() {\n  print("hello");\n}');
      final help = provider.getSignatureHelp('test_signature_temp.dart', 2, 16);
      expect(help, isNotNull);
      expect(help!.signatures.first.label, equals('print(Object? object)'));
      expect(help.activeParameter, 0);
    });

    test('SDK Built-in Signatures - Color.fromARGB', () {
      tempFile.writeAsStringSync(
          'void main() {\n  Color.fromARGB(255, 0, 128, 255);\n}');
      final help = provider.getSignatureHelp('test_signature_temp.dart', 2, 27);
      expect(help, isNotNull);
      expect(help!.signatures.first.label,
          equals('Color.fromARGB(alpha, red, green, blue)'));
      expect(help.activeParameter, 2); // after second comma
    });

    test('Current Document Parser - Custom Function', () {
      tempFile.writeAsStringSync('''
void customFunc(int x, String y) {
}
void main() {
  customFunc(12, "hello");
}
''');
      // Cursor inside customFunc call parameter 1: customFunc(12, "he|llo"); -> line 4, column 18
      final help = provider.getSignatureHelp('test_signature_temp.dart', 4, 18);
      expect(help, isNotNull);
      expect(
          help!.signatures.first.label, equals('customFunc(int x, String y)'));
      expect(help.activeParameter, 1);
    });

    test('Nested function calls calculation', () {
      tempFile.writeAsStringSync('void main() {\n  foo(a, bar(b, c), d);\n}');
      // Cursor is right before 'd' -> line 2, column 21
      final help = provider.getSignatureHelp('test_signature_temp.dart', 2, 21);
      expect(help, isNotNull);
      expect(help!.activeParameter,
          2); // active parameter of foo is 2, since bar(b, c) is nested parameter 1
    });

    test('Generic functions ignoring generic commas', () {
      tempFile.writeAsStringSync(
          'void main() {\n  myMapCall(Map<String, int> x, y);\n}');
      // Cursor is after y: line 2, column 33
      final help = provider.getSignatureHelp('test_signature_temp.dart', 2, 33);
      expect(help, isNotNull);
      expect(help!.activeParameter, 1); // ignores comma inside Map<String, int>
    });

    test('Ignoring commas inside collection and map literals', () {
      tempFile.writeAsStringSync(
          'void main() {\n  myListCall([1, 2, 3], {"a": 1, "b": 2}, z);\n}');
      // Cursor is right before z: line 2, column 43
      final help = provider.getSignatureHelp('test_signature_temp.dart', 2, 43);
      expect(help, isNotNull);
      expect(help!.activeParameter, 2);
    });

    test('Malformed code boundaries', () {
      tempFile.writeAsStringSync('void main() {\n  print(\n');
      final help = provider.getSignatureHelp('test_signature_temp.dart', 2, 9);
      expect(help, isNotNull);
      expect(help!.signatures.first.label, equals('print(Object? object)'));
      expect(help.activeParameter, 0);
    });
  });
}
