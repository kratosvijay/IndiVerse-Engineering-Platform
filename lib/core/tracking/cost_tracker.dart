import 'dart:async';
import '../events/event_bus.dart';
import '../events/runtime_event.dart';
import '../registry/model_registry.dart';

class CostTracker {
  final EventBus eventBus;
  final ModelRegistry modelRegistry;

  double _totalCost = 0.0;
  StreamSubscription<RuntimeCompleted>? _subscription;

  CostTracker({required this.eventBus, required this.modelRegistry}) {
    _subscription = eventBus.on<RuntimeCompleted>().listen((event) {
      final modelName = event.result.response.text.contains("Mock")
          ? "mock-model"
          : event.result.response.text;
      final meta = modelRegistry.resolve(modelName);
      final usage = event.result.response.usage;
      final inputCost =
          (usage.inputTokens / 1000000.0) * meta.pricingInputPerMillion;
      final outputCost =
          (usage.outputTokens / 1000000.0) * meta.pricingOutputPerMillion;
      _totalCost += (inputCost + outputCost);
    });
  }

  double get totalCost => _totalCost;

  void dispose() {
    _subscription?.cancel();
  }
}
