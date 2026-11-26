import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/app_update_service.dart';

/// A tiny fake HTTP stack so `AppUpdateService.checkForUpdate` can be tested
/// without touching the network. Only the pieces `package:http`'s IOClient
/// actually reads are implemented; everything else falls through noSuchMethod.
class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({this.body = '{}', this.statusCode = 200, this.failure});

  final String body;
  final int statusCode;
  final Object? failure;
  int requestCount = 0;
  Uri? lastRequestedUrl;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    requestCount++;
    lastRequestedUrl = url;
    if (failure != null) throw failure!;
    return _FakeHttpClientRequest(body, statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this.body, this.statusCode);

  final String body;
  final int statusCode;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  // `Stream.pipe` pumps the request body into the request, then closes it.
  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse(body, statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse(this.body, this.statusCode);

  final String body;

  @override
  final int statusCode;

  @override
  int get contentLength => body.length;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  List<Cookie> get cookies => const <Cookie>[];

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(Uint8List.fromList(utf8.encode(body))).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpOverrides extends HttpOverrides {
  _FakeHttpOverrides(this.client);

  final HttpClient client;

  @override
  HttpClient createHttpClient(SecurityContext? context) => client;
}

/// A valid manifest, matching the shape of `version.json` in the repo root.
Map<String, dynamic> _manifest({
  Object? latestVersion = '1.1.0',
  Object? latestBuild = 2,
  Object? minSupportedBuild = 1,
  Object? apkUrl = 'https://example.com/app.apk',
  Object? notes,
}) {
  return <String, dynamic>{
    'latest_version': ?latestVersion,
    'latest_build': ?latestBuild,
    'min_supported_build': ?minSupportedBuild,
    'apk_url': ?apkUrl,
    'notes': ?notes,
    'released_at': '2026-11-25',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdateInfo.fromManifest', () {
    test('parses a complete manifest', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(notes: <Object>['Faster sync', 'New theme']),
        currentBuild: 1,
        currentVersion: '1.0.0',
      );

      expect(info, isNotNull);
      expect(info!.latestVersion, '1.1.0');
      expect(info.latestBuild, 2);
      expect(info.minSupportedBuild, 1);
      expect(info.apkUrl, 'https://example.com/app.apk');
      expect(info.notes, <String>['Faster sync', 'New theme']);
      expect(info.currentBuild, 1);
      expect(info.currentVersion, '1.0.0');
    });

    test('returns null when apk_url is missing', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(apkUrl: null),
        currentBuild: 1,
        currentVersion: '1.0.0',
      );

      expect(info, isNull);
    });

    test('returns null when apk_url is blank', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(apkUrl: '   '),
        currentBuild: 1,
        currentVersion: '1.0.0',
      );

      expect(info, isNull);
    });

    test('returns null when apk_url is not an absolute uri', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(apkUrl: 'app.apk'),
        currentBuild: 1,
        currentVersion: '1.0.0',
      );

      expect(info, isNull);
    });

    test('returns null when latest_build is missing', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(latestBuild: null),
        currentBuild: 1,
        currentVersion: '1.0.0',
      );

      expect(info, isNull);
    });

    test('returns null when latest_build is not a number', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(latestBuild: '2'),
        currentBuild: 1,
        currentVersion: '1.0.0',
      );

      expect(info, isNull);
    });

    test('accepts latest_build as a decimal number', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(latestBuild: 3.0),
        currentBuild: 1,
        currentVersion: '1.0.0',
      );

      expect(info, isNotNull);
      expect(info!.latestBuild, 3);
    });

    test('defaults min_supported_build to zero when absent', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(minSupportedBuild: null),
        currentBuild: 1,
        currentVersion: '1.0.0',
      );

      expect(info, isNotNull);
      expect(info!.minSupportedBuild, 0);
      expect(info.isMandatory, isFalse);
    });

    test('falls back to the build number when latest_version is absent', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(latestVersion: null),
        currentBuild: 1,
        currentVersion: '1.0.0',
      );

      expect(info, isNotNull);
      expect(info!.latestVersion, '2');
    });

    test('keeps only usable release notes', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(notes: <Object>['Good note', 7, '  ', '  Spaced  ']),
        currentBuild: 1,
        currentVersion: '1.0.0',
      );

      expect(info!.notes, <String>['Good note', 'Spaced']);
    });

    test('an empty notes list stays empty', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(notes: <Object>[]),
        currentBuild: 1,
        currentVersion: '1.0.0',
      );

      expect(info!.notes, isEmpty);
    });
  });

  group('AppUpdateInfo.isMandatory', () {
    test('is false when the installed build meets min_supported_build', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(latestBuild: 5, minSupportedBuild: 2),
        currentBuild: 2,
        currentVersion: '1.0.0',
      );

      expect(info, isNotNull);
      expect(info!.isMandatory, isFalse);
    });

    test('is true when the installed build is below min_supported_build', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(latestBuild: 5, minSupportedBuild: 3),
        currentBuild: 2,
        currentVersion: '1.0.0',
      );

      expect(info, isNotNull);
      expect(info!.isMandatory, isTrue);
    });

    test('is mandatory when min_supported_build equals the latest build', () {
      final AppUpdateInfo? info = AppUpdateInfo.fromManifest(
        _manifest(latestBuild: 4, minSupportedBuild: 4),
        currentBuild: 1,
        currentVersion: '1.0.0',
      );

      expect(info!.isMandatory, isTrue);
    });
  });

  group('AppUpdateService.checkForUpdate', () {
    late _FakeHttpClient client;

    setUp(() {
      // Pretend we are running on Android: update flow is Android-only.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      SharedPreferences.setMockInitialValues(<String, Object>{});
      AppUpdateService.availableUpdate.value = null;
      PackageInfo.setMockInitialValues(
        appName: 'HabitNova',
        packageName: 'com.example.synvero',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      HttpOverrides.global = null;
      AppUpdateService.availableUpdate.value = null;
    });

    void serve(Map<String, dynamic> manifest, {int statusCode = 200}) {
      client = _FakeHttpClient(body: jsonEncode(manifest), statusCode: statusCode);
      HttpOverrides.global = _FakeHttpOverrides(client);
    }

    void installVersion(String version, String buildNumber) {
      PackageInfo.setMockInitialValues(
        appName: 'HabitNova',
        packageName: 'com.example.synvero',
        version: version,
        buildNumber: buildNumber,
        buildSignature: '',
      );
    }

    test('offers an update when the published build is newer', () async {
      serve(_manifest(latestVersion: '1.1.0', latestBuild: 2));

      await AppUpdateService.checkForUpdate(force: true);

      final AppUpdateInfo? info = AppUpdateService.availableUpdate.value;
      expect(info, isNotNull);
      expect(info!.latestBuild, 2);
      expect(info.currentBuild, 1);
      expect(info.latestVersion, '1.1.0');
      expect(info.isMandatory, isFalse);
      expect(client.requestCount, 1);
      expect(client.lastRequestedUrl?.host, 'raw.githubusercontent.com');
    });

    test('does not offer anything when the installed build is the same', () async {
      installVersion('1.1.0', '2');
      serve(_manifest(latestVersion: '1.1.0', latestBuild: 2));

      await AppUpdateService.checkForUpdate(force: true);

      expect(AppUpdateService.availableUpdate.value, isNull);
    });

    test('does not offer anything when the installed build is newer', () async {
      installVersion('1.2.0', '4');
      serve(_manifest(latestVersion: '1.1.0', latestBuild: 3));

      await AppUpdateService.checkForUpdate(force: true);

      expect(AppUpdateService.availableUpdate.value, isNull);
    });

    test('offers an update when only the build number is newer', () async {
      installVersion('1.0.0', '1');
      serve(_manifest(latestVersion: '1.0.0', latestBuild: 2));

      await AppUpdateService.checkForUpdate(force: true);

      expect(AppUpdateService.availableUpdate.value?.latestBuild, 2);
    });

    test('marks the popup as mandatory when min_supported_build is higher',
        () async {
      installVersion('1.0.0', '1');
      serve(_manifest(latestVersion: '1.1.0', latestBuild: 2, minSupportedBuild: 2));

      await AppUpdateService.checkForUpdate(force: true);

      final AppUpdateInfo? info = AppUpdateService.availableUpdate.value;
      expect(info, isNotNull);
      expect(info!.isMandatory, isTrue);
    });

    test('is not mandatory when min_supported_build is already installed',
        () async {
      installVersion('1.0.5', '2');
      serve(_manifest(latestVersion: '1.1.0', latestBuild: 3, minSupportedBuild: 2));

      await AppUpdateService.checkForUpdate(force: true);

      final AppUpdateInfo? info = AppUpdateService.availableUpdate.value;
      expect(info, isNotNull);
      expect(info!.isMandatory, isFalse);
    });

    test('ignores a manifest without apk_url', () async {
      serve(_manifest(apkUrl: null));

      await AppUpdateService.checkForUpdate(force: true);

      expect(AppUpdateService.availableUpdate.value, isNull);
    });

    test('ignores a manifest without latest_build', () async {
      serve(_manifest(latestBuild: null));

      await AppUpdateService.checkForUpdate(force: true);

      expect(AppUpdateService.availableUpdate.value, isNull);
    });

    test('ignores a non-object manifest body', () async {
      client = _FakeHttpClient(body: '["not", "a", "manifest"]');
      HttpOverrides.global = _FakeHttpOverrides(client);

      await AppUpdateService.checkForUpdate(force: true);

      expect(AppUpdateService.availableUpdate.value, isNull);
    });

    test('ignores malformed json', () async {
      client = _FakeHttpClient(body: '{oops');
      HttpOverrides.global = _FakeHttpOverrides(client);

      await AppUpdateService.checkForUpdate(force: true);

      expect(AppUpdateService.availableUpdate.value, isNull);
    });

    test('ignores an error http status', () async {
      serve(_manifest(), statusCode: 500);

      await AppUpdateService.checkForUpdate(force: true);

      expect(AppUpdateService.availableUpdate.value, isNull);
    });

    test('survives a network failure', () async {
      client = _FakeHttpClient(failure: const SocketException('offline'));
      HttpOverrides.global = _FakeHttpOverrides(client);

      await AppUpdateService.checkForUpdate(force: true);

      expect(AppUpdateService.availableUpdate.value, isNull);
    });

    test('snooze hides the pending update', () async {
      serve(_manifest(latestVersion: '1.1.0', latestBuild: 2));
      await AppUpdateService.checkForUpdate(force: true);
      expect(AppUpdateService.availableUpdate.value, isNotNull);

      await AppUpdateService.snooze();

      expect(AppUpdateService.availableUpdate.value, isNull);
    });

    test('is skipped when the platform is not Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      serve(_manifest(latestVersion: '1.1.0', latestBuild: 2));

      await AppUpdateService.checkForUpdate(force: true);

      expect(AppUpdateService.availableUpdate.value, isNull);
      expect(client.requestCount, 0);
    });
  });
}
