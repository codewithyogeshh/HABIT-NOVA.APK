import 'package:flutter/material.dart';
import 'package:synvero/core/services/focus_sound_service.dart';

/// Ambient focus sound selector bar embedded in the Study Timer.
class FocusSoundSelectorWidget extends StatelessWidget {
  const FocusSoundSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kCardBg = isDark ? const Color(0xFF071728) : Colors.white;
    final kBorderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
    final kTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final kSubtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return ValueListenableBuilder<String?>(
      valueListenable: FocusSoundService.currentSoundIdNotifier,
      builder: (context, currentSoundId, _) {
        final isPlaying = currentSoundId != null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPlaying ? const Color(0xFF00F0FF).withValues(alpha: 0.5) : kBorderColor,
            ),
            boxShadow: isPlaying
                ? [
                    BoxShadow(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPlaying ? Icons.graphic_eq_rounded : Icons.headphones_rounded,
                          color: const Color(0xFF00F0FF),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Ambient Focus Sounds',
                        style: TextStyle(
                          color: kTextColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (isPlaying)
                    InkWell(
                      onTap: () => FocusSoundService.stopSound(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.stop_rounded, size: 12, color: Color(0xFFEF4444)),
                            SizedBox(width: 4),
                            Text(
                              'Stop',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Sound Chips Horizontal Scroll
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: FocusSoundService.options.map((opt) {
                    final isSelected = currentSoundId == opt.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          if (isSelected) {
                            FocusSoundService.stopSound();
                          } else {
                            FocusSoundService.playSound(opt.id);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
                                : (isDark ? const Color(0xFF030814) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00F0FF) : kBorderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(opt.iconEmoji, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                opt.name,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF00F0FF) : kSubtextColor,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
