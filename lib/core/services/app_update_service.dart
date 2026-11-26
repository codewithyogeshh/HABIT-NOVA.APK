import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/config/app_update_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Describes a newer build published for the app.
@immutable
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuild,
    required this.currentVersion,
    required this.currentBuild,
    required this.minSupportedBuild,
    required this.apkUrl,
    this.notes = const <String>[],
  });

  final String latestVersion;
  final int latestBuild;
  final String currentVersion;
  final int currentBuild;

  /// Builds older than this must update before the app keeps working.
  final int minSupportedBuild;
  final String apkUrl;
  final List<String> notes;

  bool get isMandatory => currentBuild < minSupportedBuild;

  /// Returns null when the manifest is unusable, so a typo never bricks startup.
  static AppUpdateInfo? fromManifest(
    Map<String, dynamic> json, {
    required int currentBuild,
    required String currentVersion,
  }) {
    final Object? rawUrl = json['apk_url'];
    final Object? rawBuild = json['latest_build'];
    if (rawUrl is! String || rawUrl.trim().isEmpty) return null;
    if (rawBuild is! num) return null;

    final Uri? parsed = Uri.tryParse(rawUrl.trim());
    if (parsed == null || !parsed.hasScheme) return null;

    final List<String> notes = <String>[];
    final Object? rawNotes = json['notes'];
    if (rawNotes is List) {
      for (final Object? note in rawNotes) {
        if (note is String && note.trim().isNotEmpty) notes.add(note.trim());
      }
    }

    return AppUpdateInfo(
      latestVersion: (json['latest_version'] as String?)?.trim() ?? '$rawBuild',
      latestBuild: rawBuild.toInt(),
      currentVersion: currentVersion,
      currentBuild: currentBuild,
      minSupportedBuild: (json['min_supported_build'] as num?)?.toInt() ?? 0,
      apkUrl: parsed.toString(),
      notes: notes,
    );
  }
}

/// Checks a hosted manifest for a newer build and exposes it to the UI.
///
/// Fails silently: no network, a bad manifest or an unsupported platform must
/// never block the app from starting.
class AppUpdateService {
  AppUpdateService._();

  /// The pending update, if any. `AppUpdateOverlay` listens to this.
  static final ValueNotifier<AppUpdateInfo?> availableUpdate =
      ValueNotifier<AppUpdateInfo?>(null);

  static bool _checking = false;

  /// The in-app update flow installs APK files, so it is Android-only.
  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Fetch the manifest and publish a newer build to [availableUpdate].
  ///
  /// [force] skips the throttle/snooze window (used by "check again" actions).
  static Future<void> checkForUpdate({bool force = false}) async {
    if (!isSupportedPlatform || _checking) return;
    _checking = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int now = DateTime.now().millisecondsSinceEpoch;

      final int snoozedUntil = prefs.getInt(AppUpdateConfig.snoozeKey) ?? 0;
      if (!force && now < snoozedUntil) return;

      final int lastCheck = prefs.getInt(AppUpdateConfig.lastCheckKey) ?? 0;
      if (!force &&
          now - lastCheck < AppUpdateConfig.checkInterval.inMilliseconds) {
        return;
      }

      final http.Response response = await http
          .get(
            Uri.parse(AppUpdateConfig.manifestUrl),
            headers: const <String, String>{'Cache-Control': 'no-cache'},
          )
          .timeout(AppUpdateConfig.requestTimeout);

      await prefs.setInt(AppUpdateConfig.lastCheckKey, now);
      if (response.statusCode != 200) return;

      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final int currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        decoded,
        currentBuild: currentBuild,
        currentVersion: packageInfo.version,
      );
      if (info == null) return;

      if (info.latestBuild <= currentBuild) {
        availableUpdate.value = null;
        return;
      }
      availableUpdate.value = info;
    } catch (e) {
      debugPrint('AppUpdateService.checkForUpdate skipped: $e');
    } finally {
      _checking = false;
    }
  }

  /// Hide the prompt for [AppUpdateConfig.snoozeDuration].
  static Future<void> snooze() async {
    availableUpdate.value = null;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        AppUpdateConfig.snoozeKey,
        DateTime.now()
            .add(AppUpdateConfig.snoozeDuration)
            .millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// Open the download page for the new APK in the device browser.
  static Future<bool> openDownload(AppUpdateInfo info) async {
    try {
      return await launchUrl(
        Uri.parse(info.apkUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('AppUpdateService.openDownload failed: $e');
      return false;
    }
  }
}
