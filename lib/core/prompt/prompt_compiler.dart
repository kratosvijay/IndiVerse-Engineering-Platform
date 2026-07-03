import 'prompt.dart';

class PromptCompiler {
  const PromptCompiler();

  String compileSystem(Prompt prompt) {
    return prompt.systemInstructions.trim();
  }

  String compileUser(Prompt prompt) {
    final buffer = StringBuffer();

    if (prompt.contextSnippets.isNotEmpty) {
      buffer.writeln("### CONTEXT");
      for (final snip in prompt.contextSnippets) {
        buffer.writeln("- $snip");
      }
      buffer.writeln();
    }

    buffer.writeln("### USER INPUT");
    buffer.writeln(prompt.userInput);
    buffer.writeln();

    if (prompt.constraints.isNotEmpty) {
      buffer.writeln("### CONSTRAINTS");
      for (final cons in prompt.constraints) {
        buffer.writeln("- $cons");
      }
      buffer.writeln();
    }

    if (prompt.expectedOutput.isNotEmpty) {
      buffer.writeln("### EXPECTED OUTPUT");
      buffer.writeln(prompt.expectedOutput);
    }

    return buffer.toString().trim();
  }
}
