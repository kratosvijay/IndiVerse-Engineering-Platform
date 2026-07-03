import 'dart:async';
import '../events/event_bus.dart';
import '../events/runtime_event.dart';
import '../runtime/model_registry.dart';

class CostTracker {
  final EventBus _eventBus;
  final ModelRegistry _modelRegistry;
  StreamSubscription<RuntimeCompleted>? _subscription;

  double _totalCost = 0.0;
  final Map<String, double> _costByModel = {};
  final Map<String, double> _costByProvider = {};

  double get totalCost => _totalCost;
  double getCostForModel(String model) => _costByModel[model] ?? 0.0;
  double getCostForProvider(String provider) =>
      _costByProvider[provider] ?? 0.0;

  CostTracker({EventBus? eventBus, ModelRegistry? modelRegistry})
      : _eventBus = eventBus ?? EventBus(),
        _modelRegistry = modelRegistry ?? ModelRegistry() {
    _subscription = _eventBus.on<RuntimeCompleted>().listen(_onCompleted);
  }

  void _onCompleted(RuntimeCompleted event) {
    final result = event.result;
    // We try to match model metadata to estimate cost
    final meta = _modelRegistry.getModel(result.response.text); // Mock fetch

    final usage = result.response.usage;
    // Calculate cost: (inputTokens * rateInput) + (outputTokens * rateOutput)
    // Rate is per million tokens. Default fallback if not registered.
    double inputRate = 0.15; // default $0.15 / million
    double outputRate = 0.60; // default $0.60 / million

    if (meta != null) {
      inputRate = meta.pricingInputPerMillion;
      outputRate = meta.pricingOutputPerMillion;
    }

    final cost =
        ((usage.inputTokens * inputRate) + (usage.outputTokens * outputRate)) /
            1000000.0;
    _totalCost += cost;

    final model = meta?.name ?? "unknown_model";
    final provider = meta?.providerName ?? result.providerName;

    _costByModel[model] = (_costByModel[model] ?? 0.0) + cost;
    _costByProvider[provider] = (_costByProvider[provider] ?? 0.0) + cost;
  }

  void reset() {
    _totalCost = 0.0;
    _costByModel.clear();
    _costByProvider.clear();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
