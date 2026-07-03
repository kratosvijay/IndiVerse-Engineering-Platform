import 'context_source.dart';

class ContextManager {
  final List<ContextSource> _sources = [];

  List<ContextSource> get sources => List.unmodifiable(_sources);

  void addSource(ContextSource source) {
    _sources.add(source);
  }

  void removeSource(ContextSource source) {
    _sources.remove(source);
  }

  void clear() {
    _sources.clear();
  }

  Future<String> assembleContext() async {
    final buffer = StringBuffer();
    for (final source in _sources) {
      final context = await source.fetchContext();
      if (context.isNotEmpty) {
        buffer.writeln(context);
        buffer.writeln("---");
      }
    }
    return buffer.toString().trim();
  }
}
