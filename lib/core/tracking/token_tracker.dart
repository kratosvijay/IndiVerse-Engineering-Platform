import 'dart:async';
import '../events/event_bus.dart';
import '../events/runtime_event.dart';

class TokenUsage {
  final int inputTokens;
  final int outputTokens;
  final int cachedTokens;
  final int reasoningTokens;
  final int totalTokens;

  const TokenUsage({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cachedTokens = 0,
    this.reasoningTokens = 0,
    this.totalTokens = 0,
  });

  TokenUsage operator +(TokenUsage other) {
    return TokenUsage(
      inputTokens: inputTokens + other.inputTokens,
      outputTokens: outputTokens + other.outputTokens,
      cachedTokens: cachedTokens + other.cachedTokens,
      reasoningTokens: reasoningTokens + other.reasoningTokens,
      totalTokens: totalTokens + other.totalTokens,
    );
  }
}

class TokenTracker {
  final EventBus _eventBus;
  StreamSubscription<RuntimeCompleted>? _subscription;

  int _totalInputTokens = 0;
  int _totalOutputTokens = 0;
  int _totalReasoningTokens = 0;

  int get totalInputTokens => _totalInputTokens;
  int get totalOutputTokens => _totalOutputTokens;
  int get totalReasoningTokens => _totalReasoningTokens;
  int get totalTokens => _totalInputTokens + _totalOutputTokens;

  TokenTracker({EventBus? eventBus}) : _eventBus = eventBus ?? EventBus() {
    _subscription = _eventBus.on<RuntimeCompleted>().listen(_onCompleted);
  }

  void _onCompleted(RuntimeCompleted event) {
    final usage = event.result.response.usage;
    _totalInputTokens += usage.inputTokens;
    _totalOutputTokens += usage.outputTokens;
    _totalReasoningTokens += usage.reasoningTokens;
  }

  void reset() {
    _totalInputTokens = 0;
    _totalOutputTokens = 0;
    _totalReasoningTokens = 0;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
