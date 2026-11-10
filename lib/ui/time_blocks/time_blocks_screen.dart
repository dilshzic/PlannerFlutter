import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:narwhal/data/repository/time_block_repository.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/services/focus_timer_service.dart';
import 'package:narwhal/ui/time_blocks/time_blocks_view_model.dart';
import 'package:narwhal/ui/focus/focus_screen.dart';
import 'package:flutter_core_entities/task_node.dart';

class TimeBlocksScreen extends StatelessWidget {
  const TimeBlocksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TimeBlocksViewModel(
        context.read<TimeBlockRepository>(),
        context.read<FocusTimerService>(),
      ),
      child: Consumer3<TimeBlocksViewModel, TaskNodeRepository, FocusTimerService>(
        builder: (context, viewModel, nodeRepo, focusTimer, child) {
          final colorScheme = Theme.of(context).colorScheme;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Time Blocks'),
              actions: [
                if (!viewModel.isToday)
                  TextButton.icon(
                    onPressed: viewModel.goToToday,
                    icon: const Icon(Icons.today, size: 18),
                    label: const Text('Today'),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Projects'),
                        icon: Icon(Icons.folder_outlined),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Tasks'),
                        icon: Icon(Icons.check_circle_outline),
                      ),
                    ],
                    selected: {viewModel.showTasks},
                    onSelectionChanged: (set) => viewModel.toggleShowTasks(set.first),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                _buildDateNavBar(context, viewModel),
                if (focusTimer.hasActiveSession)
                  _buildActiveFocusTimerHero(context, viewModel, focusTimer),
                _buildTargetSelector(context, viewModel, nodeRepo, focusTimer),
                _buildTimeWalletBanner(context, viewModel),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<List<TaskNode>>>(
                    future: Future.wait([
                      nodeRepo.getNodesByType(NodeType.project),
                      nodeRepo.getNodesByType(NodeType.task),
                    ]),
                    builder: (context, snapshot) {
                      final projects = snapshot.data?[0] ?? [];
                      final tasks = snapshot.data?[1] ?? [];

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Center(
                          child: Column(
                            children: [
                              Wrap(
                                spacing: 20,
                                runSpacing: 20,
                                alignment: WrapAlignment.center,
                                children: List.generate(4, (gridIndex) {
                                  return _buildGridCard(
                                    context,
                                    viewModel,
                                    projects,
                                    tasks,
                                    gridIndex,
                                  );
                                }),
                              ),
                              const SizedBox(height: 24),
                              _buildGridLegend(context),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateNavBar(BuildContext context, TimeBlocksViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous Day',
            onPressed: viewModel.previousDay,
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: viewModel.selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                viewModel.selectDate(picked);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    viewModel.formattedDate,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next Day',
            onPressed: viewModel.nextDay,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFocusTimerHero(
    BuildContext context,
    TimeBlocksViewModel viewModel,
    FocusTimerService focusTimer,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    Color activeColor = colorScheme.primary;
    if (focusTimer.activeColorHex != null && focusTimer.activeColorHex!.isNotEmpty) {
      try {
        activeColor = Color(int.parse(focusTimer.activeColorHex!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            activeColor.withValues(alpha: 0.15),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activeColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: focusTimer.isRunning ? activeColor : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      focusTimer.isRunning ? Icons.fiber_manual_record : Icons.pause,
                      size: 10,
                      color: focusTimer.isRunning ? Colors.white : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      focusTimer.isRunning ? "FOCUS SESSION" : "PAUSED",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: focusTimer.isRunning ? Colors.white : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  focusTimer.activeTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen_rounded),
                tooltip: "Open Fullscreen Focus",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FocusScreen(task: focusTimer.activeTask),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Timer Body
          Row(
            children: [
              // Circular progress ring
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 7,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                    ),
                    CircularProgressIndicator(
                      value: focusTimer.currentBlockProgress,
                      strokeWidth: 7,
                      color: activeColor,
                      strokeCap: StrokeCap.round,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${(focusTimer.currentBlockProgress * 100).toInt()}%",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: activeColor,
                          ),
                        ),
                        Text(
                          focusTimer.remainingBlockTimeString,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          "${focusTimer.sessionBlocksEarned} Blocks Earned (${focusTimer.sessionBlocksEarned * 6}m)",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Session: ${focusTimer.totalSessionTimeString} • Block: ${focusTimer.currentBlockTimeString} / 06:00",
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Next block lands in slot #${viewModel.activeBlockIndex + 1}",
                      style: TextStyle(fontSize: 11, color: activeColor, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: viewModel.stopFocusSession,
                icon: const Icon(Icons.stop_rounded, size: 18, color: Colors.red),
                label: const Text("Stop", style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              if (focusTimer.activeTask != null) ...[
                FilledButton.tonalIcon(
                  onPressed: viewModel.finishTask,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.green),
                  label: const Text("Finish Task", style: TextStyle(color: Colors.green)),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton.icon(
                onPressed: viewModel.toggleFocusPlayPause,
                icon: Icon(
                  focusTimer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 20,
                ),
                label: Text(focusTimer.isRunning ? "Pause" : "Resume"),
                style: FilledButton.styleFrom(
                  backgroundColor: activeColor,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector(
    BuildContext context,
    TimeBlocksViewModel viewModel,
    TaskNodeRepository nodeRepo,
    FocusTimerService focusTimer,
  ) {
    return FutureBuilder<List<TaskNode>>(
      future: viewModel.showTasks
          ? nodeRepo.getNodesByType(NodeType.task)
          : nodeRepo.getNodesByType(NodeType.project),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 72);

        final nodes = snapshot.data!.where((n) => !n.isCompleted).toList();

        return Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: nodes.length + 1, // +1 for generic untracked focus
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Generic untracked focus card
                final isGenericActive = focusTimer.activeId == "generic";
                return ActionChip(
                  avatar: Icon(
                    isGenericActive ? Icons.stop : Icons.timer_outlined,
                    color: isGenericActive ? Colors.red : Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  label: Text(isGenericActive ? "Stop Untracked" : "Quick Focus"),
                  onPressed: () {
                    if (isGenericActive) {
                      viewModel.stopFocusSession();
                    } else {
                      viewModel.startGenericSession();
                    }
                  },
                );
              }

              final node = nodes[index - 1];
              final isActive = focusTimer.activeId == node.id;

              Color nodeColor = Theme.of(context).colorScheme.primary;
              if (node.colorHex != null && node.colorHex!.isNotEmpty) {
                try {
                  nodeColor = Color(int.parse(node.colorHex!.replaceFirst('#', '0xFF')));
                } catch (_) {}
              }

              return Card(
                elevation: isActive ? 3 : 1,
                color: isActive ? nodeColor.withValues(alpha: 0.12) : Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isActive ? nodeColor : Colors.transparent,
                    width: 1.8,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    if (isActive) {
                      viewModel.toggleFocusPlayPause();
                    } else {
                      viewModel.startSessionForNode(node);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive
                              ? (focusTimer.isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled)
                              : Icons.play_circle_outline_rounded,
                          color: nodeColor,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              node.title.length > 20
                                  ? '${node.title.substring(0, 18)}...'
                                  : node.title,
                              style: TextStyle(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            if (isActive)
                              Text(
                                focusTimer.isRunning ? "Ticking • ${focusTimer.currentBlockTimeString}" : "Paused",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: nodeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else if (node.durationMinutes > 0)
                              Text(
                                "${node.durationMinutes}m",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimeWalletBanner(BuildContext context, TimeBlocksViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Time Wallet: ${viewModel.totalFilledBlocks} / 120 Blocks",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    " (${viewModel.totalFocusedMinutes ~/ 60}h ${viewModel.totalFocusedMinutes % 60}m)",
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ],
              ),
              Text(
                "${viewModel.remainingBlocks} Blocks Available (${(viewModel.remainingBlocks * 6) ~/ 60}h)",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: viewModel.completionPercentage,
              minHeight: 6,
              backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.25),
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    TimeBlocksViewModel viewModel,
    List<TaskNode> projects,
    List<TaskNode> tasks,
    int gridIndex,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final setTitles = [
      "Morning (08:00 - 11:00)",
      "Midday (11:00 - 14:00)",
      "Afternoon (14:00 - 17:00)",
      "Evening (17:00 - 20:00)",
    ];

    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                setTitles[gridIndex],
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                "3 Hours",
                style: TextStyle(fontSize: 11, color: colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 30,
            itemBuilder: (context, index) {
              final globalIndex = (gridIndex * 30) + index;
              final blockId = viewModel.blocks[globalIndex];
              final isDone = blockId.isNotEmpty;
              final isAccumulatingBlock = viewModel.activeBlockIndex == globalIndex;

              Color blockColor = colorScheme.primary;
              String tooltipLabel = "Time Block ${globalIndex + 1}";

              if (isDone && blockId != "generic") {
                try {
                  final proj = projects.firstWhere((p) => p.id == blockId);
                  tooltipLabel = proj.title;
                  if (proj.colorHex != null && proj.colorHex!.isNotEmpty) {
                    blockColor = Color(int.parse(proj.colorHex!.replaceFirst('#', '0xFF')));
                  }
                } catch (_) {
                  try {
                    final task = tasks.firstWhere((t) => t.id == blockId);
                    tooltipLabel = task.title;
                    if (task.colorHex != null && task.colorHex!.isNotEmpty) {
                      blockColor = Color(int.parse(task.colorHex!.replaceFirst('#', '0xFF')));
                    } else if (task.parentId != null) {
                      final parentProj = projects.firstWhere((p) => p.id == task.parentId);
                      if (parentProj.colorHex != null && parentProj.colorHex!.isNotEmpty) {
                        blockColor = Color(int.parse(parentProj.colorHex!.replaceFirst('#', '0xFF')));
                      }
                    }
                  } catch (_) {}
                }
              }

              return Tooltip(
                message: isDone
                    ? "$tooltipLabel (Filled)"
                    : isAccumulatingBlock
                        ? "Currently Accumulating (${(viewModel.focusTimer.currentBlockProgress * 100).toInt()}%)"
                        : "Slot #${globalIndex + 1} (Empty)",
                child: InkWell(
                  onTap: () => viewModel.toggleBlock(globalIndex),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: isDone
                          ? blockColor
                          : isAccumulatingBlock
                              ? blockColor.withValues(alpha: 0.15)
                              : colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDone
                            ? blockColor
                            : isAccumulatingBlock
                                ? blockColor
                                : colorScheme.outline.withValues(alpha: 0.25),
                        width: isAccumulatingBlock ? 2.0 : 1.0,
                      ),
                      boxShadow: isAccumulatingBlock
                          ? [
                              BoxShadow(
                                color: blockColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isDone
                          ? Icons.check
                          : isAccumulatingBlock
                              ? Icons.hourglass_top_rounded
                              : Icons.timer_outlined,
                      color: isDone
                          ? colorScheme.onPrimary
                          : isAccumulatingBlock
                              ? blockColor
                              : colorScheme.onSurface.withValues(alpha: 0.35),
                      size: 18,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridLegend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 14, color: colorScheme.outline),
        const SizedBox(width: 6),
        Text(
          "1 Block = 6 minutes • 10 Blocks = 1 Hour • 1 Set = 3 Hours • 120 Blocks = 12 Hours",
          style: TextStyle(fontSize: 11, color: colorScheme.outline),
        ),
      ],
    );
  }
}
