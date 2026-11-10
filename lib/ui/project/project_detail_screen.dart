import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/ui/project/project_detail_view_model.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/data/repository/scratchpad_repository.dart';
import 'package:narwhal/ui/project/add_edit_project_screen.dart';
import 'package:narwhal/services/ai/project_agent_service.dart';
import 'package:narwhal/ui/project/project_agent_view_model.dart';
import 'package:narwhal/ui/project/components/project_agent_panel.dart';
import 'package:narwhal/ui/components/narwhal_icon.dart';

import 'package:narwhal/ui/project/components/project_sliver_app_bar.dart';
import 'package:narwhal/ui/project/components/project_overview_panel.dart';
import 'package:narwhal/ui/project/components/project_task_sliver_list.dart';
import 'package:narwhal/ui/project/components/project_notes_sheet.dart';
import 'package:narwhal/ui/project/components/project_dialogs.dart';

class ProjectDetailScreen extends StatefulWidget {
  final TaskNode project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _showAiAgent = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectDetailViewModel(
        context.read<TaskNodeRepository>(),
        context.read<ScratchpadRepository>(),
        widget.project,
      ),
      child: Consumer<ProjectDetailViewModel>(
        builder: (context, viewModel, child) {
          final width = MediaQuery.of(context).size.width;
          final isLandscape = width >= 900;

          return Scaffold(
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : isLandscape
                    ? _buildLandscapeLayout(context, viewModel)
                    : _buildPortraitLayout(context, viewModel),
            floatingActionButton: FloatingActionButton(
              onPressed: () => ProjectDialogs.showAddTaskDialog(context, viewModel),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, ProjectDetailViewModel viewModel) {
    return CustomScrollView(
      slivers: [
        ProjectSliverAppBar(
          viewModel: viewModel,
          onEditProject: () => _editProject(viewModel),
          onShowAiAgent: () => ProjectDialogs.showAiAgentBottomSheet(context, viewModel),
          onShowNotes: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (context) => ProjectNotesSheet(viewModel: viewModel),
            );
          },
          onDeleteProject: () => ProjectDialogs.showDeleteConfirm(context, viewModel),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: ProjectTaskSliverList(
            viewModel: viewModel,
            taskNodeRepository: context.read<TaskNodeRepository>(),
            isLandscape: false,
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, ProjectDetailViewModel viewModel) {
    return Row(
      children: [
        // Main Task Area
        Expanded(
          flex: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(viewModel.project.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: NarwhalIcon(
                    size: 22,
                    color: _showAiAgent ? Theme.of(context).colorScheme.primary : null,
                  ),
                  tooltip: 'Narwhal Project Copilot',
                  onPressed: () {
                    setState(() {
                      _showAiAgent = !_showAiAgent;
                    });
                  },
                ),
              ],
            ),
            body: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: ProjectTaskSliverList(
                    viewModel: viewModel,
                    taskNodeRepository: context.read<TaskNodeRepository>(),
                    isLandscape: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // AI Panel (Side Panel)
        if (_showAiAgent) ...[
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: ChangeNotifierProvider(
              create: (context) => ProjectAgentViewModel(
                context.read<TaskNodeRepository>(),
                context.read<ProjectAgentService>(),
                viewModel.project,
              ),
              child: ProjectAgentPanel(
                onClose: () {
                  setState(() {
                    _showAiAgent = false;
                  });
                },
              ),
            ),
          ),
          const VerticalDivider(width: 1),
        ],
        // Project Context & Notes Pane
        ProjectOverviewPanel(
          viewModel: viewModel,
          onEditProject: () => _editProject(viewModel),
        ),
      ],
    );
  }

  void _editProject(ProjectDetailViewModel viewModel) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddEditProjectScreen(project: viewModel.project)),
    );
    if (deleted == true && mounted) {
      Navigator.pop(context);
    }
  }
}
