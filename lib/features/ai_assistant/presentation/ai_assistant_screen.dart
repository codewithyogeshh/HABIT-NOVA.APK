import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/supabase_service.dart';
import 'package:synvero/features/ai_assistant/data/gemini_ai_service.dart';
import 'package:synvero/features/ai_assistant/domain/ai_response_engine.dart';

/// Chat message model for AI assistant conversations.
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final String time;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    required this.time,
  }) : id = id ?? 'msg-${DateTime.now().microsecondsSinceEpoch}';
}

/// AI Assistant screen.
///
/// Implements Screen 7 from the Synvero master design mockup:
/// - Header: Back arrow, "AI Assistant", "Your personal AI companion"
/// - Topic chips: [Study] [Fitness] [Nutrition] [General]
/// - AI greeting message bubble with sparkle icon
/// - Quick suggestion action prompt pills:
///   - Explain a topic
///   - Create a study plan
///   - Generate practice questions
///   - Summarize this chapter
/// - Full interactive message stream and input box with send button
/// - Bottom Navigation Bar
class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  int _selectedCategoryIndex = 0; // 0: Study, 1: Fitness, 2: Nutrition, 3: General
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  int _currentTabIndex = 3;
  String? _recentlyCopiedId;

  void _copyToClipboard(String text, {String? label}) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              label ?? 'Copied to clipboard!',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _copyFullConversation() {
    if (_messages.isEmpty) return;
    final buffer = StringBuffer();
    for (final m in _messages) {
      buffer.writeln(m.isUser ? '👤 You (${m.time}):' : '🤖 HabbitNova AI (${m.time}):');
      buffer.writeln(m.text);
      buffer.writeln();
    }
    _copyToClipboard(buffer.toString().trim(), label: 'Full conversation copied!');
  }

  final List<String> _categories = ['Study', 'Fitness', 'Nutrition', 'General'];

  final List<String> _studyPrompts = [
    'Explain a topic',
    'Create a study plan',
    'Generate practice questions',
    'Summarize this chapter',
  ];

  final List<String> _fitnessPrompts = [
    'Upper body workout plan',
    'Proper form for deadlifts',
    '15-min HIIT routine',
    'Rest day recovery tips',
  ];

  final List<String> _nutritionPrompts = [
    'High-protein breakfast ideas',
    'Daily hydration goals',
    'Healthy pre-workout snack',
    'Balanced meal plan (1800 kcal)',
  ];

  final List<String> _generalPrompts = [
    'How to build consistent habits',
    'Tips to avoid burnout',
    'Morning routine for productivity',
    'Weekly goal review',
  ];

  @override
  void initState() {
    super.initState();
    final user = SupabaseService.user;
    final name = (user?.userMetadata?['username'] as String?) ??
        (user?.email != null && user!.email!.isNotEmpty ? user.email!.split('@').first : 'Friend');
    _messages.add(
      ChatMessage(
        text: "Hi $name! 👋 I'm your AI assistant. How can I help you today?",
        isUser: false,
        time: _currentTimeString(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _currentTimeString() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  List<String> get _currentPrompts {
    switch (_selectedCategoryIndex) {
      case 1:
        return _fitnessPrompts;
      case 2:
        return _nutritionPrompts;
      case 3:
        return _generalPrompts;
      default:
        return _studyPrompts;
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final cleanText = text.trim();
    final userMsg = ChatMessage(
      text: cleanText,
      isUser: true,
      time: _currentTimeString(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    final user = SupabaseService.user;
    final userName = (user?.userMetadata?['username'] as String?) ??
        (user?.email != null && user!.email!.isNotEmpty ? user.email!.split('@').first : 'Friend');
    final category = _categories[_selectedCategoryIndex];

    try {
      final reply = await GeminiAIService.generateResponse(
        prompt: cleanText,
        category: category,
        userName: userName,
      );

      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: reply,
            isUser: false,
            time: _currentTimeString(),
          ),
        );
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      final fallbackReply = AIResponseEngine.getResponse(
        prompt: cleanText,
        category: category,
        userName: userName,
      );
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: fallbackReply,
            isUser: false,
            time: _currentTimeString(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  Future<void> _showApiKeyModal(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) async {
    final currentKey = await GeminiAIService.getApiKey();
    final keyController = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: kPrimaryColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Google Gemini AI Setup',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: subtextColor),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Add your Google Gemini API Key to enable real-time generative AI that answers ANY question in the world, explains custom code, and generates detailed plans!',
                style: TextStyle(color: subtextColor, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                obscureText: true,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  labelStyle: TextStyle(color: subtextColor),
                  hintText: 'AIzaSy...',
                  hintStyle: TextStyle(color: subtextColor.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.key_rounded, color: kPrimaryColor, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kPrimaryColor, width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '💡 Get your free key at: aistudio.google.com/app/apikey',
                style: TextStyle(color: subtextColor, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (currentKey.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await GeminiAIService.removeApiKey();
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Gemini API key removed. Using built-in smart engine.')),
                          );
                        },
                        child: const Text('Clear Key', style: TextStyle(color: Color(0xFFEF4444))),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final newKey = keyController.text.trim();
                        if (newKey.isNotEmpty) {
                          final messenger = ScaffoldMessenger.of(context);
                          await GeminiAIService.setApiKey(newKey);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Gemini API Key activated! 🎉 Real-time AI is now live.'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      child: const Text('Save & Activate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kBgColor = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC);
    final kCardBg = isDark ? const Color(0xFF131D31) : Colors.white;
    final kTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final kSubtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final kBorderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final kBottomNavBg = isDark ? const Color(0xFF0D1424) : Colors.white;
    final kInputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: kTextColor, size: 22),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Assistant',
              style: TextStyle(
                color: kTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Your personal AI companion',
              style: TextStyle(
                color: kSubtextColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded, color: kPrimaryColor, size: 22),
            tooltip: 'Copy Full Conversation',
            onPressed: _copyFullConversation,
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: kPrimaryColor, size: 22),
            tooltip: 'Gemini AI Brain Setup',
            onPressed: () => _showApiKeyModal(context, isDark, kCardBg, kBorderColor, kTextColor, kSubtextColor),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Category Chips Row [Study] [Fitness] [Nutrition] [General]
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimaryColor : kCardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? kPrimaryColor : kBorderColor,
                        ),
                      ),
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : kSubtextColor,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Chat Messages Stream
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  ..._messages.map((msg) => _buildMessageBubble(msg, isDark, kCardBg, kBorderColor, kTextColor, kSubtextColor)),

                  // Prompt Suggestions (if only 1 or few messages exist)
                  if (_messages.length <= 2) ...[
                    const SizedBox(height: 12),
                    ..._currentPrompts.map((prompt) => _buildSuggestionPill(prompt, isDark, kCardBg, kBorderColor, kTextColor)),
                  ],

                  // Typing indicator
                  if (_isTyping) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kBorderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kPrimaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI is thinking...',
                                style: TextStyle(
                                  color: kSubtextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Bottom Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kCardBg,
                border: Border(top: BorderSide(color: kBorderColor, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kInputBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        style: TextStyle(color: kTextColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _sendMessage(_messageController.text),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: kPrimaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kBottomNavBg,
          border: Border(top: BorderSide(color: kBorderColor, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
            if (index == 0) {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            } else if (index == 1) {
              Navigator.of(context).pushNamed('/habits');
            } else if (index == 2) {
              Navigator.of(context).pushNamed('/timer');
            } else if (index == 3) {
              Navigator.of(context).pushNamed('/tasks');
            } else if (index == 4) {
              Navigator.of(context).pushNamed('/profile');
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: kBottomNavBg,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Habits'),
            BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), label: 'Timer'),
            BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage msg,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    final isCopied = _recentlyCopiedId == msg.id;

    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            InkWell(
              onLongPress: () {
                _copyToClipboard(msg.text, label: 'Question copied!');
                setState(() => _recentlyCopiedId = msg.id);
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted && _recentlyCopiedId == msg.id) {
                    setState(() => _recentlyCopiedId = null);
                  }
                });
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: SelectableText(
                  msg.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.time,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    _copyToClipboard(msg.text, label: 'Question copied!');
                    setState(() => _recentlyCopiedId = msg.id);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted && _recentlyCopiedId == msg.id) {
                        setState(() => _recentlyCopiedId = null);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      isCopied ? Icons.check_rounded : Icons.content_copy_rounded,
                      size: 13,
                      color: isCopied
                          ? Colors.greenAccent
                          : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // AI Message bubble (with ChatGPT-style SelectableText and Copy Action)
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 10),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2D48) : const Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: kPrimaryColor,
                  size: 16,
                ),
              ),
              Expanded(
                child: InkWell(
                  onLongPress: () {
                    _copyToClipboard(msg.text, label: 'AI answer copied!');
                    setState(() => _recentlyCopiedId = msg.id);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted && _recentlyCopiedId == msg.id) {
                        setState(() => _recentlyCopiedId = null);
                      }
                    });
                  },
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SelectableText(
                      msg.text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 4),
            child: Row(
              children: [
                Text(
                  msg.time,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () {
                    _copyToClipboard(msg.text, label: 'AI answer copied!');
                    setState(() => _recentlyCopiedId = msg.id);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted && _recentlyCopiedId == msg.id) {
                        setState(() => _recentlyCopiedId = null);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCopied ? Icons.check_rounded : Icons.content_copy_rounded,
                          size: 13,
                          color: isCopied
                              ? Colors.greenAccent
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCopied ? 'Copied' : 'Copy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isCopied
                                ? Colors.greenAccent
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionPill(
    String prompt,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 38),
      child: InkWell(
        onTap: () => _sendMessage(prompt),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, size: 16, color: kPrimaryColor),
              const SizedBox(width: 8),
              Text(
                prompt,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
