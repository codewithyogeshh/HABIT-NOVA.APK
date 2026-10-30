import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synvero/core/services/gamification_service.dart';
import 'package:synvero/core/widgets/user_avatar.dart';

/// Modal dialog showing the 9:16 aesthetic Bioluminescent Zen Story Card
/// ready for one-tap sharing to Instagram, WhatsApp Status, and Telegram.
class ShareStoryCardDialog extends StatelessWidget {
  final String username;
  final int streakDays;
  final int habitsCompleted;
  final int totalHabits;
  final int totalXP;
  final String quoteText;
  final String quoteAuthor;

  const ShareStoryCardDialog({
    super.key,
    required this.username,
    required this.streakDays,
    required this.habitsCompleted,
    required this.totalHabits,
    required this.totalXP,
    required this.quoteText,
    required this.quoteAuthor,
  });

  static const MethodChannel _shareChannel = MethodChannel('com.example.synvero/share');

  static Future<void> show(
    BuildContext context, {
    required String username,
    required int streakDays,
    required int habitsCompleted,
    required int totalHabits,
    required int totalXP,
    required String quoteText,
    required String quoteAuthor,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ShareStoryCardDialog(
        username: username,
        streakDays: streakDays,
        habitsCompleted: habitsCompleted,
        totalHabits: totalHabits,
        totalXP: totalXP,
        quoteText: quoteText,
        quoteAuthor: quoteAuthor,
      ),
    );
  }

  Future<void> _shareText(BuildContext context) async {
    final levelInfo = GamificationService.getLevelInfo(totalXP);
    final text = '''
🌟 HABBITNOVA DAILY PROGRESS 🌟
👤 $username
🔥 Streak: $streakDays Days Unbroken!
⚡ Level ${levelInfo.level}: ${levelInfo.title} ($totalXP XP)
✅ Today's Habits: $habitsCompleted/$totalHabits Completed!

💬 "$quoteText"
— $quoteAuthor

🚀 Built with HabbitNova • Small Steps, Gigantic Changes!
    '''.trim();

    try {
      await _shareChannel.invokeMethod('shareText', {
        'text': text,
        'title': 'Share My HabbitNova Progress',
      });
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story copied to clipboard!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelInfo = GamificationService.getLevelInfo(totalXP);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The Visual Story Card (9:16 feel)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF030814), Color(0xFF071728), Color(0xFF0E3D48)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF00F0FF), width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Brand Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/icon/app_icon_clean.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.eco_rounded, color: Color(0xFF00F0FF), size: 22),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'HabbitNova',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'DAILY MASTERY',
                        style: TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Avatar & Name
                Row(
                  children: [
                    const UserAvatar(size: 52, showBorder: true),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Level ${levelInfo.level} • ${levelInfo.title}',
                            style: TextStyle(
                              color: levelInfo.levelColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050E1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0E3D48)),
                        ),
                        child: Column(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(
                              '$streakDays Days',
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Unbroken Streak',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050E1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0E3D48)),
                        ),
                        child: Column(
                          children: [
                            const Text('⚡', style: TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(
                              '$totalXP XP',
                              style: const TextStyle(
                                color: Color(0xFF00F0FF),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Discipline Power',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Quote
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF030814).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0E3D48)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '"$quoteText"',
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '— $quoteAuthor',
                        style: const TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Watermark footer
                const Text(
                  'Small Steps • Gigantic Changes',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF64748B)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(color: Colors.white70)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: const Color(0xFF030814),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () => _shareText(context),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share to Story', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
