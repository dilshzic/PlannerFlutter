import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:intl/intl.dart';
import 'package:narwhal/services/ai/scratchpad_task_extractor.dart';

class TaskExtractionBottomSheet extends StatefulWidget {
  final TaskExtractionResult result;
  final List<TaskNode> activeProjects;
  final Function(List<ExtractedTaskSuggestion>) onConfirm;

  const TaskExtractionBottomSheet({
    super.key,
    required this.result,
    required this.activeProjects,
    required this.onConfirm,
  });

  @override
  State<TaskExtractionBottomSheet> createState() => _TaskExtractionBottomSheetState();
}

class _TaskExtractionBottomSheetState extends State<TaskExtractionBottomSheet> {
  late List<ExtractedTaskSuggestion> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = widget.result.tasks;
  }

  int get _selectedCount => _tasks.where((t) => t.isSelected).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extracted Tasks (${_tasks.length})',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (widget.result.summary.isNotEmpty)
                        Text(
                          widget.result.summary,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Task List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _tasks.length,
              separatorBuilder: (_, unused) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return _buildTaskCard(task, theme, isDark);
              },
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Text(
                    '$_selectedCount selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('Add to Planner ($_selectedCount)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _selectedCount == 0
                        ? null
                        : () {
                            final selected = _tasks.where((t) => t.isSelected).toList();
                            widget.onConfirm(selected);
                            Navigator.pop(context);
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(ExtractedTaskSuggestion task, ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isSelected
              ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox and Title
            Row(
              children: [
                Checkbox(
                  value: task.isSelected,
                  activeColor: const Color(0xFF38BDF8),
                  onChanged: (val) {
                    setState(() {
                      task.isSelected = val ?? false;
                    });
                  },
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: task.title,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: task.isSelected ? null : TextDecoration.lineThrough,
                    ),
                    onChanged: (newTitle) => task.title = newTitle,
                  ),
                ),
              ],
            ),

            // Metadata Chips
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Priority
                  _buildPriorityChip(task.priority),

                  // Scheduled Date
                  if (task.scheduledDate != null)
                    _buildChip(
                      Icons.calendar_today,
                      DateFormat('MMM d').format(task.scheduledDate!),
                      const Color(0xFF38BDF8),
                    ),

                  // Duration
                  if (task.durationMinutes > 0)
                    _buildChip(
                      Icons.timer_outlined,
                      '${task.durationMinutes}m',
                      const Color(0xFFA78BFA),
                    ),

                  // Project Suggestion Dropdown
                  _buildProjectDropdown(task, theme),
                ],
              ),
            ),

            if (task.reasoning.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 6),
                child: Text(
                  task.reasoning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(int priority) {
    Color color;
    switch (priority) {
      case 1:
        color = const Color(0xFFEF4444);
        break;
      case 2:
        color = const Color(0xFFF59E0B);
        break;
      case 3:
        color = const Color(0xFF3B82F6);
        break;
      default:
        color = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'P$priority',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDropdown(ExtractedTaskSuggestion task, ThemeData theme) {
    final hasProject = task.suggestedProjectId != null &&
        widget.activeProjects.any((p) => p.id == task.suggestedProjectId);

    final color = task.confidence == 'HIGH'
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: hasProject ? task.suggestedProjectId : null,
        isDense: true,
        borderRadius: BorderRadius.circular(8),
        icon: Icon(Icons.arrow_drop_down, size: 16, color: color),
        selectedItemBuilder: (context) {
          return [
            const Text('Unassigned', style: TextStyle(fontSize: 11)),
            ...widget.activeProjects.map((p) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_outlined, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  p.title,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            )),
          ];
        },
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('None (Unassigned)', style: TextStyle(fontSize: 12)),
          ),
          ...widget.activeProjects.map((p) => DropdownMenuItem<String?>(
            value: p.id,
            child: Text(p.title, style: const TextStyle(fontSize: 12)),
          )),
        ],
        onChanged: (newProjId) {
          setState(() {
            task.suggestedProjectId = newProjId;
            if (newProjId != null) {
              final proj = widget.activeProjects.firstWhere((p) => p.id == newProjId);
              task.suggestedProjectTitle = proj.title;
              task.confidence = 'HIGH';
            } else {
              task.suggestedProjectTitle = null;
            }
          });
        },
      ),
    );
  }
}
