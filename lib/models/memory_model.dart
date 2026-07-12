import 'dart:convert';

enum MemoryType { episodic, semantic, procedural }

abstract class Memory {
  final String id;
  final DateTime timestamp;
  final MemoryType type;
  double importance;
  final String content;
  String? summary;
  final Map<String, dynamic> metadata;

  Memory({
    required this.id,
    required this.timestamp,
    required this.type,
    this.importance = 0.5,
    required this.content,
    this.summary,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson();
}

class EpisodicMemory extends Memory {
  final String event;
  final String? location;
  final List<String> participants;
  final String? outcome;

  EpisodicMemory({
    required super.id,
    required super.timestamp,
    super.importance,
    required super.content,
    super.summary,
    super.metadata,
    required this.event,
    this.location,
    this.participants = const [],
    this.outcome,
  }) : super(type: MemoryType.episodic);

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'episodic',
    'timestamp': timestamp.toIso8601String(),
    'importance': importance,
    'content': content,
    'event': event,
    'location': location,
    'participants': participants,
    'outcome': outcome,
  };
}

class SemanticMemory extends Memory {
  final String subject;
  final String predicate;
  final String? object;
  final double confidence;
  final DateTime? expiresAt;

  SemanticMemory({
    required super.id,
    required super.timestamp,
    super.importance,
    required super.content,
    super.summary,
    super.metadata,
    required this.subject,
    required this.predicate,
    this.object,
    this.confidence = 1.0,
    this.expiresAt,
  }) : super(type: MemoryType.semantic);

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'semantic',
    'timestamp': timestamp.toIso8601String(),
    'importance': importance,
    'content': content,
    'subject': subject,
    'predicate': predicate,
    'object': object,
    'confidence': confidence,
  };
}

class ProceduralMemory extends Memory {
  final String taskName;
  final List<String> steps;
  final String? preconditions;
  final String? expectedOutcome;
  int successCount;
  int failureCount;

  ProceduralMemory({
    required super.id,
    required super.timestamp,
    super.importance,
    required super.content,
    super.summary,
    super.metadata,
    required this.taskName,
    required this.steps,
    this.preconditions,
    this.expectedOutcome,
    this.successCount = 0,
    this.failureCount = 0,
  }) : super(type: MemoryType.procedural);

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'procedural',
    'timestamp': timestamp.toIso8601String(),
    'importance': importance,
    'content': content,
    'taskName': taskName,
    'steps': steps,
    'successCount': successCount,
    'failureCount': failureCount,
  };
}

class ConversationTurn {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final List<ToolCallRecord>? toolCalls;
  final String? modelName;
  final int? tokenCount;

  ConversationTurn({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.toolCalls,
    this.modelName,
    this.tokenCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ToolCallRecord {
  final String toolName;
  final Map<String, dynamic> parameters;
  final String? result;
  final bool success;
  final int durationMs;

  ToolCallRecord({
    required this.toolName,
    required this.parameters,
    this.result,
    required this.success,
    required this.durationMs,
  });
}

class AssembledContext {
  final String systemPrompt;
  final String? summary;
  final List<Memory> retrievedMemories;
  final List<ConversationTurn> recentTurns;
  final String userMessage;

  AssembledContext({
    required this.systemPrompt,
    this.summary,
    required this.retrievedMemories,
    required this.recentTurns,
    required this.userMessage,
  });

  String toPromptString() {
    final buffer = StringBuffer();
    buffer.writeln(systemPrompt);
    if (summary != null && summary!.isNotEmpty) {
      buffer.writeln('\n[Previous conversation summary: $summary]');
    }
    if (retrievedMemories.isNotEmpty) {
      buffer.writeln('\n[Relevant memories:]');
      for (final m in retrievedMemories) {
        buffer.writeln('- ${m.content}');
      }
    }
    for (final turn in recentTurns) {
      buffer.writeln('<|${turn.role}|>');
      buffer.writeln(turn.content);
      buffer.writeln('<|end|>');
    }
    buffer.writeln('<|user|>');
    buffer.writeln(userMessage);
    buffer.writeln('<|end|>');
    buffer.writeln('<|assistant|>');
    return buffer.toString();
  }
}