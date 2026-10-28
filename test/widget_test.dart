// Synvero widget test.
//
// Verifies that the login screen renders correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:synvero/app/theme/app_theme.dart';
import 'package:synvero/features/auth/presentation/login_screen.dart';
import 'package:synvero/features/habits/presentation/habit_screen.dart' as synvero_habits;
import 'package:synvero/features/tasks/presentation/tasks_screen.dart' as synvero_tasks;
import 'package:synvero/features/profile/presentation/profile_screen.dart' as synvero_profile;
import 'package:synvero/features/nutrition/presentation/nutrition_screen.dart' as synvero_nutrition;
import 'package:synvero/features/fitness/presentation/fitness_screen.dart' as synvero_fitness;
import 'package:synvero/features/timer/presentation/study_timer_screen.dart' as synvero_timer;
import 'package:synvero/features/dashboard/presentation/dashboard_screen.dart' as synvero_dashboard;
import 'package:synvero/features/ai_assistant/presentation/ai_assistant_screen.dart' as synvero_ai;
import 'package:synvero/features/ai_assistant/domain/ai_response_engine.dart';
import 'package:synvero/main.dart' as synvero_main;
import 'package:synvero/core/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    // Build the login screen directly with the theme
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSynveroTheme(),
        home: const LoginScreen(),
      ),
    );

    // Verify that the app title is rendered.
    expect(find.text('Synvero'), findsOneWidget);
    expect(find.text('Everything Working in Sync.'), findsOneWidget);

    // Verify the login form is present (should be exactly 2 TextFormFields for email and password)
    expect(find.byType(TextFormField), findsNWidgets(2));
    // Verify the login button is present (should be exactly 1 ElevatedButton with 'Log In' text)
    expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
  });

  testWidgets('Login screen shows validation errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSynveroTheme(),
        home: const LoginScreen(),
      ),
    );

    // Tap the login button without entering anything
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pump();

    // Should show validation errors
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Login screen password visibility toggle works', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSynveroTheme(),
        home: const LoginScreen(),
      ),
    );

    // Find the password field and verify it's obscured initially
    final passwordField = find.byType(TextFormField).last;
    expect(passwordField, findsOneWidget);

    // Tap the visibility toggle (eye icon)
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();

    // The icon should change to visibility_outlined
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('Tasks screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_tasks.TasksScreen(),
      ),
    );

    expect(find.text('Tasks'), findsAtLeast(1));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Upcoming'), findsAtLeast(1));
    expect(find.text('Complete assignment'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('Profile & Settings screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_profile.ProfileScreen(),
      ),
    );

    expect(find.text('Profile & Settings'), findsOneWidget);
    expect(find.text('Notification Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('Nutrition Plan screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_nutrition.NutritionScreen(),
      ),
    );

    expect(find.text('Nutrition Plan'), findsOneWidget);
    expect(find.text("Today's Meal Plan"), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Oats with fruits & nuts'), findsOneWidget);
    expect(find.text('Tips'), findsOneWidget);
  });

  testWidgets('Fitness Plan screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_fitness.FitnessScreen(),
      ),
    );

    expect(find.text('Fitness Plan'), findsOneWidget);
    expect(find.text('Your Personalized Workout'), findsOneWidget);
    expect(find.text('Push-ups'), findsOneWidget);
    expect(find.text('View Full Plan'), findsOneWidget);
  });

  testWidgets('Profile screen appearance modal opens and shows theme options',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_profile.ProfileScreen(),
      ),
    );

    // Tap on Appearance
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    // Verify theme options are displayed
    expect(find.text('Choose how Synvero looks on your device'), findsOneWidget);
    expect(find.text('Light Theme'), findsWidgets);
    expect(find.text('Dark Theme'), findsOneWidget);
    expect(find.text('System Default'), findsOneWidget);
  });

  testWidgets('Profile screen notification modal opens with permissions and options',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_profile.ProfileScreen(),
      ),
    );

    // Tap on Notification Settings
    await tester.tap(find.text('Notification Settings'));
    await tester.pumpAndSettle();

    // Verify modal header and reminder toggles are displayed
    expect(find.text('Device alerts for habits, tasks & timer'), findsOneWidget);
    expect(find.text('Daily Habit Reminders'), findsOneWidget);
    expect(find.text('Study Timer & Focus Alerts'), findsOneWidget);
    expect(find.text('Meal & Nutrition Logging'), findsOneWidget);
    expect(find.text('Task Due Reminders'), findsOneWidget);
  });

  testWidgets('Profile screen home screen widget modal opens with preview and guide',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_profile.ProfileScreen(),
      ),
    );

    // Tap on Home Screen Widget
    await tester.tap(find.text('Home Screen Widget'));
    await tester.pumpAndSettle();

    // Verify widget preview & guide steps are displayed
    expect(find.text('Add Synvero widget to your phone screen'), findsOneWidget);
    expect(find.text('Live Widget Preview (4x2)'), findsOneWidget);
    expect(find.text('🔥 7-Day Streak'), findsOneWidget);
    expect(find.text('How to Add on Your Phone (कसे ॲड करावे):'), findsOneWidget);
    expect(find.text('Got it! (समजले)'), findsOneWidget);
  });

  testWidgets('Study timer screen allows selecting custom focus time via preset chips',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_timer.StudyTimerScreen(),
      ),
    );

    // Initial state: 25 min default
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Set Time:'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);

    // Tap on '45 min' preset chip
    await tester.tap(find.text('45 min'));
    await tester.pumpAndSettle();

    // Verify timer updated to 45:00
    expect(find.text('45:00'), findsOneWidget);
  });

  testWidgets('Study timer custom bottom sheet opens and adjusts duration',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_timer.StudyTimerScreen(),
      ),
    );

    // Tap on 'Custom' chip to open the modal sheet
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    // Verify modal elements
    expect(find.text('Set Focus Duration'), findsOneWidget);
    expect(find.text('Choose how many minutes you want to focus'), findsOneWidget);
    expect(find.text('MINUTES FOCUS'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_circle_outline_rounded), findsOneWidget);
    expect(find.text('Set Focus Time'), findsOneWidget);

    // Tap '+' stepper button (adds 5 mins)
    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
    await tester.pumpAndSettle();

    // Tap 'Set Focus Time' to confirm
    await tester.tap(find.text('Set Focus Time'));
    await tester.pumpAndSettle();

    // Verify updated (25 + 5 = 30 min -> 30:00)
    expect(find.text('30:00'), findsOneWidget);
  });

  testWidgets('Dashboard screen renders clean state for new user with zero dummy completed tasks',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_dashboard.DashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 0 completed habits by default
    expect(find.text('0/5'), findsOneWidget);
    expect(find.text('Habits\ncompleted'), findsOneWidget);

    // Verify 0m study time and 0/4 tasks done and 0 days streak (NO dummy data)
    expect(find.text('0m'), findsOneWidget);
    expect(find.text('0/4'), findsOneWidget);
    expect(find.text('0 days'), findsOneWidget);

    // Verify habits show 'Pending', NOT completed
    expect(find.text('Completed'), findsNothing);
    expect(find.textContaining('Pending'), findsWidgets);
  });

  testWidgets('AuthWrapper restores persistent session and stays logged in on dashboard',
      (WidgetTester tester) async {
    // Simulate active persistent login session
    SharedPreferences.setMockInitialValues({
      'is_user_logged_in': true,
      'logged_in_user_id': 'test-persistent-user',
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_main.AuthWrapper(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify user is immediately on dashboard without showing login
    expect(find.text("Today's Progress"), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Log In'), findsNothing);
  });

  testWidgets('AuthWrapper shows login screen when user is not logged in',
      (WidgetTester tester) async {
    // Simulate logged out state
    SharedPreferences.setMockInitialValues({
      'is_user_logged_in': false,
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_main.AuthWrapper(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify login screen is displayed
    expect(find.text('Synvero'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
  });

  testWidgets('App-wide theme changes dynamically apply across screens',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.setThemeMode(ThemeMode.light);

    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService.themeModeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            theme: buildSynveroTheme(),
            darkTheme: buildSynveroDarkTheme(),
            themeMode: themeMode,
            home: const synvero_dashboard.DashboardScreen(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial Light Theme brightness
    BuildContext context = tester.element(find.byType(synvero_dashboard.DashboardScreen));
    expect(Theme.of(context).brightness, Brightness.light);

    // Switch to Dark Theme
    await ThemeService.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    // Verify Brightness changed to dark across the app tree
    context = tester.element(find.byType(synvero_dashboard.DashboardScreen));
    expect(Theme.of(context).brightness, Brightness.dark);

    // Switch back to Light Theme
    await ThemeService.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();

    context = tester.element(find.byType(synvero_dashboard.DashboardScreen));
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('Ticking a habit updates subtitle to 1/1 completed and unticking sets 0/1 completed',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_habits.HabitScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial clean state: Meditate shows '0/1 completed'
    expect(find.text('Meditate'), findsOneWidget);
    expect(find.text('0/1 completed'), findsWidgets);

    // Tap on Meditate to tick it
    await tester.tap(find.text('Meditate'));
    await tester.pumpAndSettle();

    // Verify Meditate is now completed with '1/1 completed'
    expect(find.text('1/1 completed'), findsOneWidget);

    // Tap on Meditate again to untick it
    await tester.tap(find.text('Meditate'));
    await tester.pumpAndSettle();

    // Verify Meditate reverted back to '0/1 completed'
    expect(find.text('1/1 completed'), findsNothing);
  });

  test('AIResponseEngine answers tech, study, and fitness questions accurately', () {
    // 1. Test "what is java ?"
    final javaResponse = AIResponseEngine.getResponse(
      prompt: 'what is java ?',
      category: 'Study',
    );
    expect(javaResponse.contains('Java Virtual Machine (JVM)'), isTrue);
    expect(javaResponse.contains('Write Once, Run Anywhere'), isTrue);
    expect(javaResponse.contains('Object-Oriented'), isTrue);

    // 2. Test "how to study ?"
    final studyResponse = AIResponseEngine.getResponse(
      prompt: 'how to study ?',
      category: 'Study',
    );
    expect(studyResponse.contains('Pomodoro'), isTrue);
    expect(studyResponse.contains('Active Recall'), isTrue);
    expect(studyResponse.contains('Feynman Technique'), isTrue);

    // 3. Test "Explain a topic"
    final topicResponse = AIResponseEngine.getResponse(
      prompt: 'Explain a topic',
      category: 'Study',
    );
    expect(topicResponse.contains('Which topic or concept are you learning right now?'), isTrue);

    // 4. Test "whos is the founder of google ?"
    final googleFounderResponse = AIResponseEngine.getResponse(
      prompt: 'whos is the founder of google ?',
      category: 'General',
    );
    expect(googleFounderResponse.contains('Larry Page'), isTrue);
    expect(googleFounderResponse.contains('Sergey Brin'), isTrue);
    expect(googleFounderResponse.contains('Stanford University'), isTrue);
  });

  testWidgets('AI Assistant screen sends and renders intelligent answers',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: synvero_ai.AIAssistantScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial elements
    expect(find.text('AI Assistant'), findsOneWidget);
    expect(find.text('Explain a topic'), findsOneWidget);

    // Enter message "what is java ?"
    await tester.enterText(find.byType(TextField), 'what is java ?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    // Verify user message appeared immediately
    expect(find.text('what is java ?'), findsOneWidget);

    // Advance 1 second to complete AI response delay
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Verify AI answered with Java explanation (contains "What is Java?")
    expect(find.textContaining('What is Java?'), findsOneWidget);
    expect(find.textContaining('Java Virtual Machine'), findsOneWidget);
  });
}

