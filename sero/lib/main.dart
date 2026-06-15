import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'app/app.dart';
import 'widgets/shared/error_boundary.dart';
import 'package:sero/config/dev_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kUseMockData) {
    try {
      await Firebase.initializeApp(
        // options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // AI V2.4: Initialize Push Notifications
      await NotificationService().init();
    } catch (e) {
      debugPrint("Firebase/Notification Init Error: $e");
    }
  } else {
    debugPrint("🚀 Running in UI Preview Mode (Mock Data Enabled)");
  }

  // AI V3.1: Global Error Handling
  runApp(
    GlobalErrorBoundary(
      child: const ProviderScope(
        child: SocietyApp(),
      ),
    ),
  );
}
