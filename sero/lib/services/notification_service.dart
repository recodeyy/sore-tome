import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../app/app.dart' show appNavigatorKey, SocietyApp;
import 'auth_service.dart';

/// Keep in sync with pubspec.yaml `version:`.
const String kAppVersion = '1.0.0+8';

/// Top-level background handler. MUST be a top-level (or static) function and
/// annotated with @pragma('vm:entry-point') so the Flutter engine can invoke
/// it from a background isolate after AOT tree-shaking.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The background isolate has no Firebase app instance yet.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized or unavailable — nothing further to do. For
    // notification-type messages Android renders the system notification
    // itself; we only need this hook alive for data-only messages.
  }
  debugPrint('BG message: ${message.messageId} data=${message.data}');
}

/// Canonical push-notification service (MR-008).
///
/// Responsibilities:
///  * Permission request + local-notifications init (called once from main).
///  * Android notification channels per category (visitors / billing /
///    notices / SOS / general) with correct importance.
///  * Device-token registration with the backend (multi-device endpoint with
///    legacy PATCH /users/me fallback) + automatic re-registration on token
///    refresh.
///  * Deep-link handling for taps in all three app states (foreground local
///    notification, background tap, cold start).
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  static NotificationService get instance => _instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Channels ───────────────────────────────────────────────────────────────
  static const _channels = <AndroidNotificationChannel>[
    AndroidNotificationChannel(
      'sero_visitors',
      'Visitors & Gate',
      description: 'Visitor arrivals, approvals and gate passes',
      importance: Importance.max,
    ),
    AndroidNotificationChannel(
      'sero_billing',
      'Bills & Payments',
      description: 'Invoices, dues reminders and payment receipts',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'sero_notices',
      'Notices & Community',
      description: 'Society notices, events and polls',
      importance: Importance.high,
    ),
    // NOTE: flutter_local_notifications 18.x has no bypassDnd channel flag;
    // Importance.max is the strongest available. DND bypass would need a
    // plugin upgrade or platform channel (deferred).
    AndroidNotificationChannel(
      'sero_sos',
      'Emergency SOS',
      description: 'Emergency and SOS alerts',
      importance: Importance.max,
    ),
    AndroidNotificationChannel(
      'sero_general',
      'General',
      description: 'General society updates',
      importance: Importance.defaultImportance,
    ),
  ];

  /// data['category'] → channel id. Unknown/missing → sero_general.
  static String _channelIdFor(String? category) {
    switch (category) {
      case 'visitor':
      case 'visitors':
      case 'gate':
      case 'parcel':
        return 'sero_visitors';
      case 'billing':
      case 'bill':
      case 'payment':
      case 'invoice':
        return 'sero_billing';
      case 'notice':
      case 'notices':
      case 'event':
      case 'poll':
      case 'community':
        return 'sero_notices';
      case 'sos':
      case 'emergency':
        return 'sero_sos';
      default:
        return 'sero_general';
    }
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Permissions (Android 13+, iOS, web).
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Local notifications + tap handler (foreground-shown notifications).
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        _handleDeeplinkPayload(details.payload);
      },
    );

    // 3. Create Android channels.
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      for (final channel in _channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    // 4. Foreground messages → local notification on the right channel.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        showLocalNotification(
          title: notification.title ?? 'SERO',
          body: notification.body ?? '',
          category: message.data['category'] as String?,
          deeplink: message.data['deeplink'] as String?,
          dedupKey: message.messageId,
        );
      }
    });

    // 5. Tap on system notification while app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleDeeplinkPayload(message.data['deeplink'] as String?);
    });

    // 6. Cold start: app launched from a notification tap.
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Defer until the first frame so the Navigator exists.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDeeplinkPayload(initialMessage.data['deeplink'] as String?);
      });
    }

    // 7. Token refresh → re-register with backend.
    _fcm.onTokenRefresh.listen((token) {
      registerDeviceToken(token: token);
    });
  }

  // ── Token registration ─────────────────────────────────────────────────────
  /// Registers the current (or provided) FCM token with the backend.
  ///
  /// Primary contract: POST /notifications/devices {token, platform,
  /// appVersion}. Fallback (legacy): PATCH /users/me {fcmToken}. Backend
  /// accepts both. Never throws — push registration must not break login.
  Future<void> registerDeviceToken({String? token}) async {
    try {
      final fcmToken = token ?? await _fcm.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final loggedIn = await AuthService.isLoggedIn();
      if (!loggedIn) return;

      final response = await http.post(
        Uri.parse('$kBaseUrl/notifications/devices'),
        headers: await AuthService.authHeaders(),
        body: jsonEncode({
          'token': fcmToken,
          'platform': _platformName(),
          'appVersion': kAppVersion,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
            'Device-token registration failed (${response.statusCode}), '
            'falling back to PATCH /users/me');
        await AuthService.updateFcmToken(fcmToken);
      }
    } catch (e) {
      debugPrint('registerDeviceToken error: $e');
      // Last-ditch legacy fallback.
      try {
        final fcmToken = token ?? await _fcm.getToken();
        if (fcmToken != null) await AuthService.updateFcmToken(fcmToken);
      } catch (e2) {
        debugPrint('Legacy fcmToken fallback failed: $e2');
      }
    }
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isAndroid) return 'android';
    } catch (_) {}
    return 'android';
  }

  // ── Local notification display ─────────────────────────────────────────────
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? category,
    String? deeplink,
    String? dedupKey,
  }) async {
    final channelId = _channelIdFor(category);
    final channel = _channels.firstWhere((c) => c.id == channelId);

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: channel.importance == Importance.max
          ? Priority.max
          : Priority.high,
    );

    // Stable id derived from the message so redelivery dedupes instead of
    // stacking duplicates.
    final id = (dedupKey ?? '$title|$body|$deeplink').hashCode & 0x7FFFFFFF;

    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
      payload: deeplink,
    );
  }

  // ── Deep links ─────────────────────────────────────────────────────────────
  /// Navigates to [deeplink] if it is a registered named route.
  /// Unknown/empty links are ignored silently (crash-safe by design).
  void _handleDeeplinkPayload(String? deeplink) {
    if (deeplink == null || deeplink.isEmpty) return;
    final route = deeplink.trim();
    if (!SocietyApp.routes.containsKey(route)) {
      debugPrint('Ignoring unregistered deeplink: $route');
      return;
    }
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    try {
      navigator.pushNamed(route);
    } catch (e) {
      debugPrint('Deeplink navigation failed for $route: $e');
    }
  }

  // ── Topics ─────────────────────────────────────────────────────────────────
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }
}
