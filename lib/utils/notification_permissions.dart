import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uztools/localization.dart';

class NotificationPermissions {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<bool> requestNotificationPermission(
      BuildContext context) async {
    bool isGranted = false;

    // Android 13+ permission
        {
      final status = await Permission.notification.request();
      isGranted = status.isGranted;

      if (status.isPermanentlyDenied) {
        // Show a dialog to guide the user to settings
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                  Localization.translate("notification_permission_denied")),
              content:
              Text(Localization.translate("enable_notifications_settings")),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(Localization.translate("cancel")),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings(); // Open app settings
                  },
                  child: Text(Localization.translate("open_settings")),
                ),
              ],
            ),
          );
        }
      } else if (!isGranted && context.mounted) {
        // Show a snackbar for temporary denial
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                Localization.translate("notification_permission_required")),
          ),
        );
      }
    }

    return isGranted;
  }

  static Future<bool> checkNotificationPermission() async {
    {
      return await Permission.notification.isGranted;
    }
    return false;
  }
}
