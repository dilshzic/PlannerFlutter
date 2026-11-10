import 'package:flutter/material.dart';
import 'package:flt_alx_core_ai/flt_alx_core_ai.dart';
import 'package:provider/provider.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/ui/components/narwhal_icon.dart';
import 'components/chat_message.dart';
import 'components/message_bubble.dart';
import 'components/chat_input_bar.dart';
import 'components/suggestion_chips.dart';
import 'components/typing_indicator.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _suggestions = [
    "Help me plan my day",
    "Create a checklist for a gym session",
    "How to manage procrastination?",
    "Review my schedule for time blocks",
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(ChatMessage(
      text: "Hello! I am Narwhal, your smart AI planner assistant. How can I help you organize your tasks, projects, or schedule today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitPrompt([String? customPrompt]) async {
    final text = customPrompt ?? _promptController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (customPrompt == null) {
      _promptController.clear();
    }

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    final manager = context.read<AiBrainManager>();

    // Prepare message history for multi-turn context
    final historyList = _messages
        .sublist(0, _messages.length - 1)
        .where((m) => m.text != "Hello! I am Narwhal, your smart AI planner assistant. How can I help you organize your tasks, projects, or schedule today?")
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();

    // Limit to last 10 turns (context window) to optimize tokens
    final limitedHistory = historyList.length > 10
        ? historyList.sublist(historyList.length - 10)
        : historyList;

    try {
      final result = await manager.askBrain(
        text,
        config: manager.defaultConfig.copyWith(
          metadata: {
            ...manager.defaultConfig.metadata,
            'history': limitedHistory,
          },
        ),
      );
      if (!mounted) return;

      var responseText = result.text.isEmpty ? 'No response returned from the assistant.' : result.text;

      // Parse commands
      final addTaskRegex = RegExp(r'\[ADD_TASK:\s*(.*?)\]');
      final completeTaskRegex = RegExp(r'\[COMPLETE_TASK:\s*(.*?)\]');

      final addMatches = addTaskRegex.allMatches(responseText);
      final completeMatches = completeTaskRegex.allMatches(responseText);

      final nodeRepo = context.read<TaskNodeRepository>();

      // Execute ADD_TASK
      for (final match in addMatches) {
        final taskTitle = match.group(1)?.trim();
        if (taskTitle != null && taskTitle.isNotEmpty) {
          final node = TaskNode(
            title: taskTitle,
            nodeType: NodeType.task,
          );
          await nodeRepo.upsertNode(node);
        }
      }

      // Execute COMPLETE_TASK
      for (final match in completeMatches) {
        final query = match.group(1)?.trim();
        if (query != null && query.isNotEmpty) {
          final allNodes = await nodeRepo.getAllNodes();
          // Find matching task node
          final matchingNode = allNodes.firstWhere(
            (n) => n.id == query || n.title.toLowerCase().trim() == query.toLowerCase().trim(),
            orElse: () => allNodes.firstWhere(
              (n) => n.title.toLowerCase().contains(query.toLowerCase()),
              orElse: () => TaskNode(title: '', nodeType: NodeType.task), // Dummy
            ),
          );
          if (matchingNode.id.isNotEmpty) {
            await nodeRepo.toggleNodeCompletion(matchingNode.id, true);
          }
        }
      }

      // Clean the response text from the tags for beautiful display
      responseText = responseText
          .replaceAll(addTaskRegex, '')
          .replaceAll(completeTaskRegex, '')
          .trim();

      setState(() {
        _messages.add(ChatMessage(
          text: responseText.isEmpty ? 'Action performed successfully!' : responseText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I encountered an error: $e",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: "Hello again! I am Narwhal. How can I assist you with your planning now?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const NarwhalIcon(
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Narwhal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online & ready',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Chat',
            onPressed: _messages.length > 1 ? _clearChat : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(message: message);
              },
            ),
          ),

          // Loading/Typing Indicator
          if (_isLoading) const TypingIndicator(),

          // Suggestion Chips (only when not loading and input is empty)
          if (!_isLoading && _messages.length <= 1)
            SuggestionChips(
              suggestions: _suggestions,
              onSuggestionSelected: _submitPrompt,
            ),

          // Input Section
          ChatInputBar(
            controller: _promptController,
            onSubmit: () => _submitPrompt(),
          ),
        ],
      ),
    );
  }


}