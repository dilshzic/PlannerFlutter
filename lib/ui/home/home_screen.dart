import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:planner/data/repository/task_repository.dart';
import 'package:planner/logic/gemini_parser.dart';
import 'package:planner/ui/home/home_view_model.dart';
import 'package:planner/ui/home/components/daily_summary_widget.dart';
import 'package:planner/ui/home/components/quick_add_section.dart';
import 'package:planner/ui/home/components/expandable_task_item.dart';
import 'package:planner/ui/addedit/add_edit_task_screen.dart';
import 'package:planner/ui/settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("HomeScreen build started");
    try {
      final repo = context.read<TaskRepository>();
      debugPrint("TaskRepository found: $repo");
    } catch (e) {
      debugPrint("TaskRepository NOT FOUND: $e");
    }
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(
        context.read<TaskRepository>(),
        context.read<GeminiParser>(),
      ),
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Planner'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  DailySummaryWidget(
                    totalTasks: viewModel.totalTasks,
                    completedTasks: viewModel.completedTasks,
                    totalMinutes: viewModel.totalMinutes,
                    workloadLevel: viewModel.workloadStatus,
                    motivationText: viewModel.dailyMotivation,
                    reschedulingSuggestion: viewModel.reschedulingSuggestion,
                    isAnalyzing: viewModel.isAnalyzingWorkload,
                    onAnalyzeClick: viewModel.analyzeWorkloadForRescheduling,
                    onDismissSuggestion: viewModel.dismissSuggestion,
                  ),
                  QuickAddSection(
                    text: viewModel.quickAddText,
                    onTextChange: viewModel.onQuickAddTextChanged,
                    onAdd: viewModel.onQuickAdd,
                    isLoading: viewModel.isLoading,
                  ),
                  if (viewModel.tasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No tasks for today. Enjoy!', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: viewModel.tasks.length,
                      itemBuilder: (context, index) {
                        final item = viewModel.tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ExpandableTaskItem(
                            item: item,
                            isExpanded: viewModel.expandedTaskIds.contains(item.task.id),
                            onToggleExpand: () => viewModel.onToggleExpand(item.task.id),
                            onToggleCheck: (task, isChecked) => viewModel.toggleTaskCompletion(task, isChecked),
                            onClick: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: item.task)),
                              );
                              viewModel.loadTasks();
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEditTaskScreen()),
                );
                viewModel.loadTasks();
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
