import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:synvero/core/services/avatar_service.dart';

/// Reusable stylish 3D profile avatar for HabbitNova users.
/// Reactively updates whenever AvatarService changes the current avatar.
class UserAvatar extends StatelessWidget {
  final double size;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    this.size = 48,
    this.avatarUrl,
    this.onTap,
    this.showBorder = true,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return _buildContainer(context, avatarUrl!);
    }

    return ValueListenableBuilder<String>(
      valueListenable: AvatarService.currentAvatarNotifier,
      builder: (context, currentPath, _) {
        return _buildContainer(context, currentPath);
      },
    );
  }

  Widget _buildContainer(BuildContext context, String path) {
    final avatarWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B66FF), Color(0xFF8B5CF6)],
            ),
            border: showBorder
                ? Border.all(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.8),
                    width: size > 40 ? 2 : 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B66FF).withValues(alpha: 0.35),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: ClipOval(
            child: _buildAvatarImage(path),
          ),
        ),
        if (showEditBadge)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: EdgeInsets.all(size * 0.06),
              decoration: BoxDecoration(
                color: const Color(0xFF3B66FF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: size * 0.26,
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: avatarWidget,
      );
    }
    return avatarWidget;
  }

  Widget _buildAvatarImage(String path) {
    if (path.startsWith('data:image/') || path.startsWith('base64:')) {
      try {
        final base64String = path.contains(',') ? path.split(',').last : path.replaceFirst('base64:', '');
        final bytes = base64Decode(base64String.trim());
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAsset(),
        );
      } catch (_) {
        return _buildFallbackAsset();
      }
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAsset(),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAsset(),
      );
    } else {
      // Local file
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAsset(),
        );
      }
      return _buildFallbackAsset();
    }
  }

  Widget _buildFallbackAsset() {
    return Image.asset(
      'assets/images/default_avatar.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF1E293B),
          child: Center(
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: size * 0.55,
            ),
          ),
        );
      },
    );
  }
}
