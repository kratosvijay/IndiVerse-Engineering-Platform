import 'dart:convert';
import '../runtime/runtime.dart';

class RuntimeInspector {
  final Runtime runtime;

  RuntimeInspector(this.runtime);

  Map<String, dynamic> inspect() {
    return {
      "runtimeVersion": "0.3.0",
      "state": runtime.state.toString().split('.').last,
      "plugins": runtime.plugins.map((p) => p.name).toList(),
      "registeredProviders": runtime.providerRegistry.registeredProviders,
      "pipelineMiddlewareCount": runtime.pipeline.middlewares.length,
    };
  }

  String exportJson() {
    return jsonEncode(inspect());
  }
}
