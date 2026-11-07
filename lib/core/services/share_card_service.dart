import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareCardService {
  static const MethodChannel _shareChannel = MethodChannel('com.example.synvero/share');

  /// Captures any widget wrapped with [RepaintBoundary] as high-res PNG bytes
  static Future<Uint8List?> captureWidgetToPng(GlobalKey boundaryKey) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // 3.0 pixelRatio yields crisp 1080p+ Story card resolution
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('ShareCardService.captureWidgetToPng error: $e');
      return null;
    }
  }

  /// Saves PNG bytes into temporary app cache and opens the Android native Share Sheet (WhatsApp, Instagram, etc.)
  static Future<bool> shareStoryImage({
    required Uint8List pngBytes,
    required String caption,
    String title = 'Share Story to WhatsApp & Instagram',
  }) async {
    try {
      if (kIsWeb) {
        await shareText(caption, title: title);
        return true;
      }

      final tempDir = Directory.systemTemp;
      final cacheDir = Directory('${tempDir.path}/shared_images');
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }

      final file = File('${cacheDir.path}/habit_nova_story_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes, flush: true);

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _shareChannel.invokeMethod('shareImage', {
          'imagePath': file.path,
          'text': caption,
          'title': title,
        });
        return true;
      } else {
        // Fallback for text share
        await shareText(caption, title: title);
        return true;
      }
    } catch (e) {
      debugPrint('ShareCardService.shareStoryImage error: $e');
      // Graceful fallback to text share
      return await shareText(caption, title: title);
    }
  }

  /// Native text share intent
  static Future<bool> shareText(String text, {String title = 'Share Habit Progress'}) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _shareChannel.invokeMethod('shareText', {
          'text': text,
          'title': title,
        });
        return true;
      } else {
        final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return true;
        }
      }
    } catch (e) {
      debugPrint('ShareCardService.shareText error: $e');
    }
    return false;
  }
}

