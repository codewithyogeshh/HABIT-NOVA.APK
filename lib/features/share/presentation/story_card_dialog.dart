import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/share_card_service.dart';

enum StoryCardTheme {
  midnightCyber,
  goldChampion,
  emeraldForest,
}

class StoryCardDialog extends StatefulWidget {
  final String username;
  final String avatar;
  final int streakDays;
  final int studyMinutes;
  final int habitsDone;
  final int habitsTotal;
  final int screenTimeSavedPercent;

  const StoryCardDialog({
    super.key,
    required this.username,
    required this.avatar,
    required this.streakDays,
    required this.studyMinutes,
    required this.habitsDone,
    required this.habitsTotal,
    this.screenTimeSavedPercent = 40,
  });

  @override
  State<StoryCardDialog> createState() => _StoryCardDialogState();
}

class _StoryCardDialogState extends State<StoryCardDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  StoryCardTheme _currentTheme = StoryCardTheme.midnightCyber;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📸 Status / Story Poster',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Theme Pickers
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildThemeChip(StoryCardTheme.midnightCyber, '🌌 Cyber Cyan'),
              const SizedBox(width: 8),
              _buildThemeChip(StoryCardTheme.goldChampion, '👑 Champion Gold'),
              const SizedBox(width: 8),
              _buildThemeChip(StoryCardTheme.emeraldForest, '🌿 Emerald Zen'),
            ],
          ),
          const SizedBox(height: 12),

          // The 9:16 Aesthetic Card preview wrapped in RepaintBoundary
          Flexible(
            child: SingleChildScrollView(
              child: RepaintBoundary(
                key: _boundaryKey,
                child: _buildAestheticCard(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Share Actions
          Row(
            children: [
              // Copy Caption
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Caption'),
                  onPressed: _copyCaption,
                ),
              ),
              const SizedBox(width: 10),

              // Share Image Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    _isSharing ? 'Generating...' : '🚀 Share to WhatsApp / Insta',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: _isSharing ? null : _handleShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeChip(StoryCardTheme theme, String label) {
    final isSelected = _currentTheme == theme;
    return InkWell(
      onTap: () => setState(() => _currentTheme = theme),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAestheticCard() {
    List<Color> gradientColors;
    Color accentColor;
    Color statBg;

    switch (_currentTheme) {
      case StoryCardTheme.goldChampion:
        gradientColors = [const Color(0xFF2E1C03), const Color(0xFF0F0A02), const Color(0xFF1F1400)];
        accentColor = const Color(0xFFFBBF24);
        statBg = const Color(0xFF3D2A08);
        break;
      case StoryCardTheme.emeraldForest:
        gradientColors = [const Color(0xFF022C22), const Color(0xFF061E16), const Color(0xFF021711)];
        accentColor = const Color(0xFF34D399);
        statBg = const Color(0xFF0B3B2F);
        break;
      case StoryCardTheme.midnightCyber:
        gradientColors = [const Color(0xFF0B192C), const Color(0xFF030712), const Color(0xFF1E1B4B)];
        accentColor = const Color(0xFF38BDF8);
        statBg = const Color(0xFF1E293B);
        break;
    }

    return Container(
      width: 320,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Brand Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.spa_rounded, color: accentColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'HABIT-NOVA',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. User Avatar & Name
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: statBg,
              child: Text(
                widget.avatar.isNotEmpty ? widget.avatar : '👑',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '⚡ Focus Warrior • Level ${(widget.streakDays / 3).floor() + 1}',
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Hero Achievement: Streak Flame
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: statBg.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  '🔥 UNBROKEN STREAK',
                  style: TextStyle(
                    color: Color(0xFFF97316), // Orange flame
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.streakDays} DAYS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Consistency is victory.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Three Stat Chips
          Row(
            children: [
              Expanded(
                child: _buildMiniStatChip(
                  icon: Icons.timer_rounded,
                  label: 'Focus Study',
                  value: '${widget.studyMinutes}m',
                  color: const Color(0xFF10B981),
                  bgColor: statBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStatChip(
                  icon: Icons.check_circle_rounded,
                  label: 'Habits Done',
                  value: '${widget.habitsDone}/${widget.habitsTotal}',
                  color: accentColor,
                  bgColor: statBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: statBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 16),
                const SizedBox(width: 6),
                Text(
                  '🛡️ Screen Time Cut by ${widget.screenTimeSavedPercent}% Today',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 5. Aesthetic Quote
          const Text(
            '"Discipline today builds the freedom of tomorrow."',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // 6. Bottom Watermark & CTA for Play Store
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.android_rounded, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Join my streak on Habit-Nova',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _copyCaption() {
    final caption = '''🔥 *Day ${widget.streakDays} of Habit & Focus Mastery on Habit-Nova!* 🔥

⏱️ Focus Study Today: ${widget.studyMinutes} Mins
🎯 Habits Crushed: ${widget.habitsDone}/${widget.habitsTotal}
🛡️ Screen Time Reduced by ${widget.screenTimeSavedPercent}%!

कष्ट आज, यश उद्या! 💪
माझ्यासोबत हॅबिट्स आणि फोकस ट्रॅक करण्यासाठी Habit-Nova डाउनलोड करा:
📲 https://github.com/codewithyogeshh/HABIT-NOVA.APK''';

    Clipboard.setData(ClipboardData(text: caption));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Caption copied to clipboard! Paste it on WhatsApp/Insta!'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);
    try {
      final pngBytes = await ShareCardService.captureWidgetToPng(_boundaryKey);
      if (pngBytes == null) {
        throw Exception('Failed to render poster image.');
      }

      final caption = '''🔥 Day ${widget.streakDays} Streak on Habit-Nova!
⏱️ Focus: ${widget.studyMinutes}m | 🎯 Habits: ${widget.habitsDone}/${widget.habitsTotal}
Download Habit-Nova to conquer your goals:
https://github.com/codewithyogeshh/HABIT-NOVA.APK''';

      await ShareCardService.shareStoryImage(
        pngBytes: pngBytes,
        caption: caption,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
}

