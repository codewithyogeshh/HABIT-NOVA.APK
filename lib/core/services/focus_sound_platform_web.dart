import 'dart:async';
import 'dart:js_interop';

@JS('synveroPlayFocusSound')
external JSBoolean _playFocusSound(JSString type, JSNumber volume);

@JS('synveroStopFocusSound')
external JSBoolean _stopFocusSound();

@JS('synveroSetFocusVolume')
external JSBoolean _setFocusVolume(JSNumber volume);

Future<bool> playWebFocusSound(String soundType, double volume) async {
  try {
    final result = _playFocusSound(soundType.toJS, volume.toJS);
    return result.toDart;
  } catch (e) {
    return false;
  }
}

Future<bool> stopWebFocusSound() async {
  try {
    final result = _stopFocusSound();
    return result.toDart;
  } catch (e) {
    return false;
  }
}

Future<bool> setWebFocusVolume(double volume) async {
  try {
    final result = _setFocusVolume(volume.toJS);
    return result.toDart;
  } catch (e) {
    return false;
  }
}

