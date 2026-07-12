import 'package:get/get.dart';
import '../models/memory_model.dart';
import 'memory_service.dart';

class SummarizerService extends GetxService {
  final MemoryService _memory;

  SummarizerService() : _memory = Get.find<MemoryService>();

  /// Get existing summary or return null
  Future<String?> getOrCreateSummary() async {
    return await _memory.getLatestSummary();
  }

  /// Create a summary from conversation turns using the LLM
  Future<String> summarize(List<ConversationTurn> turns) async {
    if (turns.isEmpty) return '';

    // Build a text representation of the conversation
    final buffer = StringBuffer();
    buffer.writeln('Summarize the following conversation concisely:');
    buffer.writeln();

    for (final turn in turns) {
      buffer.writeln('${turn.role}: ${turn.content}');
    }

    // For now, return a simple extractive summary
    // In production, this would call the LLM to generate an abstractive summary
    return _createExtractiveSummary(turns);
  }

  String _createExtractiveSummary(List<ConversationTurn> turns) {
    final keyPoints = <String>[];

    for (final turn in turns) {
      if (turn.role == 'user') {
        // Extract key facts from user messages
        final content = turn.content;
        if (content.length > 20) {
          // Take first sentence as key point
          final firstSentence = content.split('.').first;
          if (firstSentence.length > 10) {
            keyPoints.add('User asked about: $firstSentence');
          }
        }
      } else if (turn.role == 'assistant') {
        // Note important assistant responses
        if (turn.content.contains('tool') || turn.content.contains('executed')) {
          keyPoints.add('Assistant performed a device action');
        }
      }
    }

    if (keyPoints.isEmpty) {
      return 'General conversation about various topics.';
    }

    return keyPoints.take(5).join('. ') + '.';
  }

  /// Trigger summarization if conversation is getting long
  Future<void> maybeSummarize(int turnCount) async {
    if (turnCount > 0 && turnCount % 10 == 0) {
      // Every 10 turns, summarize the oldest 4
      final allTurns = await _memory.getRecentTurns(turnCount);
      if (allTurns.length >= 6) {
        final turnsToSummarize = allTurns.take(4).toList();
        final summary = await summarize(turnsToSummarize);
        await _memory.storeSummary(summary);
      }
    }
  }
}