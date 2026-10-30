import 'package:flutter/material.dart';

/// Screen displaying daily screen time, weekly usage trends, and most used apps.
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
                          // Background Grid Lines
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildGridLine('11h', isDark),
                              _buildGridLine('8h', isDark),
                              _buildGridLine('5h', isDark),
                              _buildGridLine('3h', isDark),
                              _buildGridLine('0s', isDark),
                            ],
                          ),

                          // 7 Weekly Bars
                          Padding(
                            padding: const EdgeInsets.only(left: 36, right: 12, bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(7, (index) {
                                final isCurrentDay = index == 4; // Friday in current week
                                final heightPct = (_weeklyHours[index] / 11.0).clamp(0.08, 1.0);

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      width: 28,
                                      height: 140 * heightPct,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: isCurrentDay
                                            ? const LinearGradient(
                                                colors: [Color(0xFF00E5FF), Color(0xFF10B981)],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              )
                                            : LinearGradient(
                                                colors: isDark
                                                    ? [
                                                        const Color(0xFF1E2D48),
                                                        const Color(0xFF152238),
                                                      ]
                                                    : [
                                                        const Color(0xFFCBD5E1),
                                                        const Color(0xFFE2E8F0),
                                                      ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                        boxShadow: isCurrentDay
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
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

                    // Day labels row
                    Padding(
                      padding: const EdgeInsets.only(left: 36, right: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          final isCurrentDay = index == 4;
                          return SizedBox(
                            width: 28,
                            child: Text(
                              _weekDays[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isCurrentDay
                                    ? const Color(0xFF00E5FF)
                                    : kSubtextColor,
                                fontSize: 11,
                                fontWeight: isCurrentDay ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 18),
                    Divider(color: kBorderColor, height: 1),
                    const SizedBox(height: 12),

                    // Date Navigator: < Oct 26 - Nov 1 >
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
                          _weekOffset == 0 ? 'Oct 26 - Nov 1' : 'Past Week (${_weekOffset.abs()}w ago)',
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

              // Section: Most Used Apps
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTab == 0 ? 'Most used apps' : 'Data consumption by apps',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorderColor),
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
                              Text(
                                app['name'] as String,
                                style: TextStyle(
                                  color: kTextColor,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
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

                        // Trailing info/timer icon
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
                              Icon(
                                _selectedTab == 0 ? Icons.timer_outlined : Icons.data_usage_rounded,
                                size: 13,
                                color: const Color(0xFF00E5FF),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _selectedTab == 0
                                    ? (index == 0 ? '1h 30m' : index == 1 ? '1h 1m' : '45m')
                                    : (index == 0 ? '940M' : index == 1 ? '580M' : '220M'),
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

