import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'app/app.dart';
import 'widgets/shared/error_boundary.dart';
import 'config/env.dart';

Future<void> main() async {
  Environment.validate(); // Lock API environment target checking
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // AI V2.4: Initialize Push Notifications
    await NotificationService().init();
  } catch (e) {
    debugPrint("Firebase/Notification Init Error: $e");
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
