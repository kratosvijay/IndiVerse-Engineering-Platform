import 'dart:async';
import '../events/event_bus.dart';
import '../events/runtime_event.dart';
import 'provider_benchmark.dart';

class BenchmarkCollector {
  final EventBus eventBus;
  final Map<String, List<double>> _latencies = {};
  final Map<String, int> _successes = {};
  final Map<String, int> _failures = {};

  StreamSubscription<RuntimeCompleted>? _compSub;
  StreamSubscription<ExecutionFailed>? _failSub;

  BenchmarkCollector(this.eventBus) {
    _compSub = eventBus.on<RuntimeCompleted>().listen((event) {
      final provider = event.result.providerName;
      final latency = event.result.latency.inMilliseconds.toDouble();
      _latencies.putIfAbsent(provider, () => []).add(latency);
      _successes[provider] = (_successes[provider] ?? 0) + 1;
    });
    _failSub = eventBus.on<ExecutionFailed>().listen((event) {
      // Aggregate generic failures
    });
  }

  double _percentile(List<double> list, double p) {
    if (list.isEmpty) return 0.0;
    final sorted = List<double>.from(list)..sort();
    final index = (p * (sorted.length - 1)).round();
    return sorted[index];
  }

  ProviderBenchmark getBenchmark(String providerName) {
    final list = _latencies[providerName] ?? [];
    final avgLat =
        list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;
    final succ = _successes[providerName] ?? 0;
    final fail = _failures[providerName] ?? 0;
    final total = succ + fail;
    final rel = total == 0 ? 1.0 : succ / total;

    return ProviderBenchmark(
      averageLatencyMs: avgLat,
      reliabilityRate: rel,
      p50LatencyMs: _percentile(list, 0.5),
      p95LatencyMs: _percentile(list, 0.95),
      p99LatencyMs: _percentile(list, 0.99),
    );
  }

  void dispose() {
    _compSub?.cancel();
    _failSub?.cancel();
  }
}
