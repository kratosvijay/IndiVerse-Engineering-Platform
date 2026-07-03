import '../contracts/runtime_core.dart';
import '../contracts/ai_provider.dart';
import '../contracts/plugin.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';
import '../models/execution_result.dart';
import '../events/event_bus.dart';
import '../events/runtime_event.dart';
import 'pipeline.dart';
import 'state.dart';
import '../models/ai_chunk.dart';
import '../registry/provider_registry.dart';
import '../registry/model_registry.dart';

class Runtime implements RuntimeCore {
  final ProviderRegistry providerRegistry;
  final ModelRegistry modelRegistry;
  final EventBus eventBus;
  final Pipeline pipeline = Pipeline();
  final List<AIPlugin> _plugins = [];

  RuntimeState _state = RuntimeState.idle;

  Runtime({
    ProviderRegistry? providerRegistry,
    ModelRegistry? modelRegistry,
    EventBus? eventBus,
  })  : providerRegistry = providerRegistry ?? ProviderRegistry(),
        modelRegistry = modelRegistry ?? ModelRegistry(),
        eventBus = eventBus ?? EventBus();

  RuntimeState get state => _state;
  List<AIPlugin> get plugins => List.unmodifiable(_plugins);

  void registerPlugin(AIPlugin plugin) {
    _plugins.add(plugin);
  }

  void _transition(RuntimeState newState) {
    _state = newState;
  }

  @override
  Future<ExecutionResult> execute(AIRequest request) async {
    final startTime = DateTime.now();
    final eventId = "exec-${startTime.millisecondsSinceEpoch}";

    _transition(RuntimeState.preparing);

    eventBus.publish(RuntimeStarted(
      timestamp: startTime,
      eventId: eventId,
      request: request,
    ));

    AIProvider provider;
    try {
      provider = providerRegistry.resolve(request.modelName);

      _transition(RuntimeState.executing);

      eventBus.publish(ProviderSelected(
        timestamp: DateTime.now(),
        eventId: eventId,
        providerName: provider.name,
        modelName: request.modelName,
      ));
    } catch (e) {
      _transition(RuntimeState.failed);

      eventBus.publish(ExecutionFailed(
        timestamp: DateTime.now(),
        eventId: eventId,
        error: e.toString(),
        details: const ["Model lookup failed"],
      ));
      rethrow;
    }

    final errors = <String>[];
    AIResponse? response;

    try {
      // 1. Run beforeExecute hooks for plugins
      var req = request;
      for (final plugin in _plugins) {
        req = await plugin.beforeExecute(req);
      }

      // 2. Invoke middleware pipeline and provider execution
      final rawResponse =
          await pipeline.execute(req, (r) => provider.execute(r));

      // 3. Run afterExecute hooks for plugins
      var processedResponse = rawResponse;
      for (final plugin in _plugins) {
        processedResponse = await plugin.afterExecute(processedResponse);
      }
      response = processedResponse;

      _transition(RuntimeState.completed);
    } catch (e) {
      _transition(RuntimeState.failed);
      errors.add(e.toString());

      eventBus.publish(ExecutionFailed(
        timestamp: DateTime.now(),
        eventId: eventId,
        error: e.toString(),
        details: const [],
      ));
      rethrow;
    }

    final latency = DateTime.now().difference(startTime);
    final result = ExecutionResult(
      latency: latency,
      retries: 0,
      errors: errors,
      providerName: provider.name,
      response: response,
    );

    eventBus.publish(RuntimeCompleted(
      timestamp: DateTime.now(),
      eventId: eventId,
      result: result,
    ));

    return result;
  }

  @override
  Stream<AIChunk> executeStream(AIRequest request) {
    _transition(RuntimeState.streaming);
    final provider = providerRegistry.resolve(request.modelName);
    return provider.executeStream(request).map((chunk) {
      if (chunk.finishReason != null) {
        _transition(RuntimeState.completed);
      }
      return chunk;
    });
  }
}
