import 'package:synvero/core/navigation/app_navigator.dart';
import 'package:synvero/core/services/supabase_service.dart';
import 'package:synvero/core/services/quote_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synvero/app/theme/app_theme.dart';
import 'package:synvero/core/config/supabase_config.dart';
import 'package:synvero/features/auth/data/auth_repository.dart';
import 'package:synvero/features/auth/presentation/login_screen.dart';
import 'package:synvero/features/auth/presentation/signup_screen.dart';
import 'package:synvero/features/dashboard/presentation/dashboard_screen.dart';
import 'package:synvero/features/habits/presentation/habit_screen.dart';
import 'package:synvero/features/timer/presentation/study_timer_screen.dart';
import 'package:synvero/features/tasks/presentation/tasks_screen.dart';
import 'package:synvero/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:synvero/features/profile/presentation/profile_screen.dart';
import 'package:synvero/features/nutrition/presentation/nutrition_screen.dart';
import 'package:synvero/core/services/theme_service.dart';
import 'package:synvero/features/fitness/presentation/fitness_screen.dart';
import 'package:synvero/core/services/notification_service.dart';
import 'package:synvero/core/widgets/alarm_ringing_dialog.dart';
import 'package:synvero/core/services/avatar_service.dart';

void main() async {
  // Ensure Flutter binding is initialized before using platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // Explicitly register Android SharedPreferences store
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      SharedPreferencesAndroid.registerWith();
    } catch (e) {
      debugPrint('SharedPreferencesAndroid.registerWith: $e');
    }
  }

  // Defensively initialize services so startup never results in a black screen
  try {
    await ThemeService.init();
  } catch (e, st) {
    debugPrint('ThemeService.init error: $e\n$st');
  }

  try {
    await AvatarService.init();
  } catch (e) {
    debugPrint('AvatarService.init error: ');
  }

  try {
    await NotificationService.init();
  } catch (e, st) {
    debugPrint('NotificationService.init error: $e\n$st');
  }

  try {
    QuoteService.init();
  } catch (e) {
    debugPrint('QuoteService.init error: $e');
  }

  // Initialize Supabase before building the widget tree.
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  } catch (e, st) {
    debugPrint('Supabase.initialize error: $e\n$st');
  }

  runApp(const SynveroApp());
}

class SynveroApp extends StatefulWidget {
  const SynveroApp({super.key});

  @override
  State<SynveroApp> createState() => _SynveroAppState();
}

class _SynveroAppState extends State<SynveroApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Request exact alarm and notification permissions
    NotificationService.requestPermissions();
    // Check if an alarm is already ringing in background
    NotificationService.checkForActiveAlarms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.checkForActiveAlarms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'HabbitNova',
          theme: buildSynveroTheme(),
          darkTheme: buildSynveroDarkTheme(),
          themeMode: themeMode,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return ValueListenableBuilder<ActiveAlarm?>(
              valueListenable: NotificationService.activeAlarmNotifier,
              builder: (context, activeAlarm, _) {
                return Stack(
                  children: [
                    ?child,
                    if (activeAlarm != null)
                      AlarmRingingDialog(alarm: activeAlarm),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
    final _authRepository = AuthRepository();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    try {
      final loggedIn = await _authRepository.isLoggedIn();
      if (loggedIn) {
        final user = SupabaseService.user;
        if (user != null) {
          await AvatarService.loadForUser(user.id);
        }
      } else {
        AvatarService.resetForLogout();
      }
      if (mounted) {
        setState(() {
          _isAuthenticated = loggedIn;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogin(String email, String password) async {
    try {
      await _authRepository.signIn(email: email, password: password);
      final user = SupabaseService.user;
      if (user != null) {
        await AvatarService.loadForUser(user.id);
      }
      setState(() {
        _isAuthenticated = true;
      });
      // Navigate to dashboard after successful login
      appNavigatorKey.currentState?.pushReplacementNamed('/dashboard');
    } catch (e) {
      rethrow; // Let the screen handle the error display
    }
  }

  Future<void> _handleSignup(
    String username,
    String email,
    String password,
  ) async {
    try {
      await _authRepository.signUp(
        email: email,
        password: password,
        username: username,
      );
      setState(() {
        _isAuthenticated = true;
      });
      // Navigate to dashboard after successful signup
      appNavigatorKey.currentState?.pushReplacementNamed('/dashboard');
    } catch (e) {
      rethrow; // Let the screen handle the error display
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B66FF)),
        ),
      );
    }

    return Navigator(
      key: appNavigatorKey,
      initialRoute: _isAuthenticated ? '/dashboard' : '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (context) => LoginScreen(onLogin: _handleLogin),
            );
          case '/signup':
            return MaterialPageRoute(
              builder: (context) => SignupScreen(onSignup: _handleSignup),
            );
          case '/dashboard':
            return MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
            );
          case '/habits':
            return MaterialPageRoute(builder: (context) => const HabitScreen());
          case '/timer':
            return MaterialPageRoute(builder: (context) => const StudyTimerScreen());
          case '/tasks':
            return MaterialPageRoute(builder: (context) => const TasksScreen());
          case '/ai_assistant':
          case '/ai-assistant':
            return MaterialPageRoute(builder: (context) => const AIAssistantScreen());
          case '/profile':
            return MaterialPageRoute(builder: (context) => const ProfileScreen());
          case '/nutrition':
            return MaterialPageRoute(builder: (context) => const NutritionScreen());
          case '/fitness':
            return MaterialPageRoute(builder: (context) => const FitnessScreen());
          default:
            // If already authenticated, show dashboard
            if (_isAuthenticated) {
              return MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              );
            }
            // Otherwise show login
            return MaterialPageRoute(
              builder: (context) => LoginScreen(onLogin: _handleLogin),
            );
        }
      },
    );
  }
}
