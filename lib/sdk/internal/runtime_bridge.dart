import '../../../core/events/event_bus.dart';
import '../../../core/events/runtime_event.dart';

class RuntimeBridge {
  final EventBus eventBus;

  RuntimeBridge(this.eventBus);

  void dispatch(RuntimeEvent event) {
    eventBus.publish(event);
  }
}
