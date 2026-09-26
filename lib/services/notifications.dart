import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 本地通知服务：为「提醒/待办」的提醒时间调度系统通知。
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    try {
      await _plugin.initialize(
        settings:
            const InitializationSettings(android: android, macOS: darwin),
      );
      // Android 13+：主动请求通知运行时权限（弹系统授权框）。
      if (Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
    } catch (_) {
      // 通知初始化失败不影响其他功能。
    }
    _ready = true;
  }

  /// 通知是否已开启（未授权返回 false，供 UI 引导）。
  Future<bool> permissionsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final impl = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await impl?.areNotificationsEnabled() ?? true;
      }
      if (Platform.isMacOS) {
        final perm = await _plugin
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>()
            ?.checkPermissions();
        return perm?.isEnabled ?? true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// 请求/打开通知权限（Android 弹系统授权框，macOS 跳转系统设置）。
  Future<void> openSettings() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return;
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.openAppNotificationSettings();
  }

  int _idFor(String extraId) => extraId.hashCode & 0x7fffffff;

  /// 调度一条通知。若 [when] 已过去，则安排到明天的同一时间。
  Future<void> schedule({
    required String extraId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await init();
    var target = when;
    final now = DateTime.now();
    if (target.isBefore(now)) {
      target = DateTime(now.year, now.month, now.day + 1, when.hour, when.minute);
    }
    await _plugin.zonedSchedule(
      id: _idFor(extraId),
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(target.toUtc(), tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          '提醒',
          channelDescription: '待办与提醒通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel(String extraId) async {
    await init();
    await _plugin.cancel(id: _idFor(extraId));
  }
}
