import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:intl/intl.dart';

class HomeWidgetSyncService {
  static final HomeWidgetSyncService instance = HomeWidgetSyncService._internal();
  HomeWidgetSyncService._internal();

  /// Syncs the current tasks into Android Home Screen Widgets.
  Future<void> syncTodayTasks({
    required List<TaskNode> tasks,
    Map<String, TaskNode>? projectsMap,
  }) async {
    // Only run on Android native platform
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      // Filter tasks scheduled for today
      final todayTasks = tasks.where((t) {
        if (t.nodeType != NodeType.task) return false;
        if (t.scheduledDate == null) return false;
        return (t.scheduledDate!.isAfter(todayStart.subtract(const Duration(milliseconds: 1))) &&
                t.scheduledDate!.isBefore(todayEnd.add(const Duration(milliseconds: 1))));
      }).toList();

      final totalTasks = todayTasks.length;
      final completedTasks = todayTasks.where((t) => t.isCompleted).length;
      final pendingTasks = (totalTasks - completedTasks).clamp(0, totalTasks);
      final totalMinutes = todayTasks.fold<int>(0, (sum, t) => sum + t.durationMinutes);

      // Calculate Workload Level
      String workload;
      if (totalMinutes > 240) {
        workload = 'CASUALTY';
      } else if (totalMinutes < 60) {
        workload = 'RECOVERY';
      } else {
        workload = 'GRIND';
      }

      // Serialize tasks to JSON
      final tasksJsonList = todayTasks.map((t) {
        final parentId = t.parentId;
        final project = (parentId != null && projectsMap != null) ? projectsMap[parentId] : null;
        return {
          'id': t.id,
          'title': t.title,
          'isCompleted': t.isCompleted,
          'priority': t.priority,
          'durationMinutes': t.durationMinutes,
          'projectTitle': project?.title ?? '',
          'projectColorHex': project?.colorHex ?? t.colorHex ?? '',
        };
      }).toList();

      // Find all upcoming future events/deadlines for the Hour Counter Widget
      final upcomingEvents = <Map<String, dynamic>>[];
      final calendarTaskDays = <String>{};

      for (final t in tasks) {
        if (t.nodeType != NodeType.task) continue;

        // Collect scheduled dates for the Calendar Widget
        final d = t.scheduledDate ?? t.startDateTime ?? t.deadline;
        if (d != null && !t.isCompleted) {
          calendarTaskDays.add(DateFormat('yyyy-MM-dd').format(d));
        }

        if (t.isCompleted) continue;

        final targetTime = _extractEventTargetTime(t, now);
        if (targetTime == null) continue;

        final parentId = t.parentId;
        final project = (parentId != null && projectsMap != null) ? projectsMap[parentId] : null;

        String category = 'EVENT';
        if (t.isZone) {
          category = 'EVENT';
        } else if (t.deadline != null || t.categoryId == 'Strategy') {
          category = 'DEADLINE';
        } else if (project != null && project.title.isNotEmpty) {
          category = project.title.toUpperCase();
        } else if (t.categoryId.isNotEmpty && t.categoryId != 'General') {
          category = t.categoryId.toUpperCase();
        }

        upcomingEvents.add({
          'id': t.id,
          'title': t.title.isEmpty ? 'Untitled Event' : t.title,
          'timestamp': targetTime.millisecondsSinceEpoch,
          'dateFormatted': _formatEventDate(targetTime, now),
          'category': category,
          'isZone': t.isZone,
          'priority': t.priority,
          'colorHex': project?.colorHex ?? t.colorHex ?? '',
        });
      }

      // Sort upcoming events chronologically (closest first)
      upcomingEvents.sort((a, b) {
        final cmp = (a['timestamp'] as int).compareTo(b['timestamp'] as int);
        if (cmp != 0) return cmp;
        final aIsZone = a['isZone'] == true ? 1 : 0;
        final bIsZone = b['isZone'] == true ? 1 : 0;
        if (aIsZone != bIsZone) return bIsZone.compareTo(aIsZone);
        return (b['priority'] as int).compareTo(a['priority'] as int);
      });

      final agendaSummary = totalTasks > 0
          ? '$completedTasks/$totalTasks completed • ${totalMinutes ~/ 60}h ${totalMinutes % 60}m focus'
          : 'No tasks scheduled today';

      // Save key-value pairs in Android SharedPreferences via home_widget
      final saveFutures = <Future>[
        HomeWidget.saveWidgetData<int>('today_total_tasks', totalTasks),
        HomeWidget.saveWidgetData<int>('today_completed_tasks', completedTasks),
        HomeWidget.saveWidgetData<int>('today_pending_tasks', pendingTasks),
        HomeWidget.saveWidgetData<int>('today_total_minutes', totalMinutes),
        HomeWidget.saveWidgetData<String>('today_workload', workload),
        HomeWidget.saveWidgetData<String>('today_tasks_json', jsonEncode(tasksJsonList)),
        HomeWidget.saveWidgetData<String>('calendar_task_days', calendarTaskDays.join(',')),
        HomeWidget.saveWidgetData<String>('calendar_agenda_summary', agendaSummary),
      ];

      if (upcomingEvents.isNotEmpty) {
        final primary = upcomingEvents.first;
        saveFutures.addAll([
          HomeWidget.saveWidgetData<bool>('countdown_has_event', true),
          HomeWidget.saveWidgetData<String>('countdown_event_id', primary['id']),
          HomeWidget.saveWidgetData<String>('countdown_event_title', primary['title']),
          HomeWidget.saveWidgetData<int>('countdown_event_timestamp', primary['timestamp']),
          HomeWidget.saveWidgetData<String>('countdown_event_timestamp_str', primary['timestamp'].toString()),
          HomeWidget.saveWidgetData<String>('countdown_event_date_formatted', primary['dateFormatted']),
          HomeWidget.saveWidgetData<String>('countdown_event_category', primary['category']),
          HomeWidget.saveWidgetData<String>('countdown_event_color', primary['colorHex']),
          HomeWidget.saveWidgetData<int>('countdown_upcoming_count', upcomingEvents.length),
          HomeWidget.saveWidgetData<String>('countdown_events_json', jsonEncode(upcomingEvents)),
        ]);
      } else {
        saveFutures.addAll([
          HomeWidget.saveWidgetData<bool>('countdown_has_event', false),
          HomeWidget.saveWidgetData<String>('countdown_event_id', ''),
          HomeWidget.saveWidgetData<String>('countdown_event_title', ''),
          HomeWidget.saveWidgetData<int>('countdown_event_timestamp', 0),
          HomeWidget.saveWidgetData<String>('countdown_event_timestamp_str', '0'),
          HomeWidget.saveWidgetData<String>('countdown_event_date_formatted', ''),
          HomeWidget.saveWidgetData<String>('countdown_event_category', ''),
          HomeWidget.saveWidgetData<String>('countdown_event_color', ''),
          HomeWidget.saveWidgetData<int>('countdown_upcoming_count', 0),
          HomeWidget.saveWidgetData<String>('countdown_events_json', '[]'),
        ]);
      }

      await Future.wait(saveFutures);

      // Trigger update for each widget provider
      await Future.wait([
        HomeWidget.updateWidget(
          name: 'TodayTasksWidgetProvider',
          androidName: 'widget.TodayTasksWidgetProvider',
        ),
        HomeWidget.updateWidget(
          name: 'DailySummaryWidgetProvider',
          androidName: 'widget.DailySummaryWidgetProvider',
        ),
        HomeWidget.updateWidget(
          name: 'QuickActionsWidgetProvider',
          androidName: 'widget.QuickActionsWidgetProvider',
        ),
        HomeWidget.updateWidget(
          name: 'EventCountdownWidgetProvider',
          androidName: 'widget.EventCountdownWidgetProvider',
        ),
        HomeWidget.updateWidget(
          name: 'CalendarWidgetProvider',
          androidName: 'widget.CalendarWidgetProvider',
        ),
      ]);
    } catch (e) {
      debugPrint('Error syncing data to Home Screen Widgets: $e');
    }
  }

  DateTime? _extractEventTargetTime(TaskNode t, DateTime now) {
    if (t.startDateTime != null && t.startDateTime!.isAfter(now)) {
      return t.startDateTime;
    }
    if (t.deadline != null && t.deadline!.isAfter(now)) {
      return t.deadline;
    }
    if (t.scheduledDate != null) {
      if (t.scheduledDate!.isAfter(now)) {
        return t.scheduledDate;
      }
      final isToday = t.scheduledDate!.year == now.year &&
          t.scheduledDate!.month == now.month &&
          t.scheduledDate!.day == now.day;
      if (isToday) {
        final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
        if (endOfDay.isAfter(now)) {
          return endOfDay;
        }
      }
    }
    return null;
  }

  String _formatEventDate(DateTime dt, DateTime now) {
    final nowStart = DateTime(now.year, now.month, now.day);
    final targetStart = DateTime(dt.year, dt.month, dt.day);
    final diffDays = targetStart.difference(nowStart).inDays;
    final timeStr = DateFormat('h:mm a').format(dt);

    if (diffDays == 0) {
      return 'Today • $timeStr';
    } else if (diffDays == 1) {
      return 'Tomorrow • $timeStr';
    } else if (diffDays > 1 && diffDays < 7) {
      return '${DateFormat('EEEE').format(dt)} • $timeStr';
    } else {
      return '${DateFormat('MMM d').format(dt)} • $timeStr';
    }
  }

  /// Clears widget data upon sign-out
  Future<void> clearWidgetData() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await Future.wait([
        HomeWidget.saveWidgetData<int>('today_total_tasks', 0),
        HomeWidget.saveWidgetData<int>('today_completed_tasks', 0),
        HomeWidget.saveWidgetData<int>('today_pending_tasks', 0),
        HomeWidget.saveWidgetData<int>('today_total_minutes', 0),
        HomeWidget.saveWidgetData<String>('today_workload', 'RECOVERY'),
        HomeWidget.saveWidgetData<String>('today_tasks_json', '[]'),
        HomeWidget.saveWidgetData<String>('calendar_task_days', ''),
        HomeWidget.saveWidgetData<String>('calendar_agenda_summary', ''),
        HomeWidget.saveWidgetData<int>('calendar_month_offset', 0),
        HomeWidget.saveWidgetData<bool>('countdown_has_event', false),
        HomeWidget.saveWidgetData<String>('countdown_event_id', ''),
        HomeWidget.saveWidgetData<String>('countdown_event_title', ''),
        HomeWidget.saveWidgetData<int>('countdown_event_timestamp', 0),
        HomeWidget.saveWidgetData<String>('countdown_event_timestamp_str', '0'),
        HomeWidget.saveWidgetData<String>('countdown_event_date_formatted', ''),
        HomeWidget.saveWidgetData<String>('countdown_event_category', ''),
        HomeWidget.saveWidgetData<String>('countdown_event_color', ''),
        HomeWidget.saveWidgetData<int>('countdown_upcoming_count', 0),
        HomeWidget.saveWidgetData<String>('countdown_events_json', '[]'),
      ]);

      await Future.wait([
        HomeWidget.updateWidget(
          name: 'TodayTasksWidgetProvider',
          androidName: 'widget.TodayTasksWidgetProvider',
        ),
        HomeWidget.updateWidget(
          name: 'DailySummaryWidgetProvider',
          androidName: 'widget.DailySummaryWidgetProvider',
        ),
        HomeWidget.updateWidget(
          name: 'QuickActionsWidgetProvider',
          androidName: 'widget.QuickActionsWidgetProvider',
        ),
        HomeWidget.updateWidget(
          name: 'EventCountdownWidgetProvider',
          androidName: 'widget.EventCountdownWidgetProvider',
        ),
        HomeWidget.updateWidget(
          name: 'CalendarWidgetProvider',
          androidName: 'widget.CalendarWidgetProvider',
        ),
      ]);
    } catch (e) {
      debugPrint('Error clearing widget data: $e');
    }
  }
}
