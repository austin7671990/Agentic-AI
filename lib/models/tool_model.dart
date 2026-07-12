enum ToolCategory { device, input, shell, file, web, sandbox }

class ToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parametersSchema;
  final bool requiresConfirmation;
  final ToolCategory category;
  final Future<dynamic> Function(Map<String, dynamic> args) handler;

  ToolDefinition({
    required this.name,
    required this.description,
    required this.parametersSchema,
    this.requiresConfirmation = false,
    required this.category,
    required this.handler,
  });

  String get promptDescription {
    final params = parametersSchema.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    final confirm = requiresConfirmation ? ' **Requires confirmation.**' : '';
    return '- $name($params): $description.$confirm';
  }
}

class ToolCall {
  final String toolName;
  final Map<String, dynamic> parameters;
  final String callId;

  ToolCall({
    required this.toolName,
    required this.parameters,
    required this.callId,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      toolName: json['tool'] ?? json['name'] ?? '',
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      callId: json['call_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}

class ToolResult {
  final String callId;
  final bool success;
  final dynamic data;
  final String? error;
  final int durationMs;

  ToolResult({
    required this.callId,
    required this.success,
    this.data,
    this.error,
    required this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'call_id': callId,
    'success': success,
    'data': data?.toString(),
    'error': error,
    'duration_ms': durationMs,
  };
}

class ToolSystemPromptBuilder {
  static String buildPrompt(List<ToolDefinition> tools) {
    final buffer = StringBuffer();
    buffer.writeln('You have access to the following tools. When you need to use a tool, respond with a JSON object in this exact format:');
    buffer.writeln('{"tool": "tool_name", "parameters": {"param1": "value1"}}');
    buffer.writeln();
    buffer.writeln('Available tools:');
    for (final tool in tools) {
      buffer.writeln(tool.promptDescription);
    }
    buffer.writeln();
    buffer.writeln('Rules:');
    buffer.writeln('- Only use tools when necessary');
    buffer.writeln('- Always confirm with user before destructive actions');
    buffer.writeln('- If a tool fails, explain the error and try an alternative');
    buffer.writeln('- After using tools, summarize what you did in natural language');
    return buffer.toString();
  }
}
