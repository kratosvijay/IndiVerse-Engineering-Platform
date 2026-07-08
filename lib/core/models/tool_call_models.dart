enum ToolCallStatus {
  pendingPermission,
  running,
  completed,
  failed,
}

class ToolCallState {
  final String toolCallId;
  final String toolName;
  final Map<String, dynamic> arguments;
  final ToolCallStatus status;
  final String? progressMessage;
  final ToolCallResult? result;
  final String? errorMessage;

  const ToolCallState({
    required this.toolCallId,
    required this.toolName,
    required this.arguments,
    required this.status,
    this.progressMessage,
    this.result,
    this.errorMessage,
  });

  ToolCallState copyWith({
    String? toolCallId,
    String? toolName,
    Map<String, dynamic>? arguments,
    ToolCallStatus? status,
    String? progressMessage,
    ToolCallResult? result,
    String? errorMessage,
  }) {
    return ToolCallState(
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
      arguments: arguments ?? this.arguments,
      status: status ?? this.status,
      progressMessage: progressMessage ?? this.progressMessage,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum ToolCategory {
  workspace,
  editor,
  diagnostics,
  git,
  filesystem,
  terminal,
  mcp,
}

enum PermissionDecision {
  allowOnce,
  allowAlways,
  deny,
  denyAlways,
}

class ToolDescriptor {
  final String id;
  final String name;
  final String description;
  final ToolCategory category;
  final bool requiresPermission;
  final bool readOnly;
  final bool destructive;
  final bool modifiesWorkspace;
  final List<String> tags;
  final Duration timeout;

  const ToolDescriptor({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.requiresPermission,
    required this.readOnly,
    required this.destructive,
    required this.modifiesWorkspace,
    required this.tags,
    this.timeout = const Duration(seconds: 30),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.name,
        'requiresPermission': requiresPermission,
        'readOnly': readOnly,
        'destructive': destructive,
        'modifiesWorkspace': modifiesWorkspace,
        'tags': tags,
        'timeoutMs': timeout.inMilliseconds,
      };

  factory ToolDescriptor.fromJson(Map<String, dynamic> json) => ToolDescriptor(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        category:
            ToolCategory.values.firstWhere((e) => e.name == json['category']),
        requiresPermission: json['requiresPermission'] as bool? ?? false,
        readOnly: json['readOnly'] as bool? ?? false,
        destructive: json['destructive'] as bool? ?? false,
        modifiesWorkspace: json['modifiesWorkspace'] as bool? ?? false,
        tags: List<String>.from(json['tags'] as List? ?? []),
        timeout: Duration(milliseconds: json['timeoutMs'] as int? ?? 30000),
      );
}

class ToolCallRequest {
  final String toolCallId;
  final String toolName;
  final Map<String, dynamic> arguments;
  final String? parentToolCallId;
  final int depth;

  const ToolCallRequest({
    required this.toolCallId,
    required this.toolName,
    required this.arguments,
    this.parentToolCallId,
    this.depth = 0,
  });

  Map<String, dynamic> toJson() => {
        'toolCallId': toolCallId,
        'toolName': toolName,
        'arguments': arguments,
        if (parentToolCallId != null) 'parentToolCallId': parentToolCallId,
        'depth': depth,
      };

  factory ToolCallRequest.fromJson(Map<String, dynamic> json) =>
      ToolCallRequest(
        toolCallId: json['toolCallId'] as String,
        toolName: json['toolName'] as String,
        arguments: Map<String, dynamic>.from(json['arguments'] as Map? ?? {}),
        parentToolCallId: json['parentToolCallId'] as String?,
        depth: json['depth'] as int? ?? 0,
      );
}

class ToolOutput {
  final Object? data;
  final String? displayText;
  final String? mimeType;

  const ToolOutput({
    this.data,
    this.displayText,
    this.mimeType,
  });

  Map<String, dynamic> toJson() => {
        if (data != null) 'data': data,
        if (displayText != null) 'displayText': displayText,
        if (mimeType != null) 'mimeType': mimeType,
      };

  factory ToolOutput.fromJson(Map<String, dynamic> json) => ToolOutput(
        data: json['data'],
        displayText: json['displayText'] as String?,
        mimeType: json['mimeType'] as String?,
      );
}

class ToolCallResult {
  final bool success;
  final ToolOutput output;
  final Duration duration;
  final bool cacheable;
  final String? errorCode;

  const ToolCallResult({
    required this.success,
    required this.output,
    required this.duration,
    this.cacheable = false,
    this.errorCode,
  });

  Map<String, dynamic> toJson() => {
        'success': success,
        'output': output.toJson(),
        'durationMs': duration.inMilliseconds,
        'cacheable': cacheable,
        if (errorCode != null) 'errorCode': errorCode,
      };

  factory ToolCallResult.fromJson(Map<String, dynamic> json) => ToolCallResult(
        success: json['success'] as bool,
        output:
            ToolOutput.fromJson(json['output'] as Map<String, dynamic>? ?? {}),
        duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
        cacheable: json['cacheable'] as bool? ?? false,
        errorCode: json['errorCode'] as String?,
      );
}
