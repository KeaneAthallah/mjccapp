import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wraps [FlutterLocalNotificationsPlugin] so SOS/emergency notifications
/// (sound, vibration, high importance, dedicated emergency channel) can be
/// shown from anywhere in the app — including when it is in the background or
/// the screen is locked (as Android permits).
///
/// Local notifications are used as the immediate high-visibility layer while
/// Firebase Cloud Messaging delivers the server->device push for remote cases.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static final Int64List _emergencyVibration =
      Int64List.fromList([0, 500, 200, 500, 200, 1000]);
  static final Int64List _systemVibration =
      Int64List.fromList([0, 300, 150, 300]);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Must be called once from `main()` before the app runs.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: androidInit, iOS: ios);
    await _plugin.initialize(settings);

    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'emergency_sos',
            'SOS Darurat',
            description:
                'Notifikasi darurat SOS berprioritas tinggi dengan suara & getar',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'default',
            'Informasi MJCC',
            description: 'Notifikasi umum aplikasi MJCC',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
  }

  /// Shows a highly noticeable emergency notification for an SOS.
  Future<void> showEmergencySos({
    required int id,
    required String categoryLabel,
    required String title,
    required String body,
  }) async {
    final android = AndroidNotificationDetails(
      'emergency_sos',
      'SOS Darurat',
      channelDescription:
          'Notifikasi darurat SOS berprioritas tinggi dengan suara & getar',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: _emergencyVibration,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      showWhen: true,
    );
    final details = NotificationDetails(android: android);
    await _plugin.show(
      id,
      '🚨 $categoryLabel',
      body,
      details,
      payload: 'sos:$categoryLabel:$id',
    );
  }

  /// Shows a normal system/informational notification.
  Future<void> showSystem({
    required int id,
    required String title,
    required String body,
  }) async {
    final android = AndroidNotificationDetails(
      'default',
      'Informasi MJCC',
      channelDescription: 'Notifikasi umum aplikasi MJCC',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: _systemVibration,
    );
    final details = NotificationDetails(android: android);
    await _plugin.show(id, title, body, details, payload: 'general:$id');
  }

  /// Requests the runtime POST_NOTIFICATIONS permission (Android 13+).
  Future<bool> requestNotificationsPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  /// Whether local-notification runtime permission has been granted.
  Future<bool> areNotificationsEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.areNotificationsEnabled() ?? true;
  }
}
