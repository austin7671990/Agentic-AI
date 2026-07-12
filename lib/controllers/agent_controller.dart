import 'dart:async';
import 'package:get/get.dart';
import '../services/llm_service.dart';
import '../services/tool_service.dart';
import '../services/context_assembler.dart';
import '../services/memory_service.dart';
import '../models/tool_model.dart';
import '../models/memory_model.dart';

enum AgentState { idle, planning, executingTool, observing, confirming, error }

class AgentController extends GetxController {
  final LlmService _llm = Get.find<LlmService>();
  final ToolService _tools = Get.find<ToolService>();
  final ContextAssembler _assembler = Get.find<ContextAssembler>();
  final MemoryService _memory = Get.find<MemoryService>();

  final Rx<AgentState> state = AgentState.idle.obs;
  final RxString currentAction = ''.obs;
  final RxString lastResponse = ''.obs;
  final RxList<Map<String, dynamic>> executionLog = <Map<String, dynamic>>[].obs;

  // -- Pending confirmation state (exposed for UI) --
  final RxnString pendingToolName = RxnString();
  final Rx<Map<String, dynamic>> pendingToolParams = Rx<Map<String, dynamic>>({});
  final RxnString pendingOriginalMessage = RxnString();

  /// Main entry: process a user message through the agent loop
  Future<String> processMessage(String userMessage) async {
    state.value = AgentState.planning;
    currentAction.value = 'Thinking...';

    try {
      // 1. Assemble context with memory
      final context = await _assembler.assemble(userMessage);

      // 2. Add tool definitions if tools are enabled
      final toolPrompt = _tools.getToolSystemPrompt();
      final fullSystemPrompt = toolPrompt.isNotEmpty
          ? '${context.systemPrompt}\n\n$toolPrompt'
          : context.systemPrompt;

      // 3. Build message list
      final messages = <Map<String, String>>[];

      // Add summary as context
      if (context.summary != null && context.summary!.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': '[Previous context: ${context.summary}]',
        });
      }

      // Add retrieved memories
      for (final memory in context.retrievedMemories) {
        messages.add({
          'role': 'system',
          'content': '[Memory: ${memory.content}]',
        });
      }

      // Add recent conversation turns
      for (final turn in context.recentTurns) {
        messages.add({
          'role': turn.role,
          'content': turn.content,
        });
      }

      // Add current user message
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      // 4. Generate response
      state.value = AgentState.executingTool;
      final responseBuffer = StringBuffer();

      await for (final chunk in _llm.generate(
        messages: messages,
        systemPrompt: fullSystemPrompt,
      )) {
        responseBuffer.write(chunk);
      }

      final rawResponse = responseBuffer.toString();

      // 5. Check for tool calls in response
      final toolCall = _tools.parseToolCall(rawResponse);
      if (toolCall != null) {
        return await _handleToolCall(toolCall, userMessage);
      }

      // 6. Store conversation and return
      state.value = AgentState.idle;
      currentAction.value = '';

      await _storeConversation(userMessage, rawResponse);

      // Extract facts from conversation
      await _memory.extractAndStoreFacts('$userMessage $rawResponse');

      lastResponse.value = rawResponse;
      return rawResponse;
    } catch (e) {
      state.value = AgentState.error;
      currentAction.value = 'Error: $e';
      _clearPendingConfirmation();
      return 'I encountered an error: $e';
    }
  }

  /// Handle a tool call from the model
  Future<String> _handleToolCall(ToolCall call, String originalMessage) async {
    // Check if confirmation is needed
    if (_tools.requiresConfirmation(call.toolName)) {
      state.value = AgentState.confirming;
      currentAction.value = 'Confirm: ${call.toolName}(${call.parameters})';
      // Store pending confirmation for UI
      pendingToolName.value = call.toolName;
      pendingToolParams.value = Map<String, dynamic>.from(call.parameters);
      pendingOriginalMessage.value = originalMessage;
      return '[CONFIRM_REQUIRED] I need to run `${call.toolName}` with parameters: ${call.parameters}. Say "yes" to allow, or tap the buttons below.';
    }

    // Execute tool directly (no confirmation needed)
    return _executeToolDirect(call, originalMessage);
  }

  /// User confirmed a pending action via UI button
  Future<String> confirmPendingAction() async {
    final toolName = pendingToolName.value;
    final params = pendingToolParams.value;
    final originalMsg = pendingOriginalMessage.value;

    if (toolName == null || originalMsg == null) {
      state.value = AgentState.error;
      currentAction.value = 'No pending confirmation';
      return 'Error: No pending action to confirm.';
    }

    _clearPendingConfirmation();
    final call = ToolCall(
      toolName: toolName,
      parameters: params,
      callId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    return _executeToolDirect(call, originalMsg);
  }

  /// User denied/cancelled a pending action
  void denyPendingAction() {
    _clearPendingConfirmation();
    state.value = AgentState.idle;
    currentAction.value = '';
  }

  void _clearPendingConfirmation() {
    pendingToolName.value = null;
    pendingToolParams.value = {};
    pendingOriginalMessage.value = null;
  }

  Future<String> _executeToolDirect(ToolCall call, String originalMessage) async {
    state.value = AgentState.executingTool;
    currentAction.value = 'Running ${call.toolName}...';

    final result = await _tools.executeTool(call);

    // Store in execution log
    executionLog.add({
      'tool': call.toolName,
      'params': call.parameters,
      'success': result.success,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Get follow-up response from LLM with tool result
    state.value = AgentState.observing;
    currentAction.value = 'Processing result...';

    final followUpMessages = <Map<String, String>>[
      {'role': 'user', 'content': originalMessage},
      {'role': 'assistant', 'content': 'I used `${call.toolName}` and got: ${result.success ? result.data : result.error}'},
    ];

    final responseBuffer = StringBuffer();
    await for (final chunk in _llm.generate(messages: followUpMessages)) {
      responseBuffer.write(chunk);
    }

    final finalResponse = responseBuffer.toString();

    await _storeConversation(originalMessage, finalResponse);

    state.value = AgentState.idle;
    currentAction.value = '';
    lastResponse.value = finalResponse;
    return finalResponse;
  }

  Future<void> _storeConversation(String userMessage, String assistantResponse) async {
    await _memory.storeConversationTurn(ConversationTurn(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: userMessage,
      timestamp: DateTime.now(),
    ));

    await _memory.storeConversationTurn(ConversationTurn(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: assistantResponse,
      timestamp: DateTime.now(),
    ));
  }
}
