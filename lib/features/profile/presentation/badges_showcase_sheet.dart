import 'package:flutter/material.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/gamification_service.dart';

/// Modal bottom sheet showcasing all trophies, levels, and achievement badges.
class BadgesShowcaseSheet extends StatefulWidget {
  final int currentXP;
  final int streakDays;

  const BadgesShowcaseSheet({
    super.key,
    required this.currentXP,
    required this.streakDays,
  });

  static Future<void> show(BuildContext context, {required int currentXP, required int streakDays}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BadgesShowcaseSheet(currentXP: currentXP, streakDays: streakDays),
    );
  }

  @override
  State<BadgesShowcaseSheet> createState() => _BadgesShowcaseSheetState();
}

class _BadgesShowcaseSheetState extends State<BadgesShowcaseSheet> {
  Set<String> _unlockedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnlockedBadges();
  }

  Future<void> _loadUnlockedBadges() async {
    final unlocked = await GamificationService.getUnlockedBadgeIds();
    if (mounted) {
      setState(() {
        _unlockedIds = unlocked;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelInfo = GamificationService.getLevelInfo(widget.currentXP);
    final kCardBg = isDark ? const Color(0xFF071728) : Colors.white;
    final kBorderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
    final kTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final kSubtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF030814) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: kPrimaryColor.withValues(alpha: 0.4), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: kSubtextColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🏆', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trophies & Badges',
                          style: TextStyle(
                            color: kTextColor,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '${_unlockedIds.length} of ${GamificationService.allBadges.length} Unlocked',
                          style: const TextStyle(
                            color: kPrimaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: kSubtextColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Level Hero Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    levelInfo.levelColor.withValues(alpha: 0.2),
                    kCardBg,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: levelInfo.levelColor.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: levelInfo.levelColor.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: levelInfo.levelColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: levelInfo.levelColor, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(levelInfo.badgeEmoji, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Level ${levelInfo.level}',
                                  style: TextStyle(
                                    color: levelInfo.levelColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: levelInfo.levelColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    levelInfo.title,
                                    style: TextStyle(
                                      color: levelInfo.levelColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.currentXP} Total XP Earned',
                              style: TextStyle(color: kSubtextColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: levelInfo.progress,
                      minHeight: 8,
                      backgroundColor: isDark ? const Color(0xFF030814) : const Color(0xFFE2E8F0),
                      color: levelInfo.levelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.currentXP} XP',
                        style: TextStyle(color: kSubtextColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Next: ${levelInfo.nextLevelXP} XP (Lvl ${levelInfo.level + 1})',
                        style: TextStyle(color: levelInfo.levelColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Badges Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.88,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: GamificationService.allBadges.length,
                    itemBuilder: (context, index) {
                      final badge = GamificationService.allBadges[index];
                      final isUnlocked = _unlockedIds.contains(badge.id);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUnlocked ? kCardBg : (isDark ? const Color(0xFF050E1A) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isUnlocked ? badge.glowColor.withValues(alpha: 0.6) : kBorderColor.withValues(alpha: 0.4),
                            width: isUnlocked ? 1.5 : 1,
                          ),
                          boxShadow: isUnlocked
                              ? [
                                  BoxShadow(
                                    color: badge.glowColor.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isUnlocked
                                        ? badge.glowColor.withValues(alpha: 0.2)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isUnlocked ? badge.glowColor : Colors.grey.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    badge.iconEmoji,
                                    style: TextStyle(
                                      fontSize: 26,
                                      color: isUnlocked ? null : Colors.grey,
                                    ),
                                  ),
                                ),
                                if (!isUnlocked)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1E293B),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.lock_rounded, size: 12, color: Colors.white70),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              badge.title,
                              style: TextStyle(
                                color: isUnlocked ? kTextColor : kSubtextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              badge.description,
                              style: TextStyle(
                                color: kSubtextColor,
                                fontSize: 10.5,
                                height: 1.25,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? badge.glowColor.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isUnlocked ? 'UNLOCKED ✨' : 'LOCKED',
                                style: TextStyle(
                                  color: isUnlocked ? badge.glowColor : kSubtextColor.withValues(alpha: 0.6),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

