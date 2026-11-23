import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wraps flutter_local_notifications. Instantiated both in the app isolate and
/// inside the WorkManager background isolate (no shared state needed).
class NotificationHelper {
  NotificationHelper([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'meal_reminders';
  static const channelName = 'Meal reminders';
  static const _icon = 'ic_notification';

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> init({void Function(String? payload)? onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
      onDidReceiveNotificationResponse: onTap == null
          ? null
          : (response) => onTap(response.payload),
    );
  }

  /// Payload the app was launched with (cold start from a notification).
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  Future<bool> areEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.areNotificationsEnabled() ?? true;
  }

  /// Returns true when the user granted (or no permission is required).
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> showMealReminder({
    required int id,
    required String mealId,
    required String mealName,
    required String body,
  }) => _plugin.show(
    id: id,
    title: 'Time to cook: $mealName',
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Reminders for meals you planned',
        importance: Importance.high,
        priority: Priority.high,
        icon: _icon,
      ),
    ),
    payload: '/meal/$mealId',
  );
}
