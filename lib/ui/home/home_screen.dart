import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/category_repository.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/services/ai/gemini_parser.dart';
import 'package:narwhal/ui/home/home_view_model.dart';
import 'package:narwhal/ui/home/components/daily_summary_widget.dart';
import 'package:narwhal/ui/home/components/quick_add_section.dart';
import 'package:narwhal/ui/home/components/expandable_task_item.dart';
import 'package:narwhal/ui/home/components/task_card.dart';
import 'package:narwhal/ui/home/components/quick_add_task_dialog.dart';
import 'package:narwhal/ui/addedit/add_edit_task_screen.dart';
import 'package:narwhal/ui/settings/settings_screen.dart';
import 'package:flutter_core_auth_hybrid/auth_repository.dart';
import 'package:narwhal/data/repository/scratchpad_repository.dart';
import 'package:narwhal/ui/scratchpad/scratchpad_screen.dart';
import 'package:narwhal/ui/scratchpad/scratchpad_detail_screen.dart';
import 'package:narwhal/services/sync_status_service.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(
        context.read<TaskNodeRepository>(),
        context.read<CategoryRepository>(),
        context.read<GeminiParser>(),
      ),
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          final width = MediaQuery.of(context).size.width;
          final isLandscape = width >= 1100;

          return Scaffold(
            appBar: isLandscape ? null : _buildMobileAppBar(context),
            body: isLandscape
                ? _buildLandscapeLayout(context, viewModel)
                : _buildPortraitLayout(context, viewModel),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showQuickAddDialog(context, viewModel),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildMobileAppBar(BuildContext context) {
    final authRepository = context.watch<AuthRepository>();
    final syncStatus = context.watch<SyncStatusService>();
    final user = authRepository.currentUser;

    return AppBar(
      title: const Text('Daily Dashboard'),
      actions: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: (user != null && user.photoURL != null) ? NetworkImage(user.photoURL!) : null,
                  child: (user == null || user.photoURL == null)
                      ? Icon(
                          user != null ? Icons.person : Icons.settings_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: syncStatus.isOnline ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- PORTRAIT LAYOUT (Mobile) ---
  Widget _buildPortraitLayout(BuildContext context, HomeViewModel viewModel) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320.0,
          floating: true,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  DailySummaryWidget(
                    totalTasks: viewModel.totalTasksCount,
                    completedTasks: viewModel.completedTasksCount,
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
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Today\'s Focus', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = viewModel.todayTasks[index];
              final project = item.task.parentId != null ? viewModel.projectsMap[item.task.parentId] : null;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ExpandableTaskItem(
                  item: item,
                  isExpanded: viewModel.expandedTaskIds.contains(item.task.id),
                  onToggleExpand: () => viewModel.onToggleExpand(item.task.id),
                  onToggleCheck: (task, isChecked) => viewModel.toggleTaskCompletion(task, isChecked),
                  projectColorHex: project?.colorHex,
                  projectTitle: project?.title,
                  onClick: () => _editTask(context, viewModel, item.task),
                ),
              );
            },
            childCount: viewModel.todayTasks.length,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Text('Triage / Inbox', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = viewModel.backlogTasks[index];
              final task = item.task;
              final project = task.parentId != null ? viewModel.projectsMap[task.parentId] : null;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Dismissible(
                  key: Key(task.id),
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.today, color: Colors.white),
                  ),
                  onDismissed: (direction) => viewModel.moveToToday(task),
                  child: TaskCard(
                    task: task,
                    onCheckedChange: (val) => viewModel.toggleTaskCompletion(task, val ?? false),
                    onClick: () => _editTask(context, viewModel, task),
                    projectColorHex: project?.colorHex,
                    projectTitle: project?.title,
                    onMoveToToday: () => viewModel.moveToToday(task),
                    onSchedule: () => _showDatePicker(context, viewModel, task),
                    subtaskCount: item.subtasks.length, // PASSED COUNT
                  ),
                ),
              );
            },
            childCount: viewModel.backlogTasks.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // --- LANDSCAPE LAYOUT (Tablet/Desktop) ---
  Widget _buildLandscapeLayout(BuildContext context, HomeViewModel viewModel) {
    return Row(
      children: [
        // Primary Workspace (Fluid)
        Expanded(
          child: Column(
            children: [
              // Global Header Card
              _buildLandscapeHeader(context, viewModel),
              // Split Workspace
              Expanded(
                child: Row(
                  children: [
                    // Column A: Today's Focus
                    Expanded(
                      child: _buildColumn(
                        context,
                        title: 'Today\'s Focus',
                        icon: Icons.star_outline,
                        count: viewModel.todayTasks.length,
                        child: DragTarget<TaskNode>(
                          onWillAcceptWithDetails: (details) => details.data.scheduledDate == null || !isSameDay(details.data.scheduledDate, viewModel.selectedDate),
                          onAcceptWithDetails: (details) {
                            viewModel.moveToToday(details.data);
                          },
                          builder: (context, candidateData, rejectedData) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: candidateData.isNotEmpty
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: viewModel.todayTasks.length,
                                itemBuilder: (context, index) {
                                  final item = viewModel.todayTasks[index];
                                  final project = item.task.parentId != null ? viewModel.projectsMap[item.task.parentId] : null;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Draggable<TaskNode>(
                                      data: item.task,
                                      feedback: SizedBox(
                                        width: 300,
                                        child: Material(
                                          elevation: 8,
                                          borderRadius: BorderRadius.circular(16),
                                          child: TaskCard(task: item.task, onCheckedChange: (_) {}, onClick: () {}),
                                        ),
                                      ),
                                      child: ExpandableTaskItem(
                                        item: item,
                                        isExpanded: viewModel.expandedTaskIds.contains(item.task.id),
                                        onToggleExpand: () => viewModel.onToggleExpand(item.task.id),
                                        onToggleCheck: (task, isChecked) => viewModel.toggleTaskCompletion(task, isChecked),
                                        projectColorHex: project?.colorHex,
                                        projectTitle: project?.title,
                                        onClick: () => _editTask(context, viewModel, item.task),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    // Column B: Triage Backlog
                    Expanded(
                      child: _buildColumn(
                        context,
                        title: 'Triage Backlog',
                        icon: Icons.inbox_outlined,
                        count: viewModel.backlogTasks.length,
                        child: DragTarget<TaskNode>(
                          onWillAcceptWithDetails: (details) => details.data.scheduledDate != null,
                          onAcceptWithDetails: (details) {
                            viewModel.moveToBacklog(details.data);
                          },
                          builder: (context, candidateData, rejectedData) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: candidateData.isNotEmpty
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: viewModel.backlogTasks.length,
                                itemBuilder: (context, index) {
                                  final item = viewModel.backlogTasks[index];
                                  final task = item.task;
                                  final project = task.parentId != null ? viewModel.projectsMap[task.parentId] : null;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Draggable<TaskNode>(
                                      data: task,
                                      feedback: SizedBox(
                                        width: 300,
                                        child: Material(
                                          elevation: 8,
                                          borderRadius: BorderRadius.circular(16),
                                          child: TaskCard(task: task, onCheckedChange: (_) {}, onClick: () {}),
                                        ),
                                      ),
                                      child: TaskCard(
                                        task: task,
                                        onCheckedChange: (val) => viewModel.toggleTaskCompletion(task, val ?? false),
                                        onClick: () => _editTask(context, viewModel, task),
                                        projectColorHex: project?.colorHex,
                                        projectTitle: project?.title,
                                        onMoveToToday: () => viewModel.moveToToday(task),
                                        onSchedule: () => _showDatePicker(context, viewModel, task),
                                        subtaskCount: item.subtasks.length, // PASSED COUNT
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Fixed Context Pane
        Container(
          width: 320,
          color: Theme.of(context).colorScheme.surface,
          child: _buildContextPane(context),
        ),
      ],
    );
  }

  Widget _buildLandscapeHeader(BuildContext context, HomeViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DailySummaryWidget(
                  totalTasks: viewModel.totalTasksCount,
                  completedTasks: viewModel.completedTasksCount,
                  totalMinutes: viewModel.totalMinutes,
                  workloadLevel: viewModel.workloadStatus,
                  motivationText: viewModel.dailyMotivation,
                  reschedulingSuggestion: viewModel.reschedulingSuggestion,
                  isAnalyzing: viewModel.isAnalyzingWorkload,
                  onAnalyzeClick: viewModel.analyzeWorkloadForRescheduling,
                  onDismissSuggestion: viewModel.dismissSuggestion,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    QuickAddSection(
                      text: viewModel.quickAddText,
                      onTextChange: viewModel.onQuickAddTextChanged,
                      onAdd: viewModel.onQuickAdd,
                      isLoading: viewModel.isLoading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(BuildContext context, {required String title, required IconData icon, required int count, required Widget child}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(count.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildContextPane(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Context', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildContextCard(context, 'Mini Calendar', Icons.calendar_month, _buildMiniCalendar(context, context.watch<HomeViewModel>())),
              const SizedBox(height: 24),
              _buildContextCard(context, 'Scratchpad', Icons.edit_note, _buildScratchpadContextCard(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScratchpadContextCard(BuildContext context) {
    return Consumer<ScratchpadRepository>(
      builder: (context, scratchRepo, _) {
        final activeNotes = scratchRepo.notes.where((n) => !n.isArchived && !n.isDeleted).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Notes (${activeNotes.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'New note',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScratchpadDetailScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Open Scratchpad',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScratchpadScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (activeNotes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    'No notes yet.\nTap + to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              )
            else
              ...activeNotes.take(3).map((note) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScratchpadDetailScreen(note: note),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title.isEmpty ? 'Untitled note' : note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        if (note.content.isNotEmpty)
                          Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        const Divider(height: 12),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildMiniCalendar(BuildContext context, HomeViewModel viewModel) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: viewModel.selectedDate,
      currentDay: DateTime.now(),
      selectedDayPredicate: (day) => isSameDay(viewModel.selectedDate, day),
      onDaySelected: (selectedDay, focusedDay) {
        viewModel.setSelectedDate(selectedDay);
      },
      calendarFormat: CalendarFormat.month,
      availableGestures: AvailableGestures.horizontalSwipe,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        leftChevronIcon: Icon(Icons.chevron_left, size: 20),
        rightChevronIcon: Icon(Icons.chevron_right, size: 20),
        titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        headerPadding: EdgeInsets.zero,
        headerMargin: EdgeInsets.only(bottom: 8),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontSize: 12),
        weekendStyle: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle: const TextStyle(fontSize: 13),
        weekendTextStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        cellMargin: const EdgeInsets.all(4),
      ),
      rowHeight: 36,
    );
  }

  Widget _buildContextCard(BuildContext context, String title, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ],
    );
  }

  void _editTask(BuildContext context, HomeViewModel viewModel, TaskNode task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: task)),
    );
    viewModel.loadData();
  }

  void _showDatePicker(BuildContext context, HomeViewModel viewModel, TaskNode task) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      viewModel.scheduleTask(task, date);
    }
  }

  void _showQuickAddDialog(BuildContext context, HomeViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => QuickAddTaskDialog(
        categories: viewModel.categories,
        onConfirm: (title, categoryId, date, priority, colorHex) {
          viewModel.quickAddTask(
            title: title,
            categoryId: categoryId,
            date: date,
            priority: priority,
            colorHex: colorHex,
          );
        },
        onEditMore: (title) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditTaskScreen(
                initialTitle: title,
              ),
            ),
          );
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }
}
