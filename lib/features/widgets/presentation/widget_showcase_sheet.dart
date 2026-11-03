import 'package:flutter/material.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/app_widget_service.dart';
import 'package:synvero/core/services/language_service.dart';

class WidgetShowcaseSheet extends StatefulWidget {
  final int streakDays;
  final int habitsDone;
  final int habitsTotal;

  const WidgetShowcaseSheet({
    super.key,
    required this.streakDays,
    required this.habitsDone,
    required this.habitsTotal,
  });

  @override
  State<WidgetShowcaseSheet> createState() => _WidgetShowcaseSheetState();
}

class _WidgetShowcaseSheetState extends State<WidgetShowcaseSheet> {
  bool _isPinning = false;

  Future<void> _handlePinWidget() async {
    setState(() => _isPinning = true);
    final pinned = await AppWidgetService.pinWidgetToHomeScreen();
    if (mounted) {
      setState(() => _isPinning = false);
      if (pinned) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LanguageService.tr('widget_pinned_success')),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        final lang = LanguageService.currentLanguageCode;
        String hint;
        if (lang == LanguageService.marathi) {
          hint = '📱 होम स्क्रीनवर रिकाम्या जागेवर बोट दाबून ठेवा (Long-press) ➔ "Widgets" निवडा ➔ "HabbitNova" जोडा.';
        } else if (lang == LanguageService.hindi) {
          hint = '📱 होम स्क्रीन पर खाली जगह पर लॉन्ग-प्रेस करें ➔ "Widgets" चुनें ➔ "HabbitNova" जोड़ें।';
        } else {
          hint = '📱 Long-press on an empty spot on your home screen ➔ Select "Widgets" ➔ Add "HabbitNova".';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hint),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
      child: SingleChildScrollView(
        child: Column(
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

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('📱', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      LanguageService.tr('widget_sheet_title'),
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
            const SizedBox(height: 6),
            Text(
              LanguageService.tr('widget_sheet_subtitle'),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : kSecondaryText,
              ),
            ),
            const SizedBox(height: 18),

            // Mock Preview of the Live Android Widget
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'HabbitNova',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🔥 ${widget.streakDays > 0 ? widget.streakDays : 1}d Streak',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Progress Row
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: widget.habitsTotal > 0 ? widget.habitsDone / widget.habitsTotal : 0.6,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${widget.habitsDone}/${widget.habitsTotal > 0 ? widget.habitsTotal : 5} ${LanguageService.tr('habits_label')}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Habits mock list
                  _buildMockWidgetRow('Drink Water 💧', true),
                  _buildMockWidgetRow('30m Workout 🏋️', true),
                  _buildMockWidgetRow('Read 10 pages 📖', false),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Features Checklist
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureBullet(LanguageService.tr('widget_feature_1'), isDark),
                _buildFeatureBullet(LanguageService.tr('widget_feature_2'), isDark),
                _buildFeatureBullet(LanguageService.tr('widget_feature_3'), isDark),
              ],
            ),
            const SizedBox(height: 20),

            // Pin Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                icon: _isPinning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.push_pin_rounded, color: Colors.white),
                label: Text(
                  _isPinning ? '...' : LanguageService.tr('pin_widget_btn'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: _isPinning ? null : _handlePinWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMockWidgetRow(String title, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isDone ? const Color(0xFF10B981) : Colors.white38,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDone ? Colors.white70 : Colors.white54,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
