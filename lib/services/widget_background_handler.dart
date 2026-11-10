import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

/// Headless background entry point invoked when user interacts with widget items
/// (e.g. toggles a task checkbox from the Android Home Screen widget).
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri == null) return;
  WidgetsFlutterBinding.ensureInitialized();

  // Handle task completion toggle: planner://toggle?id=<taskId> or narwhal://toggle?id=<taskId>
  if ((uri.scheme == 'planner' || uri.scheme == 'narwhal') && (uri.host == 'toggle' || uri.queryParameters.containsKey('id'))) {
    final taskId = uri.queryParameters['id'];
    if (taskId == null || taskId.isEmpty) return;

    try {
      // 1. Immediately update local widget JSON cache in SharedPreferences
      final tasksJsonStr = await HomeWidget.getWidgetData<String>('today_tasks_json', defaultValue: '[]');
      if (tasksJsonStr != null && tasksJsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(tasksJsonStr);
        bool found = false;
        bool newCompletedStatus = false;

        for (var item in list) {
          if (item is Map && item['id'] == taskId) {
            newCompletedStatus = !(item['isCompleted'] == true);
            item['isCompleted'] = newCompletedStatus;
            found = true;
            break;
          }
        }

        if (found) {
          final totalTasks = list.length;
          final completedTasks = list.where((t) => t is Map && t['isCompleted'] == true).length;
          final pendingTasks = (totalTasks - completedTasks).clamp(0, totalTasks);

          await Future.wait([
            HomeWidget.saveWidgetData<String>('today_tasks_json', jsonEncode(list)),
            HomeWidget.saveWidgetData<int>('today_completed_tasks', completedTasks),
            HomeWidget.saveWidgetData<int>('today_pending_tasks', pendingTasks),
          ]);

          // Notify widgets to refresh immediately
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

          // 2. Persist update to Firestore
          try {
            await Firebase.initializeApp();
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('task_nodes')
                  .doc(taskId)
                  .update({
                'isCompleted': newCompletedStatus,
                'completedDate': newCompletedStatus ? DateTime.now().millisecondsSinceEpoch : null,
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              });
            }
          } catch (e) {
            debugPrint("Widget background Firestore sync error: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Error handling widget background callback: $e");
    }
  }
}
