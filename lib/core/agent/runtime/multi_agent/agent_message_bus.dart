import 'dart:async';
import 'agent_envelope.dart';

class AgentMessageBus {
  final StreamController<AgentEnvelope<dynamic>> _controller =
      StreamController<AgentEnvelope<dynamic>>.broadcast(sync: true);

  Stream<AgentEnvelope<dynamic>> get messages => _controller.stream;

  void publish<T>(AgentEnvelope<T> envelope) {
    _controller.add(envelope);
  }

  Stream<AgentEnvelope<T>> filterByType<T>() {
    return _controller.stream
        .where((envelope) => envelope.payload is T)
        .map((envelope) => AgentEnvelope<T>(
              envelopeId: envelope.envelopeId,
              senderId: envelope.senderId,
              recipientId: envelope.recipientId,
              timestamp: envelope.timestamp,
              payload: envelope.payload as T,
            ));
  }

  void close() {
    _controller.close();
  }
}
