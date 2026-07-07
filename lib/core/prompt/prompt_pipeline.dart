import '../conversation/conversation_manager.dart';
import '../context/context_engine.dart';

class CancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class PromptTemplate {
  final String systemTemplate;
  final String userTemplate;

  const PromptTemplate({
    required this.systemTemplate,
    required this.userTemplate,
  });
}

class PromptPackage {
  final String systemPrompt;
  final String userPrompt;
  final List<ContextFragment> fragments;
  final int estimatedTokens;

  const PromptPackage({
    required this.systemPrompt,
    required this.userPrompt,
    required this.fragments,
    required this.estimatedTokens,
  });

  Map<String, dynamic> toJson() => {
        'systemPrompt': systemPrompt,
        'userPrompt': userPrompt,
        'fragments': fragments.map((f) => f.toJson()).toList(),
        'estimatedTokens': estimatedTokens,
      };
}

class AIRequest {
  final ConversationSession session;
  final ContextSnapshot context;
  final PromptPackage promptPackage;
  final CancellationToken token;

  const AIRequest({
    required this.session,
    required this.context,
    required this.promptPackage,
    required this.token,
  });
}

class TokenEstimator {
  static int estimate(String text) {
    return (text.length / 4.0).ceil();
  }
}

class PromptOptimizer {
  static List<ContextFragment> optimize(
    List<ContextFragment> fragments,
    int maxBudget,
  ) {
    final sorted = List<ContextFragment>.from(fragments)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final result = <ContextFragment>[];
    int currentTokens = 0;

    for (final frag in sorted) {
      if (currentTokens + frag.estimatedTokens <= maxBudget) {
        result.add(frag);
        currentTokens += frag.estimatedTokens;
      }
    }

    return result;
  }
}

class PromptBuilder {
  PromptPackage build({
    required PromptTemplate template,
    required Map<String, String> variables,
    required ContextSnapshot context,
    required int maxContextTokens,
  }) {
    String systemPrompt = template.systemTemplate;
    String userPrompt = template.userTemplate;

    variables.forEach((key, val) {
      systemPrompt = systemPrompt.replaceAll('{{$key}}', val);
      userPrompt = userPrompt.replaceAll('{{$key}}', val);
    });

    final optimizedFragments = PromptOptimizer.optimize(
      context.fragments,
      maxContextTokens,
    );

    final contextBlock = optimizedFragments
        .map((f) => 'Source: ${f.source}\nContent:\n${f.content}')
        .join('\n\n');

    if (contextBlock.isNotEmpty) {
      userPrompt = '$userPrompt\n\n--- Context ---\n$contextBlock';
    }

    final totalText = systemPrompt + userPrompt;
    final estimatedTokens = TokenEstimator.estimate(totalText);

    return PromptPackage(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      fragments: optimizedFragments,
      estimatedTokens: estimatedTokens,
    );
  }
}
