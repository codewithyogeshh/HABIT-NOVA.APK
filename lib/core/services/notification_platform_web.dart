import 'dart:async';
import 'dart:js_interop';

@JS('synveroRequestNotificationPermission')
external JSPromise<JSString> _requestPermission();

@JS('synveroGetNotificationPermission')
external JSString _getPermission();

@JS('synveroShowNotification')
external JSBoolean _showNotification(JSString title, JSString body);

Future<String> requestDevicePermission() async {
  try {
    final result = await _requestPermission().toDart;
    return result.toDart;
  } catch (_) {
    return 'denied';
  }
}

Future<String> getDevicePermission() async {
  try {
    final result = _getPermission();
    return result.toDart;
  } catch (_) {
    return 'default';
  }
}

Future<bool> showDeviceNotification(String title, String body) async {
  try {
    final result = _showNotification(title.toJS, body.toJS);
    return result.toDart;
  } catch (_) {
    return false;
  }
}
