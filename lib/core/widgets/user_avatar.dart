import 'package:flutter/material.dart';

/// Reusable stylish 3D default profile avatar for all HabbitNova users.
class UserAvatar extends StatelessWidget {
  final double size;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final bool showBorder;

  const UserAvatar({
    super.key,
    this.size = 48,
    this.avatarUrl,
    this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final avatarWidget = Container(
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
                width: 2,
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
        child: avatarUrl != null && avatarUrl!.trim().isNotEmpty
            ? Image.network(
                avatarUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
              )
            : _buildDefaultImage(),
      ),
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

  Widget _buildDefaultImage() {
    return Image.asset(
      'assets/images/default_avatar.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback modern initial badge if asset fails
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

