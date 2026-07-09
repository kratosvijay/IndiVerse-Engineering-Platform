class AgentEnvelope<T> {
  final String envelopeId;
  final String senderId;
  final String recipientId;
  final DateTime timestamp;
  final T payload;

  const AgentEnvelope({
    required this.envelopeId,
    required this.senderId,
    required this.recipientId,
    required this.timestamp,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'envelopeId': envelopeId,
        'senderId': senderId,
        'recipientId': recipientId,
        'timestamp': timestamp.toIso8601String(),
        'payload': payload.toString(),
      };
}
