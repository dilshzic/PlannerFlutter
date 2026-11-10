import 'package:flutter/material.dart';
import 'package:narwhal/ui/home/home_screen.dart';
import 'package:narwhal/ui/calendar/calendar_screen.dart';
import 'package:narwhal/ui/project/project_screen.dart';
import 'package:narwhal/ui/scratchpad/scratchpad_screen.dart';
import 'package:narwhal/ui/time_blocks/time_blocks_screen.dart';
import 'package:narwhal/ui/ai/ai_screen.dart';
import 'package:narwhal/ui/insights/insights_screen.dart';
import 'package:narwhal/ui/components/narwhal_icon.dart';
import 'package:flutter_core_auth_hybrid/auth_repository.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/ui/addedit/add_edit_task_screen.dart';
import 'package:narwhal/ui/settings/settings_screen.dart';
import 'package:narwhal/services/sync_status_service.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initHomeWidgetListener();
  }

  void _initHomeWidgetListener() {
    if (kIsWeb || !Platform.isAndroid) return;

    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        _handleWidgetUri(uri);
      }
    });

    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) {
        _handleWidgetUri(uri);
      }
    });
  }

  void _handleWidgetUri(Uri uri) async {
    // 1. Quick Add Task
    if (uri.path.contains('quick_add') || uri.host.contains('quick_add')) {
      setState(() => _selectedIndex = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
        );
      });
      return;
    }

    // 2. Open Scratchpad
    if (uri.path.contains('scratchpad') || uri.host.contains('scratchpad')) {
      setState(() => _selectedIndex = 3);
      return;
    }

    // 3. Open Focus Mode / Time Blocks
    if (uri.path.contains('focus') || uri.host.contains('focus')) {
      setState(() => _selectedIndex = 4);
      return;
    }

    // 4. Open specific task
    if (uri.path.contains('task/open') || uri.queryParameters.containsKey('id')) {
      final taskId = uri.queryParameters['id'];
      if (taskId != null) {
        final repo = context.read<TaskNodeRepository>();
        var task = await repo.getNodeById(taskId);
        if (task == null) {
          // If nodes haven't loaded yet on cold start, wait briefly for initial load
          for (int i = 0; i < 10 && task == null; i++) {
            await Future.delayed(const Duration(milliseconds: 200));
            if (!mounted) return;
            task = await repo.getNodeById(taskId);
          }
        }
        if (task != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)),
          );
        }
      }
      return;
    }

    // 5. Open Calendar
    if (uri.path.contains('calendar') || uri.host.contains('calendar')) {
      setState(() => _selectedIndex = 2);
      return;
    }

    // 6. Open Dashboard
    if (uri.path.contains('dashboard') || uri.host.contains('dashboard')) {
      setState(() => _selectedIndex = 0);
      return;
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const ProjectScreen(),
    const CalendarScreen(),
    const ScratchpadScreen(),
    const TimeBlocksScreen(),
    const AiScreen(),
    const InsightsScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: 'Projects',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Strategy',
    ),
    NavigationDestination(
      icon: Icon(Icons.edit_note_outlined),
      selectedIcon: Icon(Icons.edit_note),
      label: 'Scratchpad',
    ),
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view),
      label: 'Time Blocks',
    ),
    NavigationDestination(
      icon: NarwhalIcon(size: 24, opacity: 0.75),
      selectedIcon: NarwhalIcon(size: 24, isSelected: true),
      label: 'Narwhal',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: 'Insights',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 600;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.selected,
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        label: Text(d.label),
                      ))
                  .toList(),
              trailing: Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildProfileIcon(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          if (isWide) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: _destinations,
            ),
    );
  }
  Widget _buildProfileIcon(BuildContext context) {
    final authRepository = context.watch<AuthRepository>();
    final syncStatus = context.watch<SyncStatusService>();
    final user = authRepository.currentUser;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 18,
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
    );
  }
}
