import 'package:get/get.dart';
import '../models/memory_model.dart';
import 'memory_service.dart';
import 'summarizer_service.dart';

class ContextAssembler {
  final MemoryService _memory;
  final SummarizerService? _summarizer;

  ContextAssembler() :
    _memory = Get.find<MemoryService>(),
    _summarizer = Get.find<SummarizerService>();

  static const int maxContextTokens = 4096;
  static const int systemPromptBudget = 800;
  static const int summaryBudget = 500;
  static const int memoryBudget = 800;
  static const int recentTurnsBudget = 1200;
  static const int userMessageBudget = 200;

  Future<AssembledContext> assemble(
    String currentUserMessage, {
    String? systemPrompt,
  }) async {
    // 1. Get recent conversation turns (last 6)
    final recentTurns = await _memory.getRecentTurns(6);

    // 2. Get conversation summary
    final summary = await _summarizer?.getOrCreateSummary();

    // 3. Search for relevant memories
    final searchQuery = _buildSearchQuery(currentUserMessage, recentTurns);
    final relevantMemories = await _memory.search(searchQuery, limit: 10);

    // 4. Build the assembled context
    return AssembledContext(
      systemPrompt: systemPrompt ?? _defaultSystemPrompt(),
      summary: summary,
      retrievedMemories: relevantMemories,
      recentTurns: recentTurns,
      userMessage: currentUserMessage,
    );
  }

  String _buildSearchQuery(String userMessage, List<ConversationTurn> recentTurns) {
    final buffer = StringBuffer(userMessage);
    for (final turn in recentTurns.take(2)) {
      buffer.write(' ');
      buffer.write(turn.content);
    }
    return buffer.toString();
  }

  String _defaultSystemPrompt() {
    return 'You are a helpful AI assistant running locally on the user\'s Android device. You have access to tools for device control. Respond concisely and helpfully.';
  }

  /// Estimate token count (rough approximation: 1 token ~ 4 chars)
  static int estimateTokens(String text) {
    return (text.length / 4).ceil();
  }
}