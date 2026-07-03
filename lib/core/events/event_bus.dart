import 'dart:async';
import 'runtime_event.dart';

class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final _controller = StreamController<RuntimeEvent>.broadcast();

  Stream<RuntimeEvent> get stream => _controller.stream;

  Stream<T> on<T extends RuntimeEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  void publish(RuntimeEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}
