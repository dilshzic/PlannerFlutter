import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:narwhal/services/home_widget_sync_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'dailyBriefing') {
      await _sendDailyBriefing();
    }
    return Future.value(true);
  });
}

Future<void> _sendDailyBriefing() async {
  try {
    await Firebase.initializeApp();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).millisecondsSinceEpoch;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('task_nodes')
        .where('isCompleted', isEqualTo: false)
        .get();

    final allTasks = snapshot.docs.map((e) => TaskNode.fromMap(e.data())).toList();
    final todayTasks = allTasks.where((t) {
      if (t.nodeType != NodeType.task || t.scheduledDate == null) return false;
      final ms = t.scheduledDate!.millisecondsSinceEpoch;
      return ms >= startOfDay && ms <= endOfDay;
    }).toList();

    if (todayTasks.isEmpty) return;

    final highPriority = todayTasks.where((t) => t.priority >= 2).length;
    
    String body = 'You have ${todayTasks.length} tasks scheduled for today.';
    if (highPriority > 0) {
      body += ' $highPriority of them are high priority.';
    }

    final plugin = FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_briefings_channel',
      'Daily Briefings',
      channelDescription: 'Morning summary of your tasks',
      importance: Importance.low,
      priority: Priority.low,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      linux: LinuxNotificationDetails(),
    );

    await plugin.show(
      id: 'daily_briefing'.hashCode,
      title: 'Good Morning! ☀️',
      body: body,
      notificationDetails: details,
    );

    // Refresh home screen widgets for the new day
    try {
      await HomeWidgetSyncService.instance.syncTodayTasks(tasks: allTasks);
    } catch (e) {
      // Non-critical background failure
    }
  } catch (e) {
    debugPrint("Daily briefing error: $e");
  }
}

class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      _initialized = true;
      _scheduleDailyBriefing();
    } catch (e) {
      debugPrint("Workmanager initialization error: $e");
    }
  }

  void _scheduleDailyBriefing() {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 8, 0, 0); // 8:00 AM
    if (now.isAfter(target)) {
      target = target.add(const Duration(days: 1));
    }
    final initialDelay = target.difference(now);

    Workmanager().registerPeriodicTask(
      'daily_briefing_task',
      'dailyBriefing',
      frequency: const Duration(hours: 24),
      initialDelay: initialDelay,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}
