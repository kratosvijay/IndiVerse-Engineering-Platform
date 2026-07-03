import 'workspace_context.dart';
import 'context_budget.dart';

class ContextBuilder {
  final List<ContextProvider> providers;
  final ContextBudgetPolicy policy;

  ContextBuilder({
    required this.providers,
    this.policy = const StandardPolicy(),
  });

  Future<List<ContextContribution>> assemble(String rootPath) async {
    final list = <ContextContribution>[];
    for (final provider in providers) {
      list.addAll(await provider.build(rootPath));
    }

    list.sort((a, b) => b.priority.compareTo(a.priority));

    final pruned = <ContextContribution>[];
    var currentTokens = 0;
    for (final contrib in list) {
      if (currentTokens + contrib.tokens <= policy.maxTokens) {
        pruned.add(contrib);
        currentTokens += contrib.tokens;
      }
    }
    return pruned;
  }
}
