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
  final List<ContextFragment> used;
  final List<ContextFragment> discarded;
  final int estimatedTokens;
  final Map<String, int> tokenUsageByProvider;

  const PromptPackage({
    required this.systemPrompt,
    required this.userPrompt,
    required this.used,
    required this.discarded,
    required this.estimatedTokens,
    required this.tokenUsageByProvider,
  });

  Map<String, dynamic> toJson() => {
        'systemPrompt': systemPrompt,
        'userPrompt': userPrompt,
        'used': used.map((f) => f.toJson()).toList(),
        'discarded': discarded.map((f) => f.toJson()).toList(),
        'estimatedTokens': estimatedTokens,
        'tokenUsageByProvider': tokenUsageByProvider,
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

class PromptOptimizerResult {
  final List<ContextFragment> used;
  final List<ContextFragment> discarded;
  final int totalUsedTokens;

  const PromptOptimizerResult({
    required this.used,
    required this.discarded,
    required this.totalUsedTokens,
  });
}

class PromptOptimizer {
  static PromptOptimizerResult optimize(
    List<ContextFragment> fragments,
    int maxBudget,
  ) {
    final sorted = List<ContextFragment>.from(fragments)
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));

    final used = <ContextFragment>[];
    final discarded = <ContextFragment>[];
    int currentTokens = 0;

    for (final frag in sorted) {
      if (currentTokens + frag.estimatedTokens <= maxBudget) {
        used.add(frag);
        currentTokens += frag.estimatedTokens;
      } else {
        discarded.add(frag);
      }
    }

    return PromptOptimizerResult(
      used: used,
      discarded: discarded,
      totalUsedTokens: currentTokens,
    );
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

    final optimization = PromptOptimizer.optimize(
      context.fragments,
      maxContextTokens,
    );

    final contextBlock = optimization.used
        .map((f) => 'Source: ${f.source}\nContent:\n${f.content}')
        .join('\n\n');

    if (contextBlock.isNotEmpty) {
      userPrompt = '$userPrompt\n\n--- Context ---\n$contextBlock';
    }

    final totalText = systemPrompt + userPrompt;
    final estimatedTokens = TokenEstimator.estimate(totalText);

    final tokenUsageByProvider = <String, int>{};
    for (final frag in optimization.used) {
      tokenUsageByProvider[frag.source] =
          (tokenUsageByProvider[frag.source] ?? 0) + frag.estimatedTokens;
    }

    return PromptPackage(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      used: optimization.used,
      discarded: optimization.discarded,
      estimatedTokens: estimatedTokens,
      tokenUsageByProvider: tokenUsageByProvider,
    );
  }
}

