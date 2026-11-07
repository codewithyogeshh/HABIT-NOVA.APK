import 'dart:async';

/// Stub implementation for native platforms (Android, iOS).
Future<bool> playWebFocusSound(String soundType, double volume) async => true;
Future<bool> stopWebFocusSound() async => true;
Future<bool> setWebFocusVolume(double volume) async => true;

