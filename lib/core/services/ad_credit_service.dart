import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/supabase_service.dart';
import 'package:synvero/core/widgets/celebration_dialog.dart';
import 'package:synvero/core/widgets/gooey_drop_notification.dart';

/// AdMob Rewarded Ad & Study Squad Credit System.
///
/// Ethical Monetization:
/// - 100% voluntary & opt-in. Never interrupts daily task/habit flows.
/// - Watching a short video ad rewards the user with Nova Credits (🪙).
/// - Nova Credits are used to create Study Squads / Groups.
class AdCreditService {
  static const int kCreditsPerAd = 50;
  static const int kSquadCreationCost = 50;
  static const int kWelcomeBonusCredits = 50;

  // Official Google AdMob Rewarded Video Test Ad Unit IDs
  static const String _kAndroidRewardedTestAdId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _kIosRewardedTestAdId = 'ca-app-pub-3940256099942544/1712485313';

  // Set your production AdMob Rewarded Unit ID here when publishing to Play Store:
  static String? productionAdUnitId = 'ca-app-pub-4840571202367997/9662240668';

  static String get primaryAdUnitId {
    if (productionAdUnitId != null && productionAdUnitId!.isNotEmpty) {
      return productionAdUnitId!;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _kIosRewardedTestAdId
        : _kAndroidRewardedTestAdId;
  }

  static RewardedAd? _rewardedAd;
  static bool _isLoadingAd = false;
  static bool _isInitialized = false;

  static final ValueNotifier<int> creditsNotifier = ValueNotifier<int>(kWelcomeBonusCredits);

  static String get _currentUserId => SupabaseService.user?.id ?? 'guest';
  static String get _prefKey => 'user_${_currentUserId}_study_credits_v1';

  /// Initializes Google Mobile Ads SDK and pre-loads the first rewarded ad
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      // Whitelist physical test device to allow AdMob ads without HTTP 403
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: [
            'DB6D19BDE64BE48110B08EB10521A4F7', // User Redmi Note 12 5G
          ],
        ),
      );
      _isInitialized = true;
      await loadCredits();
      loadRewardedAd();
    } catch (e) {
      debugPrint('AdCreditService init error: $e');
      await loadCredits();
    }
  }

  /// Loads persistent credit balance from local storage
  static Future<int> loadCredits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_prefKey)) {
        // Welcome bonus for new users
        await prefs.setInt(_prefKey, kWelcomeBonusCredits);
      }
      final current = prefs.getInt(_prefKey) ?? kWelcomeBonusCredits;
      creditsNotifier.value = current;
      return current;
    } catch (_) {
      return creditsNotifier.value;
    }
  }

  /// Adds credits to user wallet (e.g. after watching rewarded ad)
  static Future<void> addCredits(int amount, {required String reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_prefKey) ?? kWelcomeBonusCredits;
      final newTotal = current + amount;
      await prefs.setInt(_prefKey, newTotal);
      creditsNotifier.value = newTotal;
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Deducts credits (e.g. for squad creation). Returns true if successful.
  static Future<bool> deductCredits(int amount, {required String reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_prefKey) ?? kWelcomeBonusCredits;
      if (current < amount) return false;

      final newTotal = current - amount;
      await prefs.setInt(_prefKey, newTotal);
      creditsNotifier.value = newTotal;
      HapticFeedback.lightImpact();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Pre-loads a RewardedAd in the background.
  /// Attempts production unit ID first; if Google rejects (HTTP 403 or error 3 while unit is propagating),
  /// immediately falls back to AdMob official sample unit so a real AdMob video ALWAYS plays!
  static Future<RewardedAd?> loadRewardedAd({bool forceReload = false}) async {
    if (_rewardedAd != null && !forceReload) return _rewardedAd;
    if (_isLoadingAd) return null;
    _isLoadingAd = true;

    final completer = Completer<RewardedAd?>();

    void tryLoad(String unitId, {required bool isProduction}) {
      debugPrint('[AdMob] Loading RewardedAd: unitId=$unitId (isProduction=$isProduction)');
      RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoadingAd = false;
            debugPrint('[AdMob] RewardedAd loaded successfully! (isProduction=$isProduction)');
            if (!completer.isCompleted) completer.complete(ad);
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdMob] RewardedAd failed for $unitId: ${error.code} - ${error.message}');
            if (isProduction) {
              debugPrint('[AdMob] Production unit propagating. Falling back to AdMob sample video unit...');
              tryLoad(
                defaultTargetPlatform == TargetPlatform.iOS
                    ? _kIosRewardedTestAdId
                    : _kAndroidRewardedTestAdId,
                isProduction: false,
              );
            } else {
              _rewardedAd = null;
              _isLoadingAd = false;
              if (!completer.isCompleted) completer.complete(null);
            }
          },
        ),
      );
    }

    final targetUnitId = primaryAdUnitId;

    tryLoad(targetUnitId, isProduction: targetUnitId == productionAdUnitId);

    return completer.future;
  }

  /// Shows the real Google AdMob Rewarded Video Ad to the user.
  /// If not cached yet, displays a brief high-tech loader while AdMob loads the video,
  /// then launches Google\'s full-screen video player!
  static Future<bool> showRewardedAd({
    required BuildContext context,
    required VoidCallback onRewardGranted,
  }) async {
    HapticFeedback.selectionClick();

    RewardedAd? ad = _rewardedAd;

    if (ad == null) {
      // Show brief modern loading indicator while AdMob loads the video
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00E5FF)),
                  SizedBox(height: 16),
                  Text(
                    'AdMob Video Ad लोड होत आहे... 🎬',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      ad = await loadRewardedAd().timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
      }
    }

    if (ad != null) {
      final completer = Completer<bool>();
      bool earnedReward = false;

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('[AdMob] RewardedAd showed full screen video content.');
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd(); // Pre-load next ad
          if (earnedReward) {
            onRewardGranted();
            completer.complete(true);
          } else {
            completer.complete(false);
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[AdMob] RewardedAd failed to show: $error');
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
          if (context.mounted) {
            _showSimulatedSponsorDialog(context, onRewardGranted).then((res) {
              completer.complete(res);
            });
          } else {
            completer.complete(false);
          }
        },
      );

      ad.show(
        onUserEarnedReward: (adWithoutView, reward) async {
          earnedReward = true;
          await addCredits(kCreditsPerAd, reason: 'Watched Rewarded Ad');
          if (context.mounted) {
            GooeyNotification.show(
              context,
              title: '+$kCreditsPerAd Nova Credits! 🪙',
              message: 'Study Squad wallet loaded! Ready to create squad.',
              icon: Icons.monetization_on_rounded,
              type: GooeyNotificationType.reward,
            );
          }
        },
      );

      return completer.future;
    } else {
      // If network is completely offline, fall back to sponsor modal
      if (context.mounted) {
        return _showSimulatedSponsorDialog(context, onRewardGranted);
      }
      return false;
    }
  }

  /// Sleek fallback simulated sponsor video dialog with 5s countdown
  static Future<bool> _showSimulatedSponsorDialog(
    BuildContext context,
    VoidCallback onRewardGranted,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _SponsorAdDialog(),
    );

    if (result == true) {
      await addCredits(kCreditsPerAd, reason: 'Watched Sponsor Video');
      onRewardGranted();
      if (context.mounted) {
        CelebrationDialog.show(
          context,
          title: '+$kCreditsPerAd Credits Earned! 🪙',
          subtitle: 'Ready to create your Study Squad!',
          streakDays: 0,
        );
      }
      return true;
    }
    return false;
  }
}

/// Simulated sponsor video dialog for instant testing or when offline
class _SponsorAdDialog extends StatefulWidget {
  const _SponsorAdDialog();

  @override
  State<_SponsorAdDialog> createState() => _SponsorAdDialogState();
}

class _SponsorAdDialogState extends State<_SponsorAdDialog> with SingleTickerProviderStateMixin {
  int _secondsRemaining = 5;
  Timer? _countdownTimer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF071728) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'SPONSOR VIDEO 🎬',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _secondsRemaining > 0 ? 'Reward in ${_secondsRemaining}s' : 'Reward Ready! ✨',
                    style: TextStyle(
                      color: _secondsRemaining > 0 ? const Color(0xFF00F0FF) : const Color(0xFF10B981),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Video animation showcase placeholder
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0369A1), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'HabitNova Study Partner Network',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Supporting high-focus students everywhere 🚀',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _secondsRemaining > 0
                  ? 'Watch this 5-second video to earn +50 Study Credits!'
                  : 'Congratulations! You unlocked +50 Study Credits 🪙',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _secondsRemaining == 0
                    ? () => Navigator.of(context).pop(true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                  disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _secondsRemaining > 0
                      ? 'Wait ${_secondsRemaining}s for reward'
                      : 'Claim +50 Credits 🪙',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

