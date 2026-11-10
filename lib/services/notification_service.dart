import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_core_entities/task_node.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  final taskId = notificationResponse.payload;
  if (taskId == null || taskId.isEmpty) return;

  try {
    await Firebase.initializeApp();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('task_nodes')
        .doc(taskId);

    if (notificationResponse.actionId == 'mark_done') {
      await docRef.update({
        'isCompleted': true,
        'completedDate': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } else if (notificationResponse.actionId == 'snooze') {
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final task = TaskNode.fromMap(doc.data()!);
        final snoozedDate = DateTime.now().add(const Duration(minutes: 15));
        final updatedTask = task.copyWith(
          scheduledDate: snoozedDate,
          reminderOffsetMinutes: 0,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await docRef.update({
          'scheduledDate': snoozedDate.millisecondsSinceEpoch,
          'reminderOffsetMinutes': 0,
          'updatedAt': updatedTask.updatedAt,
        });
        await NotificationService().scheduleTaskNotification(updatedTask);
      }
    }
  } catch (e) {
    debugPrint("Background notification response error: $e");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // For iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // For Linux
    final LinuxInitializationSettings linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
      defaultIcon: AssetsLinuxIcon('icons/app_icon.png'),
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    
    _isInitialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    // Could navigate to a specific task using response.payload
  }

  Future<void> scheduleTaskNotification(TaskNode task) async {
    if (task.scheduledDate == null) return;
    
    // Create deterministic ID from task ID for reliable cancellation
    final int notificationId = task.id.hashCode;
    
    tz.TZDateTime scheduledDate = tz.TZDateTime.from(task.scheduledDate!, tz.local);
    
    if (task.reminderOffsetMinutes != null && task.reminderOffsetMinutes! > 0) {
      scheduledDate = scheduledDate.subtract(Duration(minutes: task.reminderOffsetMinutes!));
    }
    
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      // Don't schedule for the past
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'planner_tasks_channel',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming scheduled tasks',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_done',
          'Mark as Done',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'snooze',
          'Snooze (15m)',
          showsUserInterface: false,
        ),
      ],
    );
    
    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.critical,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: notificationId,
      title: 'Task Reminder: ${task.title}',
      body: task.description.isNotEmpty ? task.description : 'It is time to start this task.',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: task.id,
      matchDateTimeComponents: task.recurrenceRule != null ? DateTimeComponents.dayOfWeekAndTime : null, // E.g., basic repeating support
    );
  }

  Future<void> showTimeBlockNotification(int minutes) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'planner_time_blocks_channel',
      'Time Blocks',
      channelDescription: 'Notifications for time block tracking',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    
    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
    );

    await _notificationsPlugin.show(
      id: 'time_block'.hashCode,
      title: 'Time Block Completed',
      body: 'Tracked $minutes minutes for your active session',
      notificationDetails: notificationDetails,
    );
  }

  Future<void> cancelTaskNotification(String taskId) async {
    final int notificationId = taskId.hashCode;
    await _notificationsPlugin.cancel(id: notificationId);
  }
}
