import 'package:flutter/material.dart';
import 'package:synvero/core/services/gamification_service.dart';
import 'package:synvero/core/services/streak_freeze_service.dart';
import 'package:synvero/core/widgets/glass_card.dart';

/// Compact dashboard card for Streak Freeze.
///
/// Shows how many freezes are banked, explains that a missed day is covered
/// automatically, and lets the user buy one with XP when the bank isn't full.
class StreakFreezeCard extends StatefulWidget {
  const StreakFreezeCard({super.key, this.onXPChanged});

  /// Called with the new XP balance after a successful purchase.
  final ValueChanged<int>? onXPChanged;

  @override
  State<StreakFreezeCard> createState() => _StreakFreezeCardState();
}

class _StreakFreezeCardState extends State<StreakFreezeCard> {
  static const Color _accent = Color(0xFF38BDF8);

  int _freezes = 0;
  int _xp = 150;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final freezes = await StreakFreezeService.availableFreezes();
    final xp = await GamificationService.loadXP();
    if (!mounted) return;
    setState(() {
      _freezes = freezes;
      _xp = xp;
      _loading = false;
    });
  }

  Future<void> _buy() async {
    if (_busy) return;
    setState(() => _busy = true);

    final result = await StreakFreezeService.purchaseFreeze();
    final xp = await GamificationService.loadXP();
    if (!mounted) return;

    setState(() => _busy = false);
    await _load();
    widget.onXPChanged?.call(xp);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    late final String message;
    switch (result) {
      case FreezePurchaseResult.success:
        message =
            'Streak Freeze खरेदी झाला (−${StreakFreezeService.freezeCostXP} XP) ❄️';
      case FreezePurchaseResult.insufficientXP:
        message = 'पुरेसे XP नाही. हॅबिट पूर्ण करून XP कमवा.';
      case FreezePurchaseResult.atCapacity:
        message =
            'जास्तीत जास्त ${StreakFreezeService.maxFreezes} freezes जवळ आहेत.';
      case FreezePurchaseResult.error:
        message = 'Freeze खरेदी होऊ शकला नाही. पुन्हा प्रयत्न करा.';
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: result == FreezePurchaseResult.success
            ? const Color(0xFF0284C7)
            : const Color(0xFF64748B),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);
    final subtextColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final atCapacity = _freezes >= StreakFreezeService.maxFreezes;
    final canAfford = _xp >= StreakFreezeService.freezeCostXP;
    final canBuy = !_loading && !_busy && !atCapacity && canAfford;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withValues(alpha: 0.35)),
            ),
            child: const Text('❄️', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Streak Freeze',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Semantics(
                      label:
                          '$_freezes of ${StreakFreezeService.maxFreezes} streak freezes available',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '$_freezes/${StreakFreezeService.maxFreezes}',
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Saves your streak automatically when you miss a day.',
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+1 free every week · buy for ${StreakFreezeService.freezeCostXP} XP',
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _BuyButton(
            enabled: canBuy,
            busy: _busy,
            label: atCapacity ? 'FULL' : 'BUY',
            caption: atCapacity
                ? '$_freezes/${StreakFreezeService.maxFreezes}'
                : '${StreakFreezeService.freezeCostXP} XP',
            accent: _accent,
            onTap: _buy,
          ),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.enabled,
    required this.busy,
    required this.label,
    required this.caption,
    required this.accent,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final String label;
  final String caption;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label $caption',
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? accent.withValues(alpha: 0.16)
                : accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: enabled ? 0.55 : 0.2),
            ),
          ),
          child: busy
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: enabled ? accent : accent.withValues(alpha: 0.5),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      caption,
                      style: TextStyle(
                        color: enabled
                            ? accent.withValues(alpha: 0.8)
                            : accent.withValues(alpha: 0.45),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
