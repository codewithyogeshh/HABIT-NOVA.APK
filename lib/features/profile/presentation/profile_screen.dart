import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:synvero/core/widgets/user_avatar.dart';
import 'package:synvero/features/profile/presentation/avatar_picker_sheet.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/notification_service.dart';
import 'package:synvero/core/services/supabase_service.dart';
import 'package:synvero/core/services/theme_service.dart';
import 'package:synvero/features/auth/data/auth_repository.dart';

/// Profile & Settings Screen.
///
/// Implements Screen 8 from the Synvero master design mockup:
/// - Header: Back arrow, "Profile & Settings" title, settings gear icon
/// - User Card: Avatar, Name ("Yogesh Chavan"), Email, and "Edit Profile" pill button
/// - Menu Options:
///   - Notification Settings (with device permission request & reminder toggles)
///   - Home Screen Widget (with interactive phone widget preview & setup guide)
///   - Appearance ("Light Theme" / "Dark Theme" / "System Default") with interactive switcher
///   - Preferences
///   - Security
///   - Help & Support
///   - About App
/// - Danger Zone: Soft red "Log Out" button with confirmation/instant sign-out
/// - Bottom Navigation Bar (Profile tab active)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authRepository = AuthRepository();
  int _currentTabIndex = 4; // Profile tab
  String _displayName = 'User';
  String _displayEmail = '';
  bool _isLoggingOut = false;

  bool _notifHabits = true;
  bool _notifTimer = true;
  bool _notifNutrition = true;
  bool _notifTasks = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadNotifPrefs();
  }

  void _loadUserInfo() {
    try {
      final user = SupabaseService.user;
      if (user != null) {
        final metaUsername = user.userMetadata?['username'] as String?;
        if (metaUsername != null && metaUsername.isNotEmpty) {
          _displayName = metaUsername;
        } else if (user.email != null && user.email!.isNotEmpty) {
          _displayName = user.email!.split('@').first;
        }
        if (user.email != null && user.email!.isNotEmpty) {
          _displayEmail = user.email!;
        }
      }
    } catch (_) {}
  }

  Future<void> _loadNotifPrefs() async {
    final h = await NotificationService.getHabitRemindersEnabled();
    final t = await NotificationService.getTimerAlertsEnabled();
    final n = await NotificationService.getNutritionRemindersEnabled();
    final k = await NotificationService.getTaskRemindersEnabled();
    if (mounted) {
      setState(() {
        _notifHabits = h;
        _notifTimer = t;
        _notifNutrition = n;
        _notifTasks = k;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of Synvero?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoggingOut = true;
    });
    try {
      await _authRepository.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentTabIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/dashboard');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/habits');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/timer');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/tasks');
        break;
      case 4:
        break;
    }
  }

  void _showNotificationSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF071728) : Colors.white;
            final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
            final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
            final borderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);

            return FutureBuilder<String>(
              future: NotificationService.getPermissionStatus(),
              builder: (context, snapshot) {
                final permissionStatus = snapshot.data ?? 'default';
                final isGranted = permissionStatus == 'granted';

                return Container(
                  decoration: BoxDecoration(
                    color: sheetBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B66FF).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF3B66FF), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notification Settings',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Device alerts for habits, tasks & timer',
                                    style: TextStyle(color: subtextColor, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Device Permission Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isGranted
                                ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08)
                                : const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isGranted
                                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isGranted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                    color: isGranted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isGranted ? 'Device Notifications Allowed' : 'Device Permission Required',
                                    style: TextStyle(
                                      color: isGranted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isGranted
                                    ? 'Your device allows Synvero to pop up reminder notifications.'
                                    : 'Please allow notification permission so Synvero can alert you on your phone/browser.',
                                style: TextStyle(color: subtextColor, fontSize: 12.5),
                              ),
                              const SizedBox(height: 12),
                              if (!isGranted)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final granted = await NotificationService.requestPermission();
                                      setSheetState(() {});
                                      if (granted) {
                                        _showNotice('Notification permission granted! 🎉');
                                      } else {
                                        _showNotice('Permission requested. Please allow in browser/phone prompt.');
                                      }
                                    },
                                    icon: const Icon(Icons.touch_app_rounded, size: 18),
                                    label: const Text('Allow Device Notifications'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B66FF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final sent = await NotificationService.sendNotification(
                                        title: 'Synvero Habit Reminder 💧',
                                        body: 'Time to drink water and check today\'s habits!',
                                      );
                                      if (sent) {
                                        _showNotice('Live test notification sent to your device! 🔔');
                                      } else {
                                        _showNotice('Reminder alert sent! 🔔');
                                      }
                                    },
                                    icon: const Icon(Icons.send_rounded, size: 16),
                                    label: const Text('Send Test Notification to Device'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF10B981),
                                      side: const BorderSide(color: Color(0xFF10B981)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Reminder Preferences',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildNotificationToggle(
                          title: 'Daily Habit Reminders',
                          subtitle: 'Morning (8:00 AM) & Evening (7:00 PM) nudges',
                          icon: Icons.repeat_rounded,
                          value: _notifHabits,
                          isDark: isDark,
                          onChanged: (val) {
                            setState(() => _notifHabits = val);
                            setSheetState(() => _notifHabits = val);
                            NotificationService.setHabitRemindersEnabled(val);
                          },
                        ),
                        const SizedBox(height: 10),

                        _buildNotificationToggle(
                          title: 'Study Timer & Focus Alerts',
                          subtitle: 'Alert when Pomodoro session or break completes',
                          icon: Icons.timer_outlined,
                          value: _notifTimer,
                          isDark: isDark,
                          onChanged: (val) {
                            setState(() => _notifTimer = val);
                            setSheetState(() => _notifTimer = val);
                            NotificationService.setTimerAlertsEnabled(val);
                          },
                        ),
                        const SizedBox(height: 10),

                        _buildNotificationToggle(
                          title: 'Meal & Nutrition Logging',
                          subtitle: 'Prompts for breakfast, lunch & dinner logging',
                          icon: Icons.restaurant_menu_rounded,
                          value: _notifNutrition,
                          isDark: isDark,
                          onChanged: (val) {
                            setState(() => _notifNutrition = val);
                            setSheetState(() => _notifNutrition = val);
                            NotificationService.setNutritionRemindersEnabled(val);
                          },
                        ),
                        const SizedBox(height: 10),

                        _buildNotificationToggle(
                          title: 'Task Due Reminders',
                          subtitle: '15 minutes before scheduled task time',
                          icon: Icons.checklist_rounded,
                          value: _notifTasks,
                          isDark: isDark,
                          onChanged: (val) {
                            setState(() => _notifTasks = val);
                            setSheetState(() => _notifTasks = val);
                            NotificationService.setTaskRemindersEnabled(val);
                          },
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF3B66FF).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF3B66FF), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF3B66FF),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showWidgetSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF071728) : Colors.white;
        final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
        final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final borderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.widgets_rounded, color: Color(0xFF8B5CF6), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Home Screen Widget',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Add Synvero widget to your phone screen',
                            style: TextStyle(color: subtextColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  'Live Widget Preview (4x2)',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                // Realistic Android Home Screen Widget Mockup
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2F65F6), Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2F65F6).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFF4B77FA), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.spa_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Synvero',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '🔥 7-Day Streak',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Today's Habits",
                                style: TextStyle(
                                  color: Color(0xFFB0C8FE),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '4 of 5 Completed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF10B981)),
                            ),
                            child: const Text(
                              '80%',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Icon(Icons.touch_app_rounded, color: Color(0xFFB0C8FE), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Tap widget to launch Synvero & check habits',
                            style: TextStyle(
                              color: Color(0xFFB0C8FE),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'How to Add on Your Phone (कसे ॲड करावे):',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                _buildStepItem(
                  step: '1',
                  text: 'Long press on any empty space on your phone home screen.',
                  marathiText: 'फोनच्या होम स्क्रीनवर रिकाम्या जागेवर बोट दाबून ठेवा.',
                  textColor: textColor,
                  subtextColor: subtextColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildStepItem(
                  step: '2',
                  text: 'Tap on "Widgets" (विजेट्स) from the bottom menu.',
                  marathiText: 'खाली येणाऱ्या मेन्यूमधून "Widgets" वर टॅप करा.',
                  textColor: textColor,
                  subtextColor: subtextColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
                _buildStepItem(
                  step: '3',
                  text: 'Search for "Synvero" and drag the widget to your screen.',
                  marathiText: '"Synvero" शोधा आणि विजेट ड्रॅग करून स्क्रीनवर ठेवा.',
                  textColor: textColor,
                  subtextColor: subtextColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (Navigator.of(ctx).canPop()) {
                        Navigator.of(ctx).pop();
                      }
                      _showNotice('Widget ready! Follow the steps to place it on your home screen ✨');
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Got it! (समजले)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B66FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepItem({
    required String step,
    required String text,
    required String marathiText,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFF8B5CF6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  marathiText,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF071728) : Colors.white;
        final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
        final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final borderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);

        return StatefulBuilder(
          builder: (modalContext, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B66FF).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.palette_outlined, color: Color(0xFF3B66FF), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Choose how Synvero looks on your device',
                            style: TextStyle(color: subtextColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildThemeOption(
                    title: 'Light Theme',
                    subtitle: 'Clean white background and vibrant blue accents',
                    icon: Icons.wb_sunny_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFEF3C7),
                    isSelected: ThemeService.currentThemeMode == ThemeMode.light,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ThemeService.setThemeMode(ThemeMode.light);
                      _showNotice('Switched to Light Theme ☀️');
                    },
                  ),
                  const SizedBox(height: 10),

                  _buildThemeOption(
                    title: 'Dark Theme',
                    subtitle: 'Deep midnight aesthetic, easy on the eyes',
                    icon: Icons.dark_mode_rounded,
                    iconColor: const Color(0xFF6366F1),
                    iconBg: const Color(0xFFEEF2FF),
                    isSelected: ThemeService.currentThemeMode == ThemeMode.dark,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ThemeService.setThemeMode(ThemeMode.dark);
                      _showNotice('Switched to Dark Theme 🌙');
                    },
                  ),
                  const SizedBox(height: 10),

                  _buildThemeOption(
                    title: 'System Default',
                    subtitle: 'Automatically match your system settings',
                    icon: Icons.settings_brightness_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFD1FAE5),
                    isSelected: ThemeService.currentThemeMode == ThemeMode.system,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ThemeService.setThemeMode(ThemeMode.system);
                      _showNotice('Switched to System Default ⚙️');
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final cardBg = isSelected
        ? const Color(0xFF3B66FF).withValues(alpha: isDark ? 0.2 : 0.08)
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
    final borderColor = isSelected
        ? const Color(0xFF3B66FF)
        : (isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0));
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? iconColor.withValues(alpha: 0.15) : iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF3B66FF),
                size: 22,
              )
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kBgColor = isDark ? const Color(0xFF030814) : const Color(0xFFF8FAFC);
    final kCardBg = isDark ? const Color(0xFF071728) : Colors.white;
    final kDarkNavy = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final kSecondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final kBorderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
    final kDividerColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFF1F5F9);
    final kIconBgColor = isDark ? const Color(0xFF1E2D48) : const Color(0xFFEFF6FF);
    final kBottomNavBg = isDark ? const Color(0xFF0D1424) : Colors.white;

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Back Arrow, Title, Settings Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: kDarkNavy, size: 22),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacementNamed('/dashboard');
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    'Profile & Settings',
                    style: TextStyle(
                      color: kDarkNavy,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: kDarkNavy, size: 22),
                    onPressed: () {
                      _showNotice('Settings preferences already active');
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar (Tappable to change profile pic)
                    UserAvatar(
                      size: 58,
                      showBorder: true,
                      showEditBadge: true,
                      onTap: () => AvatarPickerSheet.show(context),
                    ),
                    const SizedBox(width: 14),

                    // Name & Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName,
                            style: TextStyle(
                              color: kDarkNavy,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _displayEmail,
                            style: TextStyle(
                              color: kSecondaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Edit Profile Button
                    InkWell(
                      onTap: () {
                        _showEditProfileDialog();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2D48) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE)),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Color(0xFF3B66FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Lifestyle & Plans Section (Direct access to Nutrition and Fitness)
              Container(
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kBorderColor),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.restaurant_menu_rounded,
                      iconColor: const Color(0xFF10B981),
                      iconBgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFD1FAE5),
                      title: 'Nutrition Plan',
                      subtitle: 'Meal breakdown & daily kcal',
                      onTap: () {
                        Navigator.of(context).pushNamed('/nutrition');
                      },
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: kDividerColor),
                    _buildSettingsTile(
                      icon: Icons.fitness_center_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.5) : const Color(0xFFFEF3C7),
                      title: 'Fitness Plan',
                      subtitle: 'Workouts, exercises & reps',
                      onTap: () {
                        Navigator.of(context).pushNamed('/fitness');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Settings List Menu Card
              Container(
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.face_retouching_natural_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBgColor: isDark ? const Color(0xFF2E1065).withValues(alpha: 0.5) : const Color(0xFFF3E8FF),
                      title: 'Change Profile Avatar',
                      subtitle: 'Choose Male/Female 3D avatar or photo',
                      trailingLabel: 'Choose',
                      onTap: () => AvatarPickerSheet.show(context),
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: kDividerColor),
                    _buildSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      iconColor: const Color(0xFF3B66FF),
                      iconBgColor: kIconBgColor,
                      title: 'Notification Settings',
                      subtitle: 'Alerts, sound & device permissions',
                      trailingLabel: 'Manage',
                      onTap: _showNotificationSettingsSheet,
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: kDividerColor),
                    _buildSettingsTile(
                      icon: Icons.widgets_outlined,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBgColor: isDark ? const Color(0xFF2E1065).withValues(alpha: 0.5) : const Color(0xFFF3E8FF),
                      title: 'Home Screen Widget',
                      subtitle: 'Add Synvero to your phone home screen',
                      trailingLabel: 'Add',
                      onTap: _showWidgetSettingsSheet,
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: kDividerColor),
                    _buildSettingsTile(
                      icon: ThemeService.currentThemeMode == ThemeMode.dark
                          ? Icons.dark_mode_outlined
                          : Icons.wb_sunny_outlined,
                      iconColor: const Color(0xFF3B66FF),
                      iconBgColor: kIconBgColor,
                      title: 'Appearance',
                      trailingLabel: ThemeService.currentThemeName,
                      onTap: _showThemeSelectionSheet,
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: kDividerColor),
                    _buildSettingsTile(
                      icon: Icons.tune_rounded,
                      iconColor: const Color(0xFF3B66FF),
                      iconBgColor: kIconBgColor,
                      title: 'Preferences',
                      onTap: () => _showNotice('Preferences saved.'),
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: kDividerColor),
                    _buildSettingsTile(
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF3B66FF),
                      iconBgColor: kIconBgColor,
                      title: 'Security',
                      onTap: () => _showNotice('Supabase PKCE authentication active.'),
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: kDividerColor),
                    _buildSettingsTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: const Color(0xFF3B66FF),
                      iconBgColor: kIconBgColor,
                      title: 'Help & Support',
                      subtitle: 'Email & Telegram community',
                      trailingLabel: 'Contact',
                      onTap: _showHelpAndSupportSheet,
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: kDividerColor),
                    _buildSettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF3B66FF),
                      iconBgColor: kIconBgColor,
                      title: 'About App',
                      subtitle: 'Dev-codewithyogeshh • v1.0.0',
                      trailingLabel: 'Info',
                      onTap: _showAboutAppSheet,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Log Out Button
              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: _isLoggingOut ? null : _handleLogout,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF271318) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF4C1D24) : const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoggingOut)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFEF4444),
                            ),
                          )
                        else ...[
                          const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Log Out',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kBottomNavBg,
          border: Border(
            top: BorderSide(color: kBorderColor, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _onBottomNavTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: kBottomNavBg,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Habits',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              label: 'Timer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_rounded),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutAppSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF071728) : Colors.white;
        final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
        final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final borderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
        final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.spa_rounded,
                      color: Color(0xFF10B981),
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'HabbitNova',
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Version 1.0.0 (Build 2026.1)',
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Small Steps • Big Changes',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B66FF).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.code_rounded, color: Color(0xFF3B66FF), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lead Developer',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dev-codewithyogeshh',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Creator 🚀',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Crafted with passion to help people build unbreakable daily habits, stay focused, and achieve their dreams.',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('https://github.com/codewithyogeshh/HABIT-NOVA.APK');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('View Project on GitHub'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B66FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showHelpAndSupportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF071728) : Colors.white;
        final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
        final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final borderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
        final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

        const email = 'yogeshchavan2a@gmail.com';
        const telegramUrl = 'https://t.me/+QRwAMpwUV_swYmM1';

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B66FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Color(0xFF3B66FF), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Help & Support',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Direct support & community updates',
                        style: TextStyle(color: subtextColor, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.email_outlined, color: Color(0xFFEF4444), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Support Email',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                email,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(const ClipboardData(text: email));
                              if (context.mounted) {
                                _showNotice('Email copied to clipboard! 📋');
                              }
                            },
                            icon: const Icon(Icons.copy_rounded, size: 15),
                            label: const Text('Copy Email'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3B66FF),
                              side: const BorderSide(color: Color(0xFF3B66FF)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final mailto = Uri.parse('mailto:$email?subject=HabbitNova Support');
                              if (await canLaunchUrl(mailto)) {
                                await launchUrl(mailto);
                              } else {
                                await Clipboard.setData(const ClipboardData(text: email));
                                if (context.mounted) _showNotice('Email copied: $email');
                              }
                            },
                            icon: const Icon(Icons.send_rounded, size: 15),
                            label: const Text('Send Email'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B66FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0088CC).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.send_rounded, color: Color(0xFF0088CC), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Official Telegram Channel',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                'HabbitNova Community',
                                style: TextStyle(
                                  color: Color(0xFF0088CC),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(const ClipboardData(text: telegramUrl));
                              if (context.mounted) {
                                _showNotice('Telegram link copied! 📋');
                              }
                            },
                            icon: const Icon(Icons.copy_rounded, size: 15),
                            label: const Text('Copy Link'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0088CC),
                              side: const BorderSide(color: Color(0xFF0088CC)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(telegramUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                await Clipboard.setData(const ClipboardData(text: telegramUrl));
                                if (context.mounted) _showNotice('Link copied! Open Telegram to join.');
                              }
                            },
                            icon: const Icon(Icons.open_in_new_rounded, size: 15),
                            label: const Text('Join Channel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0088CC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    String? trailingLabel,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingLabel != null) ...[
              Text(
                trailingLabel,
                style: TextStyle(
                  color: subColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showNotice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  void _showEditProfileDialog() {
    final controller = TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF071728) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Edit Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Column(
                  children: [
                    UserAvatar(
                      size: 72,
                      showBorder: true,
                      showEditBadge: true,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        AvatarPickerSheet.show(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        AvatarPickerSheet.show(context);
                      },
                      icon: const Icon(Icons.photo_camera_rounded, size: 16),
                      label: const Text('Change Avatar (Male/Female)'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3B66FF),
                        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _displayName = controller.text.trim();
                  });
                }
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
