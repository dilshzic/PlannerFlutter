import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:narwhal/ui/project/project_agent_view_model.dart';
import 'package:narwhal/ui/components/narwhal_icon.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ProjectAgentPanel extends StatefulWidget {
  final VoidCallback? onClose;

  const ProjectAgentPanel({super.key, this.onClose});

  @override
  State<ProjectAgentPanel> createState() => _ProjectAgentPanelState();
}

class _ProjectAgentPanelState extends State<ProjectAgentPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

  void _handleSend(ProjectAgentViewModel viewModel) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    viewModel.sendMessage(text);
    _scrollToBottom();
  }

  void _showBreakdownTopicDialog(BuildContext context, ProjectAgentViewModel viewModel) {
    final topicController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Break down a Goal'),
        content: TextField(
          controller: topicController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Launch marketing campaign, implement database schema',
            labelText: 'What is the goal?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final topic = topicController.text.trim();
              if (topic.isNotEmpty) {
                Navigator.pop(context);
                viewModel.suggestBreakdown(topic);
                _scrollToBottom();
              }
            },
            child: const Text('Break Down'),
          ),
        ],
      ),
    ).then((_) => topicController.dispose());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProjectAgentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                const NarwhalIcon(size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Narwhal Copilot',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Context: ${viewModel.project.title}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.messages.length,
              itemBuilder: (context, index) {
                final message = viewModel.messages[index];
                final isUser = message.isUser;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest.withOpacity(0.8),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUser)
                          SelectableText(
                            message.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimary,
                            ),
                          )
                        else
                          MarkdownBody(
                            data: message.text,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                              p: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              pPadding: const EdgeInsets.only(bottom: 6.0),
                              listBullet: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading Indicator
          if (viewModel.isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Thinking...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Suggestion Checklist UI (Interactive task addition)
          if (viewModel.showBreakdownChecklist && viewModel.suggestedTasks.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.surfaceContainerLowest,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Suggested Task Breakdown',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => viewModel.dismissBreakdown(),
                        ),
                      ],
                    ),
                    const Divider(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: viewModel.suggestedTasks.length,
                        itemBuilder: (context, index) {
                          final taskName = viewModel.suggestedTasks[index];
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              taskName,
                              style: theme.textTheme.bodyMedium,
                            ),
                            value: viewModel.selectedSuggestedTasks[index],
                            onChanged: (val) {
                              if (val != null) {
                                viewModel.toggleSuggestedTaskSelection(index, val);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        viewModel.addSelectedTasksToProject();
                        _scrollToBottom();
                      },
                      icon: const Icon(Icons.add_task),
                      label: const Text('Add Selected to Project'),
                    ),
                  ],
                ),
              ),
            ),

          // Action Suggestion Chips
          if (!viewModel.isLoading && !viewModel.showBreakdownChecklist)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                    child: ActionChip(
                      avatar: const Icon(Icons.schedule, size: 16),
                      label: const Text('Analyze Timeline'),
                      onPressed: () {
                        viewModel.analyzeSchedule();
                        _scrollToBottom();
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                    child: ActionChip(
                      avatar: const Icon(Icons.playlist_add, size: 16),
                      label: const Text('Break Down Goal'),
                      onPressed: () => _showBreakdownTopicDialog(context, viewModel),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                    child: ActionChip(
                      avatar: const Icon(Icons.delete_sweep_outlined, size: 16),
                      label: const Text('Clear Chat'),
                      onPressed: () => viewModel.clearChat(),
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _handleSend(viewModel),
                    decoration: InputDecoration(
                      hintText: 'Ask Narwhal about this project...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: () => _handleSend(viewModel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
