import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request a hardware or system permission contextually with beautiful rationale dialogs
  static Future<bool> request(
    BuildContext context, {
    required Permission permission,
    required String title,
    required String rationale,
  }) async {
    // Check if permission is already granted
    final status = await permission.status;
    if (!context.mounted) {
      return false;
    }
    if (status.isGranted) {
      return true;
    }

    // Show custom explanation dialog before triggering OS permission popup
    final bool shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(_getIconForPermission(permission), color: Colors.blueAccent),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text(
            rationale,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Continue', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;

    if (!shouldRequest) {
      return false;
    }

    // Fire the OS native permission request
    final newStatus = await permission.request();
    if (!context.mounted) {
      return false;
    }
    if (newStatus.isGranted) {
      return true;
    }

    // If permanently denied by user, explain how to enable from device settings
    if (newStatus.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Permission Disabled', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              'You have previously denied this permission. Please enable it in the system settings to use this feature.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  await openAppSettings();
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }

    return false;
  }

  static IconData _getIconForPermission(Permission permission) {
    if (permission == Permission.camera) return Icons.camera_alt_outlined;
    if (permission == Permission.notification) return Icons.notifications_none_outlined;
    if (permission == Permission.microphone) return Icons.mic_none_outlined;
    if (permission == Permission.photos) return Icons.photo_library_outlined;
    return Icons.security_outlined;
  }
}
