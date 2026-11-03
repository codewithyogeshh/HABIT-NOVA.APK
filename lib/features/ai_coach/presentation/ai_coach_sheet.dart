import 'package:flutter/material.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/ai_coach_service.dart';
import 'package:synvero/core/services/language_service.dart';
import 'package:synvero/core/services/share_card_service.dart';

class AiCoachSheet extends StatefulWidget {
  final int streakDays;
  final int studyMinutes;
  final int screenTimeMinutes;
  final int habitsDone;
  final int habitsTotal;

  const AiCoachSheet({
    super.key,
    required this.streakDays,
    required this.studyMinutes,
    required this.screenTimeMinutes,
    required this.habitsDone,
    required this.habitsTotal,
  });

  @override
  State<AiCoachSheet> createState() => _AiCoachSheetState();
}

class _AiCoachSheetState extends State<AiCoachSheet> {
  CoachPersonality _personality = CoachPersonality.savageRoast;
  String _currentRoast = '';
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final p = await AiCoachService.getPersonality();
    final notifs = await AiCoachService.areNotificationsEnabled();
    final roast = AiCoachService.generateRoast(
      personality: p,
      streakDays: widget.streakDays,
      studyMinutes: widget.studyMinutes,
      screenTimeMinutes: widget.screenTimeMinutes,
      habitsDone: widget.habitsDone,
      habitsTotal: widget.habitsTotal,
    );

    if (mounted) {
      setState(() {
        _personality = p;
        _notificationsEnabled = notifs;
        _currentRoast = roast;
        _isLoading = false;
      });
    }
  }

  void _generateNewRoast() {
    final roast = AiCoachService.generateRoast(
      personality: _personality,
      streakDays: widget.streakDays,
      studyMinutes: widget.studyMinutes,
      screenTimeMinutes: widget.screenTimeMinutes,
      habitsDone: widget.habitsDone,
      habitsTotal: widget.habitsTotal,
    );
    setState(() => _currentRoast = roast);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          LanguageService.tr('ai_coach_title'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : kDarkText,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Personality Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPersonalityChip(CoachPersonality.savageRoast, LanguageService.tr('coach_savage')),
                      const SizedBox(width: 8),
                      _buildPersonalityChip(CoachPersonality.toughLove, LanguageService.tr('coach_tough')),
                      const SizedBox(width: 8),
                      _buildPersonalityChip(CoachPersonality.zenMaster, LanguageService.tr('coach_zen')),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // The Roast Speech Bubble
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                          : [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF97316).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF97316).withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _personality == CoachPersonality.savageRoast
                                ? '🔥 SAVAGE CALLOUT'
                                : '⚡ COACH ADVICE',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF97316),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentRoast,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                          color: isDark ? Colors.white : kDarkText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Actions: New Roast & WhatsApp Share
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : kDarkText,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(LanguageService.tr('generate_fresh_roast')),
                        onPressed: _generateNewRoast,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: Text(
                          LanguageService.tr('share_roast_whatsapp'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          final lang = LanguageService.currentLanguageCode;
                          String promoTag;
                          if (lang == LanguageService.marathi) {
                            promoTag = '🚀 Habit-Nova वरील माझा AI कोच मला थेट टोमणे मारून अभ्यासाला लावतोय! 😂\nतुम्हीही तुमचे हॅबिट्स ट्रॅक करा:';
                          } else if (lang == LanguageService.hindi) {
                            promoTag = '🚀 Habit-Nova पर मेरा AI कोच मुझे मजेदार व्यंग्य सुनाकर पढ़ाई करवा रहा है! 😂\nआप भी अपनी आदतें ट्रैक करें:';
                          } else {
                            promoTag = '🚀 My AI Coach on Habit-Nova keeps me accountable with savage roasts! 😂\nTrack your habits & boost your streak:';
                          }
                          final text = '$_currentRoast\n\n$promoTag\nhttps://github.com/codewithyogeshh/HABIT-NOVA.APK';
                          ShareCardService.shareText(text, title: LanguageService.tr('share_roast_whatsapp'));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notification Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    LanguageService.tr('daily_notifications_title'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : kDarkText,
                    ),
                  ),
                  subtitle: Text(
                    LanguageService.tr('daily_notifications_desc'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : kSecondaryText,
                    ),
                  ),
                  value: _notificationsEnabled,
                  activeTrackColor: kPrimaryColor,
                  onChanged: (val) async {
                    setState(() => _notificationsEnabled = val);
                    await AiCoachService.setNotificationsEnabled(val);
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildPersonalityChip(CoachPersonality p, String label) {
    final isSelected = _personality == p;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: kPrimaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (val) async {
        if (val) {
          setState(() => _personality = p);
          await AiCoachService.setPersonality(p);
          _generateNewRoast();
        }
      },
    );
  }
}
