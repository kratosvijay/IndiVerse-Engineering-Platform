import 'review_models.dart';

class ExplainabilityEngine {
  final List<ExplainabilityTrace> traces = [];

  void logTrace(ExplainabilityTrace trace) {
    traces.add(trace);
  }

  ExplainabilityTrace? getTrace(String actionId) {
    for (final t in traces) {
      if (t.actionId == actionId) {
        return t;
      }
    }
    return null;
  }
}
