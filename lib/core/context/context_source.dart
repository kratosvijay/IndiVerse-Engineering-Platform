abstract class ContextSource {
  Future<String> fetchContext();
}

class StaticContextSource extends ContextSource {
  final String _content;
  StaticContextSource(this._content);

  @override
  Future<String> fetchContext() async => _content;
}

class RuleContextSource extends ContextSource {
  final String ruleName;
  RuleContextSource(this.ruleName);

  @override
  Future<String> fetchContext() async {
    // Mimic rule extraction
    return "Rule context for: $ruleName";
  }
}
