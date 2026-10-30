import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synvero/core/services/app_limit_service.dart';

/// Screen displaying daily screen time, weekly usage trends, and most used apps
/// with Digital Wellbeing App Usage Limits and Focus App Blocker.
///
/// Implements the Statistics & Screen Time view with Bioluminescent Zen styling.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTab = 0; // 0: Screen, 1: Data
  int _weekOffset = 0;
  Map<String, int> _appLimits = {};

  // Weekly screen time hours: Mon, Tue, Wed, Thu, Fri, Sat, Sun
  final List<double> _weeklyHours = [7.8, 8.2, 5.5, 8.0, 4.2, 3.5, 2.0];
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<Map<String, dynamic>> _screenTimeApps = [
    {
      'name': 'Instagram',
      'duration': '1 hour, 30 minutes',
      'category': 'Social Media',
      'icon': Icons.camera_alt_rounded,
      'gradient': [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
    },
    {
      'name': 'YouTube',
      'duration': '1 hour, 1 minute',
      'category': 'Entertainment & Study',
      'icon': Icons.play_arrow_rounded,
      'gradient': [Color(0xFFFF0000), Color(0xFFCC0000)],
    },
    {
      'name': 'HabbitNova Focus',
      'duration': '45 minutes',
      'category': 'Productivity & Habits',
      'icon': Icons.eco_rounded,
      'gradient': [Color(0xFF00E5FF), Color(0xFF10B981)],
    },
    {
      'name': 'WA Business',
      'duration': '26 minutes',
      'category': 'Communication',
      'icon': Icons.chat_rounded,
      'gradient': [Color(0xFF25D366), Color(0xFF128C7E)],
    },
    {
      'name': 'Chrome Browser',
      'duration': '20 minutes',
      'category': 'Reading & Research',
      'icon': Icons.public_rounded,
      'gradient': [Color(0xFF4285F4), Color(0xFF0F9D58)],
    },
  ];

  final List<Map<String, dynamic>> _dataApps = [
    {
      'name': 'YouTube',
      'usage': '940 MB',
      'category': 'Streaming & Video',
      'icon': Icons.play_arrow_rounded,
      'gradient': [Color(0xFFFF0000), Color(0xFFCC0000)],
    },
    {
      'name': 'Instagram',
      'usage': '580 MB',
      'category': 'Reels & Media',
      'icon': Icons.camera_alt_rounded,
      'gradient': [Color(0xFF833AB4), Color(0xFFFD1D1D)],
    },
    {
      'name': 'Chrome Browser',
      'usage': '220 MB',
      'category': 'Web Browsing',
      'icon': Icons.public_rounded,
      'gradient': [Color(0xFF4285F4), Color(0xFF0F9D58)],
    },
    {
      'name': 'WhatsApp',
      'usage': '110 MB',
      'category': 'Messages & Calls',
      'icon': Icons.chat_rounded,
      'gradient': [Color(0xFF25D366), Color(0xFF128C7E)],
    },
    {
      'name': 'HabbitNova Sync',
      'usage': '35 MB',
      'category': 'Habit & AI Updates',
      'icon': Icons.eco_rounded,
      'gradient': [Color(0xFF00E5FF), Color(0xFF10B981)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    await AppLimitService.initializeDefaultsIfNeeded();
    final names = _screenTimeApps.map((a) => a['name'] as String).toList();
    final limits = await AppLimitService.loadAllLimits(names);
    if (mounted) {
      setState(() {
        _appLimits = limits;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kBgColor = isDark ? const Color(0xFF030814) : const Color(0xFFF8FAFC);
    final kCardBg = isDark ? const Color(0xFF071728) : Colors.white;
    final kBorderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
    final kTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final kSubtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: kTextColor, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Statistics',
          style: TextStyle(
            color: kTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Switcher: [📱 Screen] [🌐 Data]
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF071728) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorderColor),
                ),
                child: Row(
                  children: [
                    _buildSegmentTab(
                      index: 0,
                      label: 'Screen',
                      icon: Icons.smartphone_rounded,
                      isDark: isDark,
                    ),
                    _buildSegmentTab(
                      index: 1,
                      label: 'Data',
                      icon: Icons.public_rounded,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Hero Usage Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF0E223D),
                            const Color(0xFF071728),
                          ]
                        : [
                            const Color(0xFFEEF2FF),
                            Colors.white,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.08 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                      ),
                      child: Icon(
                        _selectedTab == 0 ? Icons.phone_android_rounded : Icons.wifi_rounded,
                        color: const Color(0xFF00E5FF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedTab == 0 ? 'Screen time' : 'Daily data usage',
                            style: TextStyle(
                              color: kSubtextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedTab == 0 ? '4 hours, 12 minutes' : '1.84 GB today',
                            style: TextStyle(
                              color: kTextColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Weekly Bar Chart Container
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: kBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bar Chart with Y-Axis guidelines
                    SizedBox(
                      height: 190,
                      child: Stack(
                        children: [
                          // Y-Axis Horizontal dashed guideline levels (11h, 8h, 5h, 3h, 0s)
                          Positioned.fill(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildGridLine('11h', isDark),
                                _buildGridLine('8h', isDark),
                                _buildGridLine('5h', isDark),
                                _buildGridLine('3h', isDark),
                                _buildGridLine('0s', isDark),
                              ],
                            ),
                          ),

                          // Weekly pill columns
                          Positioned(
                            left: 36,
                            right: 0,
                            top: 4,
                            bottom: 6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(_weeklyHours.length, (i) {
                                final h = _weeklyHours[i];
                                final isToday = i == 4; // Friday highlighted
                                final heightRatio = (h / 11.0).clamp(0.08, 1.0);

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 140 * heightRatio,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: isToday
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF2E3A75),
                                                  Color(0xFF6366F1),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              )
                                            : LinearGradient(
                                                colors: isDark
                                                    ? [
                                                        const Color(0xFF1E293B),
                                                        const Color(0xFF0F172A),
                                                      ]
                                                    : [
                                                        const Color(0xFFE2E8F0),
                                                        const Color(0xFFCBD5E1),
                                                      ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                        boxShadow: isToday
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Day labels below bars
                    Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(_weekDays.length, (i) {
                          final isToday = i == 4;
                          return SizedBox(
                            width: 28,
                            child: Center(
                              child: Text(
                                _weekDays[i],
                                style: TextStyle(
                                  color: isToday
                                      ? (isDark ? Colors.white : const Color(0xFF4F46E5))
                                      : kSubtextColor,
                                  fontSize: 11,
                                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(color: kBorderColor.withValues(alpha: 0.5), height: 1),
                    const SizedBox(height: 12),

                    // Week navigator: < Oct 26 - Nov 1 >
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() => _weekOffset--);
                          },
                          icon: const Icon(Icons.chevron_left_rounded),
                          color: kSubtextColor,
                          iconSize: 22,
                        ),
                        Text(
                          _weekOffset == 0
                              ? 'Oct 26 - Nov 1'
                              : 'Week ${_weekOffset.abs()} ${_weekOffset < 0 ? 'ago' : 'ahead'}',
                          style: TextStyle(
                            color: kTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_weekOffset < 0) {
                              setState(() => _weekOffset++);
                            }
                          },
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: _weekOffset < 0 ? kSubtextColor : kSubtextColor.withValues(alpha: 0.3),
                          iconSize: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section: Most Used Apps & App Limits
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTab == 0 ? 'Most used apps' : 'Data consumption by apps',
                        style: TextStyle(
                          color: kTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_selectedTab == 0)
                        Text(
                          'Tap app to set daily usage limit & focus shield',
                          style: TextStyle(
                            color: kSubtextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'October 30, 2026',
                    style: TextStyle(
                      color: kSubtextColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // App List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedTab == 0 ? _screenTimeApps.length : _dataApps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final app = _selectedTab == 0 ? _screenTimeApps[index] : _dataApps[index];
                  final List<Color> gradient = app['gradient'] as List<Color>;
                  final appName = app['name'] as String;
                  final usageMinutes = AppLimitService.defaultUsageMinutes[appName] ?? 30;
                  final limitMinutes = _appLimits[appName];
                  final isBlocked = _selectedTab == 0 &&
                      AppLimitService.isLimitReached(usageMinutes, limitMinutes);

                  return InkWell(
                    onTap: () {
                      if (_selectedTab == 0) {
                        if (isBlocked) {
                          _showAppBlockedShieldDialog(
                            context: context,
                            appName: appName,
                            usageMinutes: usageMinutes,
                            limitMinutes: limitMinutes!,
                            gradient: gradient,
                            icon: app['icon'] as IconData,
                          );
                        } else {
                          _showSetLimitSheet(
                            context: context,
                            appName: appName,
                            usageMinutes: usageMinutes,
                            currentLimit: limitMinutes,
                            icon: app['icon'] as IconData,
                            gradient: gradient,
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isBlocked
                              ? Colors.redAccent.withValues(alpha: 0.7)
                              : (limitMinutes != null
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                                  : kBorderColor),
                          width: isBlocked ? 1.5 : 1.0,
                        ),
                        boxShadow: isBlocked
                            ? [
                                BoxShadow(
                                  color: Colors.redAccent.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          // App Icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: gradient.first.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              app['icon'] as IconData,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // App Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        appName,
                                        style: TextStyle(
                                          color: kTextColor,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isBlocked) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                                        ),
                                        child: const Text(
                                          'BLOCKED',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedTab == 0
                                      ? (app['duration'] as String)
                                      : (app['usage'] as String),
                                  style: TextStyle(
                                    color: kSubtextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Trailing Action / Limit Badge
                          if (_selectedTab == 0) ...[
                            if (isBlocked && limitMinutes != null)
                              GestureDetector(
                                onTap: () => _showAppBlockedShieldDialog(
                                  context: context,
                                  appName: appName,
                                  usageMinutes: usageMinutes,
                                  limitMinutes: limitMinutes,
                                  gradient: gradient,
                                  icon: app['icon'] as IconData,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.block_rounded, size: 13, color: Colors.redAccent),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Limit ${AppLimitService.formatMinutes(limitMinutes)} 🛑',
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (limitMinutes != null)
                              GestureDetector(
                                onTap: () => _showSetLimitSheet(
                                  context: context,
                                  appName: appName,
                                  usageMinutes: usageMinutes,
                                  currentLimit: limitMinutes,
                                  icon: app['icon'] as IconData,
                                  gradient: gradient,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.hourglass_bottom_rounded, size: 13, color: Color(0xFF00E5FF)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Limit: ${AppLimitService.formatMinutes(limitMinutes)}',
                                        style: const TextStyle(
                                          color: Color(0xFF00E5FF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () => _showSetLimitSheet(
                                  context: context,
                                  appName: appName,
                                  usageMinutes: usageMinutes,
                                  currentLimit: null,
                                  icon: app['icon'] as IconData,
                                  gradient: gradient,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF030814) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: kBorderColor),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_alarm_rounded, size: 13, color: kSubtextColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Set Limit',
                                        style: TextStyle(
                                          color: kSubtextColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ] else ...[
                            // Data tab trailing info
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF030814) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: kBorderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.data_usage_rounded,
                                    size: 13,
                                    color: Color(0xFF00E5FF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    index == 0 ? '940M' : index == 1 ? '580M' : '220M',
                                    style: TextStyle(
                                      color: kTextColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Interactive App Blocked Lock Shield Dialog
  void _showAppBlockedShieldDialog({
    required BuildContext context,
    required String appName,
    required int usageMinutes,
    required int limitMinutes,
    required List<Color> gradient,
    required IconData icon,
  }) {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF081220) : Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Shield Lock Badge
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  '$appName is Blocked! 🛑',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'Daily Limit Reached: ${AppLimitService.formatMinutes(limitMinutes)}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  'You have used $appName for ${AppLimitService.formatMinutes(usageMinutes)} today. HabbitNova Focus Shield has locked this app to protect your time and goals.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),

                // Motivational quote box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF030814) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF00E5FF), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"Discipline is choosing between what you want now and what you want most."',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showSetLimitSheet(
                        context: context,
                        appName: appName,
                        usageMinutes: usageMinutes,
                        currentLimit: limitMinutes,
                        icon: icon,
                        gradient: gradient,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: const Color(0xFF030814),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Adjust / Remove Limit',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Return to HabitNova Focus',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bottom Sheet to Set or Modify Daily App Usage Limit
  void _showSetLimitSheet({
    required BuildContext context,
    required String appName,
    required int usageMinutes,
    required int? currentLimit,
    required IconData icon,
    required List<Color> gradient,
  }) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedMinutes = currentLimit ?? 60;
    bool isStrict = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isCurrentlyBlocked = AppLimitService.isLimitReached(usageMinutes, selectedMinutes);

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF071728) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: const Color(0xFF0E3D48)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF475569),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header with App Icon
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appName,
                              style: TextStyle(
                                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Screen time today: ${AppLimitService.formatMinutes(usageMinutes)}',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Select Daily Usage Limit:',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Duration chip options: 15m, 30m, 45m, 1h, 1.5h, 2h, 3h
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [15, 30, 45, 60, 90, 120, 180].map((mins) {
                      final isSelected = selectedMinutes == mins;
                      final willBlock = usageMinutes >= mins;

                      return ChoiceChip(
                        label: Text(
                          AppLimitService.formatMinutes(mins),
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF030814)
                                : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: willBlock ? Colors.redAccent : const Color(0xFF00E5FF),
                        backgroundColor: isDark ? const Color(0xFF030814) : const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: isSelected
                              ? (willBlock ? Colors.redAccent : const Color(0xFF00E5FF))
                              : const Color(0xFF0E3D48),
                        ),
                        onSelected: (val) {
                          if (val) {
                            HapticFeedback.selectionClick();
                            setModalState(() => selectedMinutes = mins);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Strict Shield info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrentlyBlocked
                          ? Colors.red.withValues(alpha: 0.12)
                          : const Color(0xFF00E5FF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrentlyBlocked
                            ? Colors.redAccent.withValues(alpha: 0.4)
                            : const Color(0xFF00E5FF).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrentlyBlocked ? Icons.gpp_bad_rounded : Icons.shield_rounded,
                          color: isCurrentlyBlocked ? Colors.redAccent : const Color(0xFF00E5FF),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isCurrentlyBlocked
                                ? 'Status: LIMIT EXCEEDED. $appName will be blocked immediately upon saving.'
                                : 'Status: ACTIVE. $appName will lock once ${AppLimitService.formatMinutes(selectedMinutes)} is reached.',
                            style: TextStyle(
                              color: isCurrentlyBlocked
                                  ? Colors.redAccent
                                  : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Save & Remove buttons
                  Row(
                    children: [
                      if (currentLimit != null) ...[
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () async {
                              final navigator = Navigator.of(bCtx);
                              final messenger = ScaffoldMessenger.of(context);
                              HapticFeedback.mediumImpact();
                              await AppLimitService.removeLimit(appName);
                              await _loadLimits();
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Removed limit for $appName'),
                                  backgroundColor: const Color(0xFF071728),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Remove',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final navigator = Navigator.of(bCtx);
                            final messenger = ScaffoldMessenger.of(context);
                            HapticFeedback.mediumImpact();
                            await AppLimitService.setLimit(
                              appName,
                              selectedMinutes,
                              strictMode: isStrict,
                            );
                            await _loadLimits();
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Daily limit for $appName set to ${AppLimitService.formatMinutes(selectedMinutes)} ✨',
                                ),
                                backgroundColor: const Color(0xFF0E223D),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: const Color(0xFF030814),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Save Limit (${AppLimitService.formatMinutes(selectedMinutes)})',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSegmentTab({
    required int index,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridLine(String label, bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? const Color(0xFF1E2D48).withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }
}
