import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/services/squad_service.dart';

class SquadsScreen extends StatefulWidget {
  const SquadsScreen({super.key});

  @override
  State<SquadsScreen> createState() => _SquadsScreenState();
}

class _SquadsScreenState extends State<SquadsScreen> {
  List<Squad> _squads = [];
  int _selectedSquadIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSquads();
  }

  Future<void> _loadSquads() async {
    setState(() => _isLoading = true);
    final list = await SquadService.getSquads();
    if (mounted) {
      setState(() {
        _squads = list;
        _isLoading = false;
        if (_selectedSquadIndex >= _squads.length) {
          _selectedSquadIndex = 0;
        }
      });
    }
  }

  void _showCreateSquadDialog() {
    final nameCtrl = TextEditingController();
    final mottoCtrl = TextEditingController();
    String category = 'Study & Exams';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '⚔️ Create New Squad',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : kDarkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'मित्रांसोबत स्पर्धा करा आणि रोज सवयी पूर्ण करा!',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : kSecondaryText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Squad Name (उदा. MPSC Warriors)',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: [
                        'Study & Exams',
                        'Coding & Tech',
                        'Fitness & Gym',
                        'Deep Focus',
                        'General Productivity',
                      ].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: mottoCtrl,
                      decoration: InputDecoration(
                        labelText: 'Squad Motto (ध्येयवाक्य)',
                        hintText: 'कष्ट आज, यश उद्या!',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          final squad = await SquadService.createSquad(
                            name: nameCtrl.text.trim(),
                            category: category,
                            motto: mottoCtrl.text.trim(),
                          );
                          await _loadSquads();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 Squad "${squad.name}" created! Code: ${squad.code}'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          '🚀 Create Squad & Get Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showJoinSquadDialog() {
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            '🔑 Join Squad with Code',
            style: TextStyle(color: isDark ? Colors.white : kDarkText),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'तुमच्या मित्राने पाठवलेला ६-अक्षरी कोड टाका:',
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : kSecondaryText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'MPSC26',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final code = codeCtrl.text.trim();
                if (code.isEmpty) return;
                Navigator.pop(ctx);
                final joined = await SquadService.joinSquad(code);
                await _loadSquads();
                if (mounted) {
                  if (joined != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 Joined Squad "${joined.name}" successfully!'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                }
              },
              child: const Text('Join Squad', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kBgColor = isDark ? const Color(0xFF030712) : const Color(0xFFF8FAFC);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final activeSquad = _squads.isNotEmpty ? _squads[_selectedSquadIndex] : null;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text(
          '⚔️ Habit Squads & Battles',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Join with Code',
            icon: const Icon(Icons.group_add_rounded, color: kPrimaryColor),
            onPressed: _showJoinSquadDialog,
          ),
          IconButton(
            tooltip: 'Create New Squad',
            icon: const Icon(Icons.add_circle_outline_rounded, color: kPrimaryColor),
            onPressed: _showCreateSquadDialog,
          ),
        ],
      ),
      body: _squads.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('👥', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  const Text(
                    'अजून कोणताही स्क्वॉड नाही!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showCreateSquadDialog,
                    child: const Text('Create Squad'),
                  )
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Squad Selector Tabs
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _squads.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        if (idx == _squads.length) {
                          return ActionChip(
                            avatar: const Icon(Icons.add, size: 16, color: kPrimaryColor),
                            label: const Text('New Squad'),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            onPressed: _showCreateSquadDialog,
                          );
                        }
                        final s = _squads[idx];
                        final isSelected = idx == _selectedSquadIndex;
                        return ChoiceChip(
                          label: Text(s.name),
                          selected: isSelected,
                          selectedColor: kPrimaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : kDarkText),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          onSelected: (val) {
                            if (val) setState(() => _selectedSquadIndex = idx);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (activeSquad != null) ...[
                    // 2. Active Squad Hero Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: kPrimaryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activeSquad.name,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : kDarkText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${activeSquad.category} • Led by ${activeSquad.leaderName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : kSecondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Code Pill with 1-Tap Copy
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: activeSquad.code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('📋 Code ${activeSquad.code} copied!'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: kPrimaryColor.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        activeSquad.code,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryColor,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.copy_rounded, size: 14, color: kPrimaryColor),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '"${activeSquad.motto}"',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Viral WhatsApp Invite Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 3,
                              ),
                              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                              label: const Text(
                                '💬 Invite Friends on WhatsApp',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: () {
                                SquadService.inviteViaWhatsApp(activeSquad);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Squad Live Battle Rankings Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🏆 Live Battle Standings (${activeSquad.members.length} Members)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : kDarkText,
                          ),
                        ),
                        Text(
                          'Today\'s Stats',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF64748B) : kSecondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 4. Members List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeSquad.members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, mIdx) {
                        final m = activeSquad.members[mIdx];
                        return _buildMemberCard(m, mIdx + 1, isDark);
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMemberCard(SquadMember member, int rank, bool isDark) {
    Color cardBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    Color cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;

    if (member.isMVP) {
      cardBorder = const Color(0xFFF59E0B); // Gold
      cardBg = isDark ? const Color(0xFF1E1708) : const Color(0xFFFFFBEB);
    } else if (member.isSlacker) {
      cardBorder = const Color(0xFFEF4444).withOpacity(0.6); // Red Alert
      cardBg = isDark ? const Color(0xFF230D0D) : const Color(0xFFFEF2F2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: member.isMVP ? 1.8 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: member.isMVP
                      ? const Color(0xFFF59E0B)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  member.isMVP ? '👑' : '#$rank',
                  style: TextStyle(
                    fontSize: member.isMVP ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: member.isMVP ? Colors.white : (isDark ? Colors.white70 : kDarkText),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              Text(member.avatar, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),

              // Name & Streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : kDarkText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (member.isMVP) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'MVP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                        if (member.isSlacker) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '🐢 Slacker (आळशी)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '🔥 ${member.streakDays} Day Streak • ${member.completedHabitsCount}/5 Habits done',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : kSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stat counters bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricChip(
                icon: Icons.timer_rounded,
                label: 'Study Time',
                value: '${member.studyMinutesToday}m',
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              _buildMetricChip(
                icon: Icons.phone_android_rounded,
                label: 'Screen Time',
                value: '${member.screenTimeMinutesToday}m',
                color: member.screenTimeMinutesToday > 120
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF3B82F6),
                isDark: isDark,
              ),
              _buildMetricChip(
                icon: Icons.check_circle_outline_rounded,
                label: 'Habits Done',
                value: '${member.completedHabitsCount}',
                color: kPrimaryColor,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : kDarkText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

