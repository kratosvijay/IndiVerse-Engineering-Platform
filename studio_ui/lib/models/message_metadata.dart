import 'request_metrics.dart';

class MessageMetadata {
  final String? providerId;
  final String? modelId;
  final int? promptTokens;
  final int? completionTokens;
  final int? latencyMs;
  final int? ttftMs;
  final int? streamDurationMs;
  final DateTime? generatedAt;

  const MessageMetadata({
    this.providerId,
    this.modelId,
    this.promptTokens,
    this.completionTokens,
    this.latencyMs,
    this.ttftMs,
    this.streamDurationMs,
    this.generatedAt,
  });

  int get totalTokens => (promptTokens ?? 0) + (completionTokens ?? 0);

  MessageMetadata copyWith({
    String? providerId,
    String? modelId,
    int? promptTokens,
    int? completionTokens,
    int? latencyMs,
    int? ttftMs,
    int? streamDurationMs,
    DateTime? generatedAt,
  }) {
    return MessageMetadata(
      providerId: providerId ?? this.providerId,
      modelId: modelId ?? this.modelId,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      latencyMs: latencyMs ?? this.latencyMs,
      ttftMs: ttftMs ?? this.ttftMs,
      streamDurationMs: streamDurationMs ?? this.streamDurationMs,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'modelId': modelId,
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
        'latencyMs': latencyMs,
        'ttftMs': ttftMs,
        'streamDurationMs': streamDurationMs,
        'generatedAt': generatedAt?.toIso8601String(),
      };

  factory MessageMetadata.fromJson(Map<String, dynamic> json) =>
      MessageMetadata(
        providerId: json['providerId'] as String?,
        modelId: json['modelId'] as String?,
        promptTokens: json['promptTokens'] as int?,
        completionTokens: json['completionTokens'] as int?,
        latencyMs: json['latencyMs'] as int?,
        ttftMs: json['ttftMs'] as int?,
        streamDurationMs: json['streamDurationMs'] as int?,
        generatedAt: json['generatedAt'] != null
            ? DateTime.parse(json['generatedAt'] as String)
            : null,
      );
}
