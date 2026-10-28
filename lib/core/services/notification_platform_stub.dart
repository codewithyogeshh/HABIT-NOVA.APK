import 'dart:async';

/// Stub implementation for native platforms (Android, iOS).
Future<String> requestDevicePermission() async {
  // On Android/iOS, device notification permission default is granted / handled via OS
  return 'granted';
}

Future<String> getDevicePermission() async {
  return 'granted';
}

Future<bool> showDeviceNotification(String title, String body) async {
  return true;
}
