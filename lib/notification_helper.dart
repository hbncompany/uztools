import 'package:shared_preferences/shared_preferences.dart';

class NotificationHelper {
  static Future<int> getNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final starredCodes =
        prefs.getStringList('starred_tax_codes')?.toSet() ?? {};
    int count = 0;
    for (var code in starredCodes) {
      if (prefs.containsKey('notification_$code')) {
        count++;
      }
    }
    return count;
  }
}
