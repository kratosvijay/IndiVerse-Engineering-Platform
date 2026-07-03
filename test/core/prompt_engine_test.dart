import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt_compiler.dart';

void main() {
  group('PromptCompiler Tests', () {
    const compiler = PromptCompiler();

    test('should compile system instructions correctly', () {
      const prompt = Prompt(
        systemInstructions: "Be concise. ",
        userInput: "Hello",
      );
      expect(compiler.compileSystem(prompt), "Be concise.");
    });

    test('should compile user input, context, and constraints', () {
      const prompt = Prompt(
        systemInstructions: "System",
        userInput: "Run tests",
        contextSnippets: ["Context snippet 1", "Context snippet 2"],
        constraints: ["Must pass", "No logs"],
        expectedOutput: "YAML output",
      );

      final userPrompt = compiler.compileUser(prompt);
      expect(userPrompt, contains("### CONTEXT"));
      expect(userPrompt, contains("Context snippet 1"));
      expect(userPrompt, contains("### USER INPUT"));
      expect(userPrompt, contains("Run tests"));
      expect(userPrompt, contains("### CONSTRAINTS"));
      expect(userPrompt, contains("Must pass"));
      expect(userPrompt, contains("### EXPECTED OUTPUT"));
      expect(userPrompt, contains("YAML output"));
    });
  });
}
