import 'package:flutter/material.dart';

/// Bioluminescent AI Daily Morning Coach Briefing card for the Home Dashboard.
class AICoachCard extends StatelessWidget {
  final String username;
  final int streakDays;
  final int habitsCompletedToday;
  final int totalHabits;
  final VoidCallback onChatTapped;

  const AICoachCard({
    super.key,
    required this.username,
    required this.streakDays,
    required this.habitsCompletedToday,
    required this.totalHabits,
    required this.onChatTapped,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _coachMessage {
    if (habitsCompletedToday == totalHabits && totalHabits > 0) {
      return 'Phenomenal job! You crushed all your habits today. Keep your momentum soaring!';
    }
    if (streakDays >= 7) {
      return 'You are on an elite $streakDays-day streak! Tackle your 25-min study timer next to secure today.';
    }
    if (habitsCompletedToday > 0) {
      return 'Solid start, $username! Complete your remaining habits to keep your streak alive today.';
    }
    return 'Small daily disciplines create extraordinary achievements. Start with your easiest habit right now!';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kCardBg = isDark ? const Color(0xFF071728) : Colors.white;
    final kTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00F0FF).withValues(alpha: isDark ? 0.12 : 0.08),
            kCardBg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00F0FF), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$_greeting, $username ☀️',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onChatTapped,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ask AI',
                        style: TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF00F0FF)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _coachMessage,
            style: TextStyle(
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
