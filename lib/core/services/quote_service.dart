import 'dart:async';
import 'package:flutter/foundation.dart';

/// Model representing a motivational quote with title, author, and category.
class MotivationalQuote {
  final String text;
  final String author;
  final String category;

  const MotivationalQuote({
    required this.text,
    required this.author,
    required this.category,
  });
}

/// Service providing continuously rotating, high-impact motivational quotes for HabbitNova.
class QuoteService {
  static const List<MotivationalQuote> quotes = [
    MotivationalQuote(
      text: 'Small steps every day create gigantic results.',
      author: 'James Clear',
      category: 'Habits',
    ),
    MotivationalQuote(
      text: 'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
      author: 'Will Durant',
      category: 'Consistency',
    ),
    MotivationalQuote(
      text: 'Discipline is choosing between what you want now and what you want most.',
      author: 'Abraham Lincoln',
      category: 'Discipline',
    ),
    MotivationalQuote(
      text: 'The secret of getting ahead is getting started.',
      author: 'Mark Twain',
      category: 'Action',
    ),
    MotivationalQuote(
      text: 'Success is the sum of small efforts, repeated day in and day out.',
      author: 'Robert Collier',
      category: 'Persistence',
    ),
    MotivationalQuote(
      text: 'Don’t watch the clock; do what it does. Keep going.',
      author: 'Sam Levenson',
      category: 'Focus',
    ),
    MotivationalQuote(
      text: 'Focus on being productive instead of busy.',
      author: 'Tim Ferriss',
      category: 'Productivity',
    ),
    MotivationalQuote(
      text: 'Your habits determine your future. Build the ones you want to live with.',
      author: 'Jack Canfield',
      category: 'Mindset',
    ),
    MotivationalQuote(
      text: 'Motivation gets you going, but discipline keeps you growing.',
      author: 'John C. Maxwell',
      category: 'Discipline',
    ),
    MotivationalQuote(
      text: 'Consistency is the DNA of mastery.',
      author: 'Robin Sharma',
      category: 'Mastery',
    ),
    MotivationalQuote(
      text: 'You don’t have to be extreme, just consistent.',
      author: 'Atomic Habits',
      category: 'Habits',
    ),
    MotivationalQuote(
      text: 'Action is the foundational key to all success.',
      author: 'Pablo Picasso',
      category: 'Action',
    ),
    MotivationalQuote(
      text: 'One day or day one. You decide.',
      author: 'Paulo Coelho',
      category: 'Mindset',
    ),
    MotivationalQuote(
      text: 'A 1% improvement every day makes you 37 times better in one year.',
      author: 'James Clear',
      category: 'Growth',
    ),
    MotivationalQuote(
      text: 'Win your morning, win your day.',
      author: 'Robin Sharma',
      category: 'Energy',
    ),
    MotivationalQuote(
      text: 'The only bad workout is the one that didn’t happen.',
      author: 'Fitness Wisdom',
      category: 'Fitness',
    ),
    MotivationalQuote(
      text: 'It is not about having time, it is about making time.',
      author: 'Discipline Rule',
      category: 'Priority',
    ),
    MotivationalQuote(
      text: 'Dream big. Start small. Begin now.',
      author: 'Robin Sharma',
      category: 'Action',
    ),
    MotivationalQuote(
      text: 'Do something today that your future self will thank you for.',
      author: 'Sean Patrick Flanery',
      category: 'Future',
    ),
    MotivationalQuote(
      text: 'Push yourself, because no one else is going to do it for you.',
      author: 'Daily Spark',
      category: 'Drive',
    ),
  ];

  static int _currentIndex = 0;

  static final ValueNotifier<MotivationalQuote> currentQuoteNotifier =
      ValueNotifier<MotivationalQuote>(quotes[0]);

  static Timer? _timer;

  /// Initializes the quote service and starts gentle automatic quote rotation
  static void init() {
    _currentIndex = DateTime.now().minute % quotes.length;
    currentQuoteNotifier.value = quotes[_currentIndex];

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) {
      nextQuote();
    });
  }

  /// Manually advances to the next motivational quote
  static MotivationalQuote nextQuote() {
    _currentIndex = (_currentIndex + 1) % quotes.length;
    final next = quotes[_currentIndex];
    currentQuoteNotifier.value = next;
    return next;
  }

  /// Get current quote
  static MotivationalQuote get currentQuote => currentQuoteNotifier.value;
}
