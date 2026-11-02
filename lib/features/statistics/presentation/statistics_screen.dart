import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synvero/core/services/app_limit_service.dart';

/// Screen displaying real-time daily screen time, live 7-day usage trends,
/// real installed apps with Digital Wellbeing usage limits, and Android Focus Shield app blocking.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with WidgetsBindingObserver {
  int _selectedTab = 0; // 0: Screen, 1: Data
  bool _isLoading = true;
  bool _hasUsagePermission = true;
  bool _hasAccessibilityPermission = true;

  String _totalScreenTimeFormatted = '0 minutes';
  String _totalDataUsageFormatted = '0 MB today';
  List<double> _weeklyHours = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<Map<String, dynamic>> _screenTimeApps = [];
  List<Map<String, dynamic>> _dataApps = [];
  Map<String, int> _appLimits = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLimitService.ensureHandler();
    AppLimitService.blockedAppEventNotifier.addListener(_onAppBlockedFromNative);
    _loadAllStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLimitService.blockedAppEventNotifier.removeListener(_onAppBlockedFromNative);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAllStats();
    }
  }

  void _onAppBlockedFromNative() {
    final event = AppLimitService.blockedAppEventNotifier.value;
    if (event != null && mounted) {
      final appName = event['appName'] as String? ?? 'App';
      final limitMins = event['limitMinutes'] as int? ?? 0;
      final usedMins = event['usedMinutes'] as int? ?? 0;
      final visuals = _getAppVisuals(appName, event['packageName'] as String? ?? '', '');
      _showAppBlockedShieldDialog(
        context: context,
        appName: appName,
        packageName: event['packageName'] as String? ?? '',
        usageMinutes: usedMins,
        limitMinutes: limitMins,
        gradient: visuals['gradient'] as List<Color>,
        icon: visuals['icon'] as IconData,
      );
    }
  }

  Future<void> _loadAllStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasUsage = await AppLimitService.hasUsagePermission();
      final hasAccess = await AppLimitService.hasAccessibilityPermission();

      final screenStats = await AppLimitService.getLiveScreenTimeStats();
      final dataStats = await AppLimitService.getLiveDataUsageStats();

      // Process real screen time apps
      final rawScreenApps = (screenStats['apps'] as List?) ?? [];
      final List<Map<String, dynamic>> screenApps = [];
      for (final a in rawScreenApps) {
        if (a is Map) {
          final pkg = a['packageName'] as String? ?? '';
          final name = a['appName'] as String? ?? pkg;
          final cat = a['category'] as String? ?? 'General';
          final duration = a['durationFormatted'] as String? ?? '0 min';
          final usageMins = (a['usageMinutes'] as num?)?.toInt() ?? 0;
          final visuals = _getAppVisuals(name, pkg, cat);

          screenApps.add({
            'packageName': pkg,
            'name': name,
            'duration': duration,
            'category': cat,
            'usageMinutes': usageMins,
            'icon': visuals['icon'],
            'gradient': visuals['gradient'],
          });
        }
      }

      // Process real data apps
      final rawDataApps = (dataStats['apps'] as List?) ?? [];
      final List<Map<String, dynamic>> dataApps = [];
      for (final d in rawDataApps) {
        if (d is Map) {
          final pkg = d['packageName'] as String? ?? '';
          final name = d['appName'] as String? ?? pkg;
          final cat = d['category'] as String? ?? 'General';
          final usageStr = d['usageFormatted'] as String? ?? '0 MB';
          final bytes = (d['bytes'] as num?)?.toInt() ?? 0;
          final visuals = _getAppVisuals(name, pkg, cat);

          dataApps.add({
            'packageName': pkg,
            'name': name,
            'usage': usageStr,
            'bytes': bytes,
            'category': cat,
            'icon': visuals['icon'],
            'gradient': visuals['gradient'],
          });
        }
      }

      // Load active app limits
      final allKeys = <String>{};
      for (final a in screenApps) {
        allKeys.add(a['name'] as String);
        allKeys.add(a['packageName'] as String);
      }
      final limits = await AppLimitService.loadAllLimits(allKeys.toList());

      // Weekly hours
      List<double> weeklyH = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
      if (screenStats['weeklyHours'] is List) {
        weeklyH = (screenStats['weeklyHours'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
        while (weeklyH.length < 7) {
          weeklyH.add(0.0);
        }
      }

      List<String> weekD = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      if (screenStats['weekDays'] is List && (screenStats['weekDays'] as List).isNotEmpty) {
        weekD = (screenStats['weekDays'] as List).map((e) => e.toString()).toList();
      }

      if (mounted) {
        setState(() {
          _hasUsagePermission = hasUsage;
          _hasAccessibilityPermission = hasAccess;
          _totalScreenTimeFormatted = screenStats['totalFormatted'] as String? ?? '0 minutes';
          _totalDataUsageFormatted = dataStats['totalFormatted'] as String? ?? '0 MB today';
          _weeklyHours = weeklyH;
          _weekDays = weekD;
          _screenTimeApps = screenApps;
          _dataApps = dataApps;
          _appLimits = limits;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('StatisticsScreen._loadAllStats error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getAppVisuals(String appName, String packageName, String category) {
    final low = (appName + packageName).toLowerCase();
    if (low.contains('youtube')) {
      return {
        'icon': Icons.play_arrow_rounded,
        'gradient': [const Color(0xFFFF0000), const Color(0xFFCC0000)],
      };
    }
    if (low.contains('instagram')) {
      return {
        'icon': Icons.camera_alt_rounded,
        'gradient': [const Color(0xFF833AB4), const Color(0xFFFD1D1D), const Color(0xFFFCB045)],
      };
    }
    if (low.contains('whatsapp')) {
      return {
        'icon': Icons.chat_rounded,
        'gradient': [const Color(0xFF25D366), const Color(0xFF128C7E)],
      };
    }
    if (low.contains('chrome') || low.contains('browser')) {
      return {
        'icon': Icons.public_rounded,
        'gradient': [const Color(0xFF4285F4), const Color(0xFF0F9D58)],
      };
    }
    if (low.contains('telegram')) {
      return {
        'icon': Icons.send_rounded,
        'gradient': [const Color(0xFF0088CC), const Color(0xFF005580)],
      };
    }
    if (low.contains('snapchat')) {
      return {
        'icon': Icons.flash_on_rounded,
        'gradient': [const Color(0xFFFFD600), const Color(0xFFE5B800)],
      };
    }
    if (low.contains('facebook')) {
      return {
        'icon': Icons.facebook_rounded,
        'gradient': [const Color(0xFF1877F2), const Color(0xFF0D5BB5)],
      };
    }
    if (low.contains('spotify') || low.contains('music')) {
      return {
        'icon': Icons.music_note_rounded,
        'gradient': [const Color(0xFF1DB954), const Color(0xFF191414)],
      };
    }
    if (low.contains('netflix') || low.contains('prime') || low.contains('hotstar')) {
      return {
        'icon': Icons.movie_rounded,
        'gradient': [const Color(0xFFE50914), const Color(0xFFB81D24)],
      };
    }
    if (low.contains('habit') || low.contains('synvero') || low.contains('nova')) {
      return {
        'icon': Icons.eco_rounded,
        'gradient': [const Color(0xFF00E5FF), const Color(0xFF10B981)],
      };
    }
    if (category.contains('Gaming') || low.contains('game')) {
      return {
        'icon': Icons.sports_esports_rounded,
        'gradient': [const Color(0xFF9333EA), const Color(0xFF6B21A8)],
      };
    }
    if (category.contains('Communication')) {
      return {
        'icon': Icons.forum_rounded,
        'gradient': [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
      };
    }
    return {
      'icon': Icons.apps_rounded,
      'gradient': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
    };
  }

  int? _findLimitForApp(String name, String pkg) {
    if (_appLimits.containsKey(pkg)) return _appLimits[pkg];
    if (_appLimits.containsKey(name)) return _appLimits[name];
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kBgColor = isDark ? const Color(0xFF030814) : const Color(0xFFF8FAFC);
    final kCardBg = isDark ? const Color(0xFF071728) : Colors.white;
    final kBorderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
    final kTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final kSubtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final now = DateTime.now();
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final todayDateStr = '${monthNames[now.month - 1]} ${now.day}, ${now.year}';

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
          'Statistics & Usage',
          style: TextStyle(
            color: kTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: const Color(0xFF00E5FF), size: 22),
            tooltip: 'Refresh real-time stats',
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadAllStats();
            },
          ),
        ],
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllStats,
          color: const Color(0xFF00E5FF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Permission Warning 1: Usage Access
                if (!_hasUsagePermission) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF59E0B).withValues(alpha: 0.18),
                          const Color(0xFFD97706).withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.security_update_warning_rounded, color: Color(0xFFF59E0B), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Usage Access Required (परमिशन आवश्यक)',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF92400E),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'तुमच्या फोनचा रिअल-टाइम स्क्रीन टाइम आणि ॲप वापर अचूक मोजण्यासाठी Android ची "Usage Access" परमिशन द्या.',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF78350F),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await AppLimitService.requestUsagePermission();
                            },
                            icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                            label: const Text('Grant Usage Permission (परमिशन द्या)', style: TextStyle(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: const Color(0xFF030814),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Permission Warning 2: Accessibility Focus Blocker
                if (_hasUsagePermission && !_hasAccessibilityPermission) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          const Color(0xFF0284C7).withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.45)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_rounded, color: Color(0xFF00E5FF), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'App Blocker Shield (ॲप लॉक सुरू करा)',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF075985),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ॲपची लिमिट संपल्यानंतर ते फोनवर परत उघडू नये यासाठी HabbitNova Accessibility सर्विस चालू करा.',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0369A1),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await AppLimitService.requestAccessibilityPermission();
                            },
                            icon: const Icon(Icons.lock_person_rounded, size: 18),
                            label: const Text('Turn ON Focus Shield (लॉक सुरू करा)', style: TextStyle(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF),
                              foregroundColor: const Color(0xFF030814),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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
                        label: 'Screen Time',
                        icon: Icons.smartphone_rounded,
                        isDark: isDark,
                      ),
                      _buildSegmentTab(
                        index: 1,
                        label: 'Data Usage',
                        icon: Icons.public_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Hero Usage Summary Card (Real-time live values)
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
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                        ),
                        child: Icon(
                          _selectedTab == 0 ? Icons.phone_android_rounded : Icons.wifi_rounded,
                          color: const Color(0xFF00E5FF),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _selectedTab == 0 ? 'Today\'s Screen Time' : 'Daily Data Usage',
                                  style: TextStyle(
                                    color: kSubtextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedTab == 0 ? _totalScreenTimeFormatted : _totalDataUsageFormatted,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Weekly Screen Time Trend',
                            style: TextStyle(
                              color: kTextColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '7 Days',
                            style: TextStyle(
                              color: const Color(0xFF00E5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildWeeklyBarChart(isDark),
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
                          _selectedTab == 0 ? 'Apps Screen Time' : 'Data Consumption by Apps',
                          style: TextStyle(
                            color: kTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_selectedTab == 0)
                          Text(
                            'Tap any app to set daily limit & lock shield 🛑',
                            style: TextStyle(
                              color: kSubtextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      todayDateStr,
                      style: TextStyle(
                        color: kSubtextColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // List of real apps
                if (_isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    ),
                  ),
                ] else if (_selectedTab == 0 && _screenTimeApps.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.hourglass_empty_rounded, size: 40, color: Color(0xFF00E5FF)),
                        const SizedBox(height: 12),
                        Text(
                          'No screen time recorded yet today',
                          style: TextStyle(color: kTextColor, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use your phone or grant Usage Access to track stats',
                          style: TextStyle(color: kSubtextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ] else if (_selectedTab == 1 && _dataApps.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFF00E5FF)),
                        const SizedBox(height: 12),
                        Text(
                          'No network data recorded yet today',
                          style: TextStyle(color: kTextColor, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Connect to WiFi or Mobile Data to view per-app stats',
                          style: TextStyle(color: kSubtextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedTab == 0 ? _screenTimeApps.length : _dataApps.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final app = _selectedTab == 0 ? _screenTimeApps[index] : _dataApps[index];
                      final List<Color> gradient = app['gradient'] as List<Color>;
                      final appName = app['name'] as String;
                      final pkg = app['packageName'] as String? ?? '';
                      final usageMinutes = (app['usageMinutes'] as int?) ?? 0;
                      final limitMinutes = _findLimitForApp(appName, pkg);
                      final isBlocked = _selectedTab == 0 &&
                          AppLimitService.isLimitReached(usageMinutes, limitMinutes);

                      return InkWell(
                        onTap: () {
                          if (_selectedTab == 0) {
                            if (isBlocked) {
                              _showAppBlockedShieldDialog(
                                context: context,
                                appName: appName,
                                packageName: pkg,
                                usageMinutes: usageMinutes,
                                limitMinutes: limitMinutes!,
                                gradient: gradient,
                                icon: app['icon'] as IconData,
                              );
                            } else {
                              _showSetLimitSheet(
                                context: context,
                                appName: appName,
                                packageName: pkg,
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
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                                      : kBorderColor),
                              width: isBlocked ? 1.5 : 1.0,
                            ),
                            boxShadow: isBlocked
                                ? [
                                    BoxShadow(
                                      color: Colors.redAccent.withValues(alpha: 0.15),
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
                                              'LOCKED',
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
                                      packageName: pkg,
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
                                          const Icon(Icons.lock_rounded, size: 13, color: Colors.redAccent),
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
                                      packageName: pkg,
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
                                      packageName: pkg,
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
                                        app['usage'] as String? ?? '0 MB',
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
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyBarChart(bool isDark) {
    double maxH = 1.0;
    for (final h in _weeklyHours) {
      if (h > maxH) maxH = h;
    }
    final topCeil = (maxH < 4.0) ? 4.0 : (maxH.ceilToDouble());

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGridLine('${topCeil.toInt()}h', isDark),
                    _buildGridLine('${(topCeil * 0.75).toStringAsFixed(1)}h', isDark),
                    _buildGridLine('${(topCeil * 0.5).toStringAsFixed(1)}h', isDark),
                    _buildGridLine('${(topCeil * 0.25).toStringAsFixed(1)}h', isDark),
                    _buildGridLine('0h', isDark),
                  ],
                ),
              ),
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
                    final isToday = i == (_weeklyHours.length - 1);
                    final heightRatio = (h / topCeil).clamp(0.06, 1.0);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (h > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${h}h',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                color: isToday ? const Color(0xFF00E5FF) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        Container(
                          width: 26,
                          height: 130 * heightRatio,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: isToday
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF00E5FF),
                                      Color(0xFF0284C7),
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
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
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
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_weekDays.length, (i) {
              final isToday = i == (_weekDays.length - 1);
              return SizedBox(
                width: 28,
                child: Center(
                  child: Text(
                    _weekDays[i],
                    style: TextStyle(
                      color: isToday
                          ? const Color(0xFF00E5FF)
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  void _showAppBlockedShieldDialog({
    required BuildContext context,
    required String appName,
    required String packageName,
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
                const SizedBox(height: 8),
                Text(
                  'तुम्ही आज $appName चा वापर ${AppLimitService.formatMinutes(usageMinutes)} केला आहे. Focus Shield ने हे ॲप आजसाठी लॉक केले आहे जेणेकरून तुमचे ध्येय पूर्ण होईल.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showSetLimitSheet(
                        context: context,
                        appName: appName,
                        packageName: packageName,
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
                    'Stay Focused (बंद करा)',
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

  void _showSetLimitSheet({
    required BuildContext context,
    required String appName,
    required String packageName,
    required int usageMinutes,
    required int? currentLimit,
    required IconData icon,
    required List<Color> gradient,
  }) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedMinutes = currentLimit ?? 60;

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
                          isCurrentlyBlocked ? Icons.lock_rounded : Icons.shield_rounded,
                          color: isCurrentlyBlocked ? Colors.redAccent : const Color(0xFF00E5FF),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isCurrentlyBlocked
                                ? 'Status: LIMIT REACHED. $appName will be blocked immediately.'
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
                              await AppLimitService.removeLimit(appName, packageName: packageName);
                              await _loadAllStats();
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
                              packageName: packageName,
                            );
                            await _loadAllStats();
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Daily limit for $appName set to ${AppLimitService.formatMinutes(selectedMinutes)} ✨ (Blocked when reached)',
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
          width: 30,
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
