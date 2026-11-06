import 'dart:async';
import 'package:flutter/material.dart';
import 'package:synvero/core/widgets/ambient_mesh_background.dart';
import 'package:flutter/services.dart';
import 'package:synvero/core/services/app_limit_service.dart';

/// Screen displaying real-time daily screen time, exact second-by-second updates,
/// day-by-day historical phone usage breakdown, real installed apps with Digital Wellbeing limits,
/// and Android Focus Shield app blocking with 100% responsive zero-overflow UI.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: Screen Time, 1: Data Usage
  int _selectedDayIndex = 6; // 0: 6 days ago ... 6: Today
  bool _isLoading = true;
  bool _hasUsagePermission = true;
  bool _hasAccessibilityPermission = true;

  // Real-time second-by-second ticking
  Timer? _syncTimer;
  int _liveTodayScreenTimeMs = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _totalScreenTimeFormatted = '0m';
  String _totalDataUsageFormatted = '0 MB today';
  List<double> _weeklyHours = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Day-by-day full history breakdown
  List<Map<String, dynamic>> _dailyHistory = [];
  Map<String, dynamic>? _customDateRecord;
  bool _isCustomDateSelected = false;

  List<Map<String, dynamic>> _screenTimeApps = [];
  List<Map<String, dynamic>> _dataApps = [];
  Map<String, int> _appLimits = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLimitService.ensureHandler();
    AppLimitService.blockedAppEventNotifier.addListener(_onAppBlockedFromNative);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadAllStats();
    _startPeriodicSync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _pulseController.dispose();
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

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    // Smooth periodic background sync with Android UsageStatsManager
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted) return;
      if (_selectedTab == 0 && _selectedDayIndex == 6 && !_isCustomDateSelected && !_isLoading && _hasUsagePermission) {
        _silentBackgroundSync();
      }
    });
  }

  Future<void> _silentBackgroundSync() async {
    if (!mounted || _isLoading || !_hasUsagePermission) return;
    try {
      final screenStats = await AppLimitService.getLiveScreenTimeStats();
      if (!mounted) return;

      final ms = (screenStats['totalScreenTimeMs'] as num?)?.toInt() ?? _liveTodayScreenTimeMs;
      final rawDaily = (screenStats['dailyHistory'] as List?) ?? [];
      final List<Map<String, dynamic>> dailyHist = [];
      for (final item in rawDaily) {
        if (item is Map) {
          dailyHist.add(Map<String, dynamic>.from(item));
        }
      }

      final rawScreenApps = (screenStats['apps'] as List?) ?? [];
      final List<Map<String, dynamic>> screenApps = [];
      for (final a in rawScreenApps) {
        if (a is Map) {
          final pkg = a['packageName'] as String? ?? '';
          final name = a['appName'] as String? ?? pkg;
          final cat = a['category'] as String? ?? 'Apps & Tools';
          final duration = a['durationFormatted'] as String? ?? '0m';
          final usageMins = (a['usageMinutes'] as num?)?.toInt() ?? 0;
          final usageMs = (a['usageTimeMs'] as num?)?.toInt() ?? 0;
          final visuals = _getAppVisuals(name, pkg, cat);

          screenApps.add({
            'packageName': pkg,
            'name': name,
            'duration': duration,
            'category': cat,
            'usageMinutes': usageMins,
            'usageTimeMs': usageMs,
            'icon': visuals['icon'],
            'gradient': visuals['gradient'],
          });
        }
      }

      setState(() {
        _liveTodayScreenTimeMs = ms;
        if (_selectedDayIndex == 6 && !_isCustomDateSelected) {
          _totalScreenTimeFormatted = AppLimitService.formatExactDuration(ms);
          _screenTimeApps = screenApps;
        }
        if (dailyHist.isNotEmpty) {
          _dailyHistory = dailyHist;
        }
      });
    } catch (_) {}
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

      final totalMs = (screenStats['totalScreenTimeMs'] as num?)?.toInt() ?? 0;

      // Process real screen time apps
      final rawScreenApps = (screenStats['apps'] as List?) ?? [];
      final List<Map<String, dynamic>> screenApps = [];
      for (final a in rawScreenApps) {
        if (a is Map) {
          final pkg = a['packageName'] as String? ?? '';
          final name = a['appName'] as String? ?? pkg;
          final cat = a['category'] as String? ?? 'Apps & Tools';
          final duration = a['durationFormatted'] as String? ?? '0m';
          final usageMins = (a['usageMinutes'] as num?)?.toInt() ?? 0;
          final usageMs = (a['usageTimeMs'] as num?)?.toInt() ?? 0;
          final visuals = _getAppVisuals(name, pkg, cat);

          screenApps.add({
            'packageName': pkg,
            'name': name,
            'duration': duration,
            'category': cat,
            'usageMinutes': usageMins,
            'usageTimeMs': usageMs,
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
          final cat = d['category'] as String? ?? 'Apps & Tools';
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

      // Process daily history list
      final rawDaily = (screenStats['dailyHistory'] as List?) ?? [];
      final List<Map<String, dynamic>> dailyHist = [];
      for (final item in rawDaily) {
        if (item is Map) {
          dailyHist.add(Map<String, dynamic>.from(item));
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
          _liveTodayScreenTimeMs = totalMs;
          _totalScreenTimeFormatted = AppLimitService.formatExactDuration(totalMs);
          _totalDataUsageFormatted = dataStats['totalFormatted'] as String? ?? '0 MB today';
          _weeklyHours = weeklyH;
          _weekDays = weekD;
          _dailyHistory = dailyHist;
          _screenTimeApps = screenApps;
          _dataApps = dataApps;
          _appLimits = limits;
          _selectedDayIndex = 6; // Default to Today
          _isCustomDateSelected = false;
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

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
      helpText: 'SELECT DATE TO VIEW PHONE USAGE',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00E5FF),
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: const Color(0xFF00E5FF),
              onPrimary: const Color(0xFF030814),
              surface: isDark ? const Color(0xFF071728) : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _isLoading = true);

      final startOfDay = DateTime(picked.year, picked.month, picked.day).millisecondsSinceEpoch;
      final endOfDay = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999).millisecondsSinceEpoch;

      final res = await AppLimitService.getScreenTimeForCustomDate(startOfDay, endOfDay);
      final rawApps = (res['apps'] as List?) ?? [];
      final List<Map<String, dynamic>> customApps = [];
      for (final a in rawApps) {
        if (a is Map) {
          final pkg = a['packageName'] as String? ?? '';
          final name = a['appName'] as String? ?? pkg;
          final cat = a['category'] as String? ?? 'Apps & Tools';
          final duration = a['durationFormatted'] as String? ?? '0m';
          final usageMins = (a['usageMinutes'] as num?)?.toInt() ?? 0;
          final usageMs = (a['usageTimeMs'] as num?)?.toInt() ?? 0;
          final visuals = _getAppVisuals(name, pkg, cat);

          customApps.add({
            'packageName': pkg,
            'name': name,
            'duration': duration,
            'category': cat,
            'usageMinutes': usageMins,
            'usageTimeMs': usageMs,
            'icon': visuals['icon'],
            'gradient': visuals['gradient'],
          });
        }
      }

      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final fullDate = '${picked.day} ${monthNames[picked.month - 1]} ${picked.year}';
      final totalMs = (res['totalScreenTimeMs'] as num?)?.toInt() ?? 0;

      if (mounted) {
        setState(() {
          _isCustomDateSelected = true;
          _customDateRecord = {
            'fullDate': fullDate,
            'totalScreenTimeMs': totalMs,
            'totalFormatted': AppLimitService.formatExactDuration(totalMs),
            'apps': customApps,
          };
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

  // Resolves the currently active list of apps based on day selection
  List<Map<String, dynamic>> _getDisplayedScreenApps() {
    if (_isCustomDateSelected && _customDateRecord != null) {
      final apps = _customDateRecord!['apps'];
      if (apps is List) return List<Map<String, dynamic>>.from(apps);
      return [];
    }
    if (_selectedDayIndex == 6) {
      return _screenTimeApps;
    }
    if (_selectedDayIndex >= 0 && _selectedDayIndex < _dailyHistory.length) {
      final dayItem = _dailyHistory[_selectedDayIndex];
      final apps = dayItem['apps'];
      if (apps is List) {
        final List<Map<String, dynamic>> list = [];
        for (final a in apps) {
          if (a is Map) {
            final pkg = a['packageName'] as String? ?? '';
            final name = a['appName'] as String? ?? pkg;
            final cat = a['category'] as String? ?? 'Apps & Tools';
            final duration = a['durationFormatted'] as String? ?? '0m';
            final usageMins = (a['usageMinutes'] as num?)?.toInt() ?? 0;
            final usageMs = (a['usageTimeMs'] as num?)?.toInt() ?? 0;
            final visuals = _getAppVisuals(name, pkg, cat);

            list.add({
              'packageName': pkg,
              'name': name,
              'duration': duration,
              'category': cat,
              'usageMinutes': usageMins,
              'usageTimeMs': usageMs,
              'icon': visuals['icon'],
              'gradient': visuals['gradient'],
            });
          }
        }
        return list;
      }
    }
    return _screenTimeApps;
  }

  // Resolves currently displayed total screen time formatted string
  String _getDisplayedTotalScreenTime() {
    if (_selectedTab == 1) return _totalDataUsageFormatted;
    if (_isCustomDateSelected && _customDateRecord != null) {
      return _customDateRecord!['totalFormatted'] as String? ?? '0m';
    }
    if (_selectedDayIndex == 6) {
      return _totalScreenTimeFormatted;
    }
    if (_selectedDayIndex >= 0 && _selectedDayIndex < _dailyHistory.length) {
      final dayItem = _dailyHistory[_selectedDayIndex];
      return dayItem['totalFormatted'] as String? ?? '0m';
    }
    return _totalScreenTimeFormatted;
  }

  // Resolves currently displayed day title
  String _getDisplayedDayTitle() {
    if (_selectedTab == 1) return "Today's Mobile & WiFi Data";
    if (_isCustomDateSelected && _customDateRecord != null) {
      return '${_customDateRecord!['fullDate']} Screen Time';
    }
    if (_selectedDayIndex == 6) {
      return "Today's Live Screen Time";
    }
    if (_selectedDayIndex == 5) {
      return "Yesterday's Screen Time";
    }
    if (_selectedDayIndex >= 0 && _selectedDayIndex < _dailyHistory.length) {
      final dayItem = _dailyHistory[_selectedDayIndex];
      return "${dayItem['fullDate'] ?? dayItem['dayName']} Screen Time";
    }
    return "Screen Time";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kBgColor = isDark ? const Color(0xFF030814) : const Color(0xFFF8FAFC);
    final kCardBg = isDark ? const Color(0xFF071728) : Colors.white;
    final kBorderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
    final kTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final kSubtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final displayedScreenApps = _getDisplayedScreenApps();
    final isViewingToday = (_selectedDayIndex == 6 && !_isCustomDateSelected);

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
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF00E5FF), size: 22),
            tooltip: 'Pick date to view phone usage history',
            onPressed: _pickCustomDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF), size: 22),
            tooltip: 'Refresh real-time stats',
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadAllStats();
            },
          ),
        ],
        centerTitle: false,
      ),
      body: AmbientMeshBackground(
        child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllStats,
          color: const Color(0xFF00E5FF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Permission Warning 1: Usage Access
                if (!_hasUsagePermission) ...[
                  _buildPermissionBanner(
                    title: 'Usage Access Required (परमिशन आवश्यक)',
                    description: 'तुमच्या फोनचा रिअल-टाइम स्क्रीन टाइम आणि ॲप वापर सेकंदा-सेकंदाला अचूक मोजण्यासाठी Android ची "Usage Access" परमिशन द्या.',
                    buttonText: 'Grant Usage Permission (परमिशन द्या)',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.security_update_warning_rounded,
                    isDark: isDark,
                    onTap: () async => await AppLimitService.requestUsagePermission(),
                  ),
                ],

                // Permission Warning 2: Accessibility Focus Blocker
                if (_hasUsagePermission && !_hasAccessibilityPermission) ...[
                  _buildPermissionBanner(
                    title: 'App Blocker Shield (ॲप लॉक सुरू करा)',
                    description: 'ॲपची लिमिट संपल्यानंतर ते फोनवर परत उघडू नये यासाठी HabbitNova Accessibility सर्विस चालू करा.',
                    buttonText: 'Turn ON Focus Shield (लॉक सुरू करा)',
                    color: const Color(0xFF00E5FF),
                    icon: Icons.shield_rounded,
                    isDark: isDark,
                    onTap: () async => await AppLimitService.requestAccessibilityPermission(),
                  ),
                ],

                // Segmented Switcher: [📱 Screen Time] [🌐 Data Usage]
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

                const SizedBox(height: 16),

                // Day Selection Pills Carousel (Today, Yesterday, Mon, Tue, etc.)
                if (_selectedTab == 0) ...[
                  _buildDaySelectorCarousel(isDark),
                  const SizedBox(height: 16),
                ],

                // Hero Screen Time / Data Usage Card
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
                                Flexible(
                                  child: Text(
                                    _getDisplayedDayTitle(),
                                    style: TextStyle(
                                      color: kSubtextColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (isViewingToday && _selectedTab == 0) ...[
                                  FadeTransition(
                                    opacity: _pulseAnimation,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6)),
                                      ),
                                      child: const Text(
                                        'LIVE USAGE',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else if (_selectedTab == 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'RECORDED',
                                      style: TextStyle(
                                        color: Color(0xFF00E5FF),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getDisplayedTotalScreenTime(),
                              style: TextStyle(
                                color: kTextColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (_selectedTab == 0) ...[
                              const SizedBox(height: 3),
                              Text(
                                isViewingToday
                                    ? '⚡ Synced with Android Digital Wellbeing'
                                    : '📊 Total phone usage recorded for this day',
                                style: TextStyle(
                                  color: isViewingToday ? const Color(0xFF10B981) : kSubtextColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Weekly Bar Chart Container (Interactive: Tap any bar to inspect day!)
                if (_selectedTab == 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
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
                              '7-Day Phone Usage Trend',
                              style: TextStyle(
                                color: kTextColor,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Tap any day 👆',
                              style: TextStyle(
                                color: const Color(0xFF00E5FF),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildInteractiveWeeklyBarChart(isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Section: App breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedTab == 0
                                ? (isViewingToday
                                    ? "Today's App Screen Time"
                                    : "Apps on ${_getDisplayedDayTitle().replaceAll(' Screen Time', '')}")
                                : 'Data Consumption by Apps',
                            style: TextStyle(
                              color: kTextColor,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_selectedTab == 0 && isViewingToday)
                            Text(
                              'Tap any app to set daily limit & lock shield 🛑',
                              style: TextStyle(
                                color: kSubtextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else if (_selectedTab == 0)
                            Text(
                              'Exact breakdown of apps used on this date',
                              style: TextStyle(
                                color: kSubtextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_selectedTab == 0 && !_isCustomDateSelected && _selectedDayIndex < _dailyHistory.length)
                      Text(
                        _dailyHistory[_selectedDayIndex]['dateStr'] as String? ?? '',
                        style: TextStyle(
                          color: kSubtextColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // List of apps
                if (_isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    ),
                  ),
                ] else if (_selectedTab == 0 && displayedScreenApps.isEmpty) ...[
                  _buildEmptyStateCard(
                    icon: Icons.hourglass_empty_rounded,
                    title: 'No screen time recorded for this day',
                    subtitle: isViewingToday
                        ? 'Use your phone or grant Usage Access to track stats'
                        : 'No active phone usage was recorded on this date',
                    kCardBg: kCardBg,
                    kBorderColor: kBorderColor,
                    kTextColor: kTextColor,
                    kSubtextColor: kSubtextColor,
                  ),
                ] else if (_selectedTab == 1 && _dataApps.isEmpty) ...[
                  _buildEmptyStateCard(
                    icon: Icons.wifi_off_rounded,
                    title: 'No network data recorded yet today',
                    subtitle: 'Connect to WiFi or Mobile Data to view per-app stats',
                    kCardBg: kCardBg,
                    kBorderColor: kBorderColor,
                    kTextColor: kTextColor,
                    kSubtextColor: kSubtextColor,
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedTab == 0 ? displayedScreenApps.length : _dataApps.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final app = _selectedTab == 0 ? displayedScreenApps[index] : _dataApps[index];
                      final List<Color> gradient = app['gradient'] as List<Color>;
                      final appName = app['name'] as String;
                      final pkg = app['packageName'] as String? ?? '';
                      final usageMinutes = (app['usageMinutes'] as int?) ?? 0;
                      final usageMs = (app['usageTimeMs'] as int?) ?? 0;
                      final limitMinutes = _findLimitForApp(appName, pkg);
                      final isBlocked = _selectedTab == 0 &&
                          isViewingToday &&
                          AppLimitService.isLimitReached(usageMinutes, limitMinutes);

                      return InkWell(
                        onTap: () {
                          if (_selectedTab == 0 && isViewingToday) {
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
                                  : (limitMinutes != null && isViewingToday
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

                              // App Details (Flexible & overflow-safe)
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
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            app['category'] as String,
                                            style: TextStyle(
                                              color: kSubtextColor,
                                              fontSize: 11.5,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (_selectedTab == 0 && limitMinutes != null && isViewingToday) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '• Limit: ${AppLimitService.formatMinutes(limitMinutes)}',
                                            style: TextStyle(
                                              color: isBlocked ? Colors.redAccent : const Color(0xFF00E5FF),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Usage time / Data consumption
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _selectedTab == 0
                                        ? (app['duration'] as String)
                                        : (app['usage'] as String),
                                    style: TextStyle(
                                      color: isBlocked ? Colors.redAccent : kTextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (_selectedTab == 0 && usageMs > 0 && _liveTodayScreenTimeMs > 0 && isViewingToday) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${((usageMs / _liveTodayScreenTimeMs) * 100).clamp(1, 100).toInt()}% of phone',
                                      style: TextStyle(
                                        color: const Color(0xFF00E5FF),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
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
    ),
  );
  }

  // Horizontally scrollable day selector carousel with haptic feedback
  Widget _buildDaySelectorCarousel(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // 7 days pills (6 days ago to Today)
          ...List.generate(_dailyHistory.length, (i) {
            final dayData = _dailyHistory[i];
            final isToday = (i == 6);
            final isSelected = (!_isCustomDateSelected && _selectedDayIndex == i);
            final dayName = isToday ? 'Today' : (i == 5 ? 'Yesterday' : (dayData['dayName'] as String? ?? 'Day'));
            final formatted = dayData['totalFormatted'] as String? ?? '0m';

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isCustomDateSelected = false;
                    _selectedDayIndex = i;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.22 : 0.15)
                        : (isDark ? const Color(0xFF071728) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00E5FF) : (isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0)),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isToday) ...[
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                          Text(
                            dayName,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF00E5FF)
                                  : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isToday ? _totalScreenTimeFormatted : formatted,
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF00E5FF))
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Custom Date Picker chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: _pickCustomDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isCustomDateSelected
                      ? const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.22 : 0.15)
                      : (isDark ? const Color(0xFF071728) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isCustomDateSelected ? const Color(0xFF00E5FF) : (isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0)),
                    width: _isCustomDateSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 6),
                    Text(
                      _isCustomDateSelected && _customDateRecord != null
                          ? (_customDateRecord!['fullDate'] as String? ?? 'Picked')
                          : 'Custom Date',
                      style: TextStyle(
                        color: _isCustomDateSelected
                            ? const Color(0xFF00E5FF)
                            : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Interactive 7-day bar chart with LayoutBuilder and zero-overflow flexible columns
  Widget _buildInteractiveWeeklyBarChart(bool isDark) {
    double maxH = 1.0;
    for (final h in _weeklyHours) {
      if (h > maxH) maxH = h;
    }
    final topCeil = (maxH < 4.0) ? 4.0 : (maxH.ceilToDouble());

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            SizedBox(
              height: 175,
              child: Stack(
                children: [
                  // Horizontal Grid Lines
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

                  // Interactive Bars Row
                  Positioned(
                    left: 36,
                    right: 4,
                    top: 4,
                    bottom: 6,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(_weeklyHours.length, (i) {
                        final h = _weeklyHours[i];
                        final isSelected = (!_isCustomDateSelected && _selectedDayIndex == i);
                        final heightRatio = (h / topCeil).clamp(0.06, 1.0);

                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _isCustomDateSelected = false;
                                _selectedDayIndex = i;
                              });
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (h > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${h}h',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                          color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 24,
                                  height: 120 * heightRatio,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: isSelected
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
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                    border: isSelected
                                        ? Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Weekday labels (Overflow-safe Expanded)
            Padding(
              padding: const EdgeInsets.only(left: 36, right: 4),
              child: Row(
                children: List.generate(_weekDays.length, (i) {
                  final isSelected = (!_isCustomDateSelected && _selectedDayIndex == i);
                  final isToday = (i == _weekDays.length - 1);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isCustomDateSelected = false;
                          _selectedDayIndex = i;
                        });
                      },
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isToday ? 'Today' : _weekDays[i],
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF00E5FF)
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color kCardBg,
    required Color kBorderColor,
    required Color kTextColor,
    required Color kSubtextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFF00E5FF)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextColor, fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: kSubtextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner({
    required String title,
    required String description,
    required String buttonText,
    required Color color,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.settings_suggest_rounded, size: 18),
              label: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: const Color(0xFF030814),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(bCtx).size.height * 0.88,
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(bCtx).viewInsets.bottom + 28,
              ),
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
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                ),
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
          HapticFeedback.selectionClick();
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
