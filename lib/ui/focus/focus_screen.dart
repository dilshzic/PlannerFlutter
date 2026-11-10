import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/time_block_repository.dart';
import 'package:narwhal/services/focus_timer_service.dart';

class FocusScreen extends StatefulWidget {
  final TaskNode? task;

  const FocusScreen({super.key, this.task});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusTimer = context.read<FocusTimerService>();
      if (widget.task != null && focusTimer.activeId != widget.task!.id) {
        focusTimer.startSession(
          id: widget.task!.id,
          title: widget.task!.title,
          task: widget.task,
          colorHex: widget.task!.colorHex,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final focusTimer = context.watch<FocusTimerService>();
    final tbRepo = context.watch<TimeBlockRepository>();
    final colorScheme = Theme.of(context).colorScheme;

    final activeTask = widget.task ?? focusTimer.activeTask;
    final title = activeTask?.title ?? focusTimer.activeTitle;
    final colorHex = activeTask?.colorHex ?? focusTimer.activeColorHex;

    Color themeColor = colorScheme.primary;
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        themeColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Minimize (Timer keeps running)',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Add +1 Time Block',
            onPressed: () async {
              await focusTimer.addManualBlockFor(
                id: focusTimer.activeId ?? "generic",
                task: activeTask,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added 1 time block! (6m)')),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: focusTimer.isRunning
                          ? themeColor.withValues(alpha: 0.15)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: focusTimer.isRunning
                            ? themeColor
                            : colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          focusTimer.isRunning ? Icons.fiber_manual_record : Icons.pause,
                          size: 12,
                          color: focusTimer.isRunning ? themeColor : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          focusTimer.isRunning ? "FOCUS SESSION ACTIVE" : "SESSION PAUSED",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: focusTimer.isRunning ? themeColor : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title.isNotEmpty ? title : "Deep Focus",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (activeTask != null && activeTask.durationMinutes > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Target: ${activeTask.durationMinutes}m • Priority ${activeTask.priority}",
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),

              // Large Circular Timer
              Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 16,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                      CircularProgressIndicator(
                        value: focusTimer.currentBlockProgress,
                        strokeWidth: 16,
                        color: themeColor,
                        strokeCap: StrokeCap.round,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${(focusTimer.currentBlockProgress * 100).toInt()}%",
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: themeColor,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            "OF CURRENT BLOCK (6 MIN)",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${focusTimer.remainingBlockTimeString} remaining",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Total: ${focusTimer.totalSessionTimeString}",
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Session Metrics Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMetricCard(
                    context,
                    label: "Blocks Earned",
                    value: "🔥 ${focusTimer.sessionBlocksEarned}",
                  ),
                  const SizedBox(width: 16),
                  _buildMetricCard(
                    context,
                    label: "Focus Time",
                    value: "⏱️ ${focusTimer.sessionBlocksEarned * 6}m",
                  ),
                  const SizedBox(width: 16),
                  _buildMetricCard(
                    context,
                    label: "Today's Wallet",
                    value: "📊 ${tbRepo.totalFilledBlocks} / 120",
                  ),
                ],
              ),

              // Mini Visual Time Block Wallet Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Progress",
                        style: TextStyle(fontSize: 12, color: colorScheme.outline),
                      ),
                      Text(
                        "${tbRepo.totalFilledBlocks} / 120 Blocks (${tbRepo.totalFocusedMinutes ~/ 60}h ${tbRepo.totalFocusedMinutes % 60}m)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (tbRepo.totalFilledBlocks / 120.0).clamp(0.0, 1.0),
                      minHeight: 8,
                      color: themeColor,
                      backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),

              // Action Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    iconSize: 28,
                    onPressed: () async {
                      await focusTimer.stopSession();
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.stop_rounded, color: Colors.red),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  FloatingActionButton.large(
                    heroTag: 'focus_play_pause',
                    onPressed: focusTimer.togglePlayPause,
                    backgroundColor: themeColor,
                    child: Icon(
                      focusTimer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  IconButton.filledTonal(
                    iconSize: 28,
                    onPressed: () async {
                      await focusTimer.finishTask();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task completed and session finished!')),
                        );
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.check_rounded, color: Colors.green),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {required String label, required String value}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
