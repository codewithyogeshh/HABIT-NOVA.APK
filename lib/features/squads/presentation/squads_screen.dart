import 'package:synvero/core/services/ad_credit_service.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:synvero/app/theme/app_colors.dart';

import 'package:synvero/core/services/language_service.dart';

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

  bool _isRefreshing = false;

  Timer? _liveRefreshTimer;

  DateTime? _lastSyncedTime;



  @override

  void initState() {

    super.initState();

    _loadSquads();

    _startLivePolling();

  }



  @override

  void dispose() {

    _liveRefreshTimer?.cancel();

    super.dispose();

  }



  void _startLivePolling() {

    _liveRefreshTimer?.cancel();

    // Poll Cloud Firestore every 10 seconds in real time

    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {

      if (mounted && _squads.isNotEmpty && !_isRefreshing) {

        _refreshActiveSquad(silent: true);

      }

    });

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

      // Initial background sync for active squad

      if (_squads.isNotEmpty) {

        _refreshActiveSquad(silent: false);

      }

    }

  }



  Future<void> _refreshActiveSquad({bool silent = false}) async {

    if (_squads.isEmpty || _selectedSquadIndex >= _squads.length) return;

    if (!silent) setState(() => _isRefreshing = true);

    try {

      final active = _squads[_selectedSquadIndex];

      final updated = await SquadService.refreshSquad(active);

      if (mounted) {

        setState(() {

          _squads[_selectedSquadIndex] = updated;

          _isRefreshing = false;

          _lastSyncedTime = DateTime.now();

        });

      }

    } catch (_) {

      if (mounted) setState(() => _isRefreshing = false);

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

                    color: Colors.black.withValues(alpha: 0.3),

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

                          color: Colors.grey.withValues(alpha: 0.4),

                          borderRadius: BorderRadius.circular(2),

                        ),

                      ),

                    ),

                    const SizedBox(height: 16),

                    Text(

                      LanguageService.tr('create_squad_sheet_title'),

                      style: TextStyle(

                        fontSize: 20,

                        fontWeight: FontWeight.bold,

                        color: isDark ? Colors.white : kDarkText,

                      ),

                    ),

                    const SizedBox(height: 6),

                    Text(

                      LanguageService.tr('create_squad_sheet_subtitle'),

                      style: TextStyle(

                        fontSize: 13,

                        color: isDark ? const Color(0xFF94A3B8) : kSecondaryText,

                      ),

                    ),

                    const SizedBox(height: 20),

                    TextField(

                      controller: nameCtrl,

                      decoration: InputDecoration(

                        labelText: LanguageService.tr('squad_name'),

                        hintText: 'e.g. MPSC Warriors, Coding Gang',

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

                      initialValue: category,

                      decoration: InputDecoration(

                        labelText: LanguageService.tr('squad_category'),

                        filled: true,

                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),

                        border: OutlineInputBorder(

                          borderRadius: BorderRadius.circular(14),

                          borderSide: BorderSide.none,

                        ),

                      ),

                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,

                      items: [

                        DropdownMenuItem(

                          value: 'Study & Exams',

                          child: Text(LanguageService.tr('category_study')),

                        ),

                        DropdownMenuItem(

                          value: 'Coding & Tech',

                          child: Text(LanguageService.tr('category_coding')),

                        ),

                        DropdownMenuItem(

                          value: 'Fitness & Gym',

                          child: Text(LanguageService.tr('category_fitness')),

                        ),

                        DropdownMenuItem(

                          value: 'General Focus',

                          child: Text(LanguageService.tr('category_general')),

                        ),

                      ],

                      onChanged: (val) {

                        if (val != null) setModalState(() => category = val);

                      },

                    ),

                    const SizedBox(height: 14),

                    TextField(

                      controller: mottoCtrl,

                      decoration: InputDecoration(

                        labelText: LanguageService.tr('squad_motto'),

                        hintText: 'e.g. Hard work in silence, success makes noise.',

                        filled: true,

                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),

                        border: OutlineInputBorder(

                          borderRadius: BorderRadius.circular(14),

                          borderSide: BorderSide.none,

                        ),

                      ),

                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Squad Creation: 50 Credits',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  'Your balance: ${AdCreditService.creditsNotifier.value} Credits',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AdCreditService.creditsNotifier.value >= 50
                                        ? const Color(0xFF10B981)
                                        : Colors.amber,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB300).withValues(alpha: 0.2),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              await AdCreditService.showRewardedAd(
                                context: context,
                                onRewardGranted: () {
                                  setModalState(() {});
                                },
                              );
                            },
                            icon: const Icon(Icons.play_circle_fill_rounded, size: 16, color: Color(0xFFFFB300)),
                            label: const Text(
                              '+50 Ad',
                              style: TextStyle(
                                color: Color(0xFFFFB300),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

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

                          final currentCredits = AdCreditService.creditsNotifier.value;
                          if (currentCredits < 50) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Need 50 credits to create a squad! Tap "+50 Ad" to earn credits.'),
                                backgroundColor: Colors.amber,
                              ),
                            );
                            await AdCreditService.showRewardedAd(
                              context: context,
                              onRewardGranted: () {
                                setModalState(() {});
                              },
                            );
                            return;
                          }

                          final deducted = await AdCreditService.deductCredits(50, reason: 'Created Squad ${nameCtrl.text.trim()}');
                          if (!deducted || !ctx.mounted) return;

                          final scaffoldMessenger = ScaffoldMessenger.of(context);

                          Navigator.pop(ctx);

                          final squad = await SquadService.createSquad(

                            name: nameCtrl.text.trim(),

                            category: category,

                            motto: mottoCtrl.text.trim(),

                          );

                          await _loadSquads();

                          if (mounted) {

                            scaffoldMessenger.showSnackBar(

                              SnackBar(

                                content: Text('${LanguageService.tr('squad_created_success')} (Code: ${squad.code}) 🪙 -50 Credits'),

                                backgroundColor: const Color(0xFF10B981),

                              ),

                            );

                          }

                        },

                        child: Text(

                          LanguageService.tr('create_squad_btn'),

                          style: const TextStyle(

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

            LanguageService.tr('join_squad_sheet_title'),

            style: TextStyle(color: isDark ? Colors.white : kDarkText, fontWeight: FontWeight.bold),

          ),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Text(

                LanguageService.tr('join_squad_sheet_subtitle'),

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

                  hintText: 'NOVA84',

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

              child: Text(LanguageService.tr('cancel')),

            ),

            ElevatedButton(

              style: ElevatedButton.styleFrom(

                backgroundColor: kPrimaryColor,

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

              ),

              onPressed: () async {

                final code = codeCtrl.text.trim();

                if (code.isEmpty) return;

                final messenger = ScaffoldMessenger.of(context);

                Navigator.pop(ctx);

                final joined = await SquadService.joinSquad(code);

                await _loadSquads();

                if (mounted) {

                  if (joined != null) {

                    messenger.showSnackBar(

                      SnackBar(

                        content: Text(LanguageService.tr('squad_join_success')),

                        backgroundColor: const Color(0xFF10B981),

                      ),

                    );

                  } else {

                    messenger.showSnackBar(

                      SnackBar(

                        content: Text(LanguageService.tr('squad_not_found')),

                        backgroundColor: const Color(0xFFEF4444),

                      ),

                    );

                  }

                }

              },

              child: Text(LanguageService.tr('join_squad_btn'), style: const TextStyle(color: Colors.white)),

            ),

          ],

        );

      },

    );

  }



  void _confirmLeaveSquad(Squad squad) {

    showDialog(

      context: context,

      builder: (ctx) {

        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return AlertDialog(

          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

          title: Text(

            LanguageService.tr('leave_squad'),

            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),

          ),

          content: Text(

            'Are you sure you want to leave "${squad.name}"? You will not be able to view members or live progress without re-entering the code.',

            style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : kDarkText),

          ),

          actions: [

            TextButton(

              onPressed: () => Navigator.pop(ctx),

              child: Text(LanguageService.tr('cancel')),

            ),

            ElevatedButton(

              style: ElevatedButton.styleFrom(

                backgroundColor: const Color(0xFFEF4444),

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

              ),

              onPressed: () async {

                final messenger = ScaffoldMessenger.of(context);

                Navigator.pop(ctx);

                await SquadService.leaveSquad(squad.code);

                await _loadSquads();

                if (mounted) {

                  messenger.showSnackBar(

                    SnackBar(

                      content: Text('Left ${squad.name}'),

                      backgroundColor: const Color(0xFF64748B),

                    ),

                  );

                }

              },

              child: const Text('Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),

            ),

          ],

        );

      },

    );

  }



  void _showMemberDetailSheet(SquadMember member, int rank) {

    showModalBottomSheet(

      context: context,

      backgroundColor: Colors.transparent,

      isScrollControlled: true,

      builder: (ctx) {

        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        final isHealthyScreenTime = member.screenTimeMinutesToday <= 120;



        return Container(

          constraints: BoxConstraints(

            maxHeight: MediaQuery.of(ctx).size.height * 0.88,

          ),

          padding: EdgeInsets.only(

            left: 24,

            right: 24,

            top: 24,

            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,

          ),

          decoration: BoxDecoration(

            color: isDark ? const Color(0xFF0F172A) : Colors.white,

            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),

            boxShadow: [

              BoxShadow(

                color: Colors.black.withValues(alpha: 0.3),

                blurRadius: 24,

                offset: const Offset(0, -4),

              )

            ],

          ),

          child: SafeArea(

            top: false,

            child: SingleChildScrollView(

              physics: const BouncingScrollPhysics(),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

              Container(

                width: 44,

                height: 4,

                decoration: BoxDecoration(

                  color: Colors.grey.withValues(alpha: 0.4),

                  borderRadius: BorderRadius.circular(2),

                ),

              ),

              const SizedBox(height: 20),



              // Avatar & Name

              Row(

                children: [

                  Container(

                    width: 58,

                    height: 58,

                    alignment: Alignment.center,

                    decoration: BoxDecoration(

                      shape: BoxShape.circle,

                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),

                    ),

                    child: Text(

                      member.avatar.length <= 4 ? member.avatar : '🦁',

                      style: const TextStyle(fontSize: 32),

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

                                member.name,

                                style: TextStyle(

                                  fontSize: 18,

                                  fontWeight: FontWeight.bold,

                                  color: isDark ? Colors.white : kDarkText,

                                ),

                                overflow: TextOverflow.ellipsis,

                              ),

                            ),

                            if (member.isMVP) ...[

                              const SizedBox(width: 8),

                              const Text('👑 MVP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),

                            ],

                            if (member.isSlacker) ...[

                              const SizedBox(width: 8),

                              const Text('💤 Slacker', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),

                            ],

                          ],

                        ),

                        const SizedBox(height: 4),

                        Text(

                          'Rank #$rank • 🔥 ${member.streakDays} Day Streak • ⭐ ${member.xp} XP',

                          style: TextStyle(

                            fontSize: 13,

                            color: isDark ? const Color(0xFF94A3B8) : kSecondaryText,

                          ),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 24),



              // Detailed Metric Cards

              Container(

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(

                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                ),

                child: Column(

                  children: [

                    _buildDetailRow(

                      icon: Icons.timer_rounded,

                      color: const Color(0xFF10B981),

                      title: 'Live Study Time Today',

                      value: '${member.studyMinutesToday} mins',

                      subtitle: member.studyMinutesToday >= 60 ? '🔥 High Focus Level' : 'Tackle timer sessions to boost rank',

                      isDark: isDark,

                    ),

                    const Divider(height: 24),

                    _buildDetailRow(

                      icon: Icons.phone_android_rounded,

                      color: isHealthyScreenTime ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),

                      title: 'Live Screen Time Today',

                      value: '${member.screenTimeMinutesToday} mins',

                      subtitle: isHealthyScreenTime ? '✅ Controlled phone usage' : '⚠️ High screen time alert',

                      isDark: isDark,

                    ),

                    const Divider(height: 24),

                    _buildDetailRow(

                      icon: Icons.check_circle_outline_rounded,

                      color: kPrimaryColor,

                      title: 'Habits Completed Today',

                      value: '${member.completedHabitsCount}/5 Habits',

                      subtitle: '${(member.completedHabitsCount / 5 * 100).toInt()}% completed for today',

                      isDark: isDark,

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 20),



              // Action button to Cheer via WhatsApp

              SizedBox(

                width: double.infinity,

                height: 48,

                child: ElevatedButton.icon(

                  style: ElevatedButton.styleFrom(

                    backgroundColor: const Color(0xFF25D366),

                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

                  ),

                  icon: const Icon(Icons.bolt_rounded, color: Colors.white),

                  label: Text(

                    'Cheer ${member.name} on WhatsApp',

                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),

                  ),

                  onPressed: () {

                    Navigator.pop(ctx);

                    if (_squads.isNotEmpty) {

                      SquadService.inviteViaWhatsApp(_squads[_selectedSquadIndex]);

                    }

                  },

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



  Widget _buildDetailRow({

    required IconData icon,

    required Color color,

    required String title,

    required String value,

    required String subtitle,

    required bool isDark,

  }) {

    return Row(

      children: [

        Container(

          width: 40,

          height: 40,

          decoration: BoxDecoration(

            color: color.withValues(alpha: 0.15),

            shape: BoxShape.circle,

          ),

          alignment: Alignment.center,

          child: Icon(icon, color: color, size: 20),

        ),

        const SizedBox(width: 14),

        Expanded(

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                title,

                style: TextStyle(

                  fontSize: 12,

                  color: isDark ? const Color(0xFF94A3B8) : kSecondaryText,

                ),

              ),

              const SizedBox(height: 2),

              Text(

                subtitle,

                style: TextStyle(

                  fontSize: 11,

                  fontStyle: FontStyle.italic,

                  color: isDark ? Colors.white60 : const Color(0xFF64748B),

                ),

              ),

            ],

          ),

        ),

        Text(

          value,

          style: TextStyle(

            fontSize: 16,

            fontWeight: FontWeight.bold,

            color: isDark ? Colors.white : kDarkText,

          ),

        ),

      ],

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

        title: Text(

          LanguageService.tr('squads_title'),

          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),

        ),

        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,

        elevation: 0,

        actions: [

          ValueListenableBuilder<int>(
            valueListenable: AdCreditService.creditsNotifier,
            builder: (context, credits, _) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.4)),
                ),
                child: InkWell(
                  onTap: () => AdCreditService.showRewardedAd(
                    context: context,
                    onRewardGranted: () {},
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          '$credits',
                          style: const TextStyle(
                            color: Color(0xFFFFB300),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '+50 Ad',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          IconButton(

            tooltip: LanguageService.tr('join_squad_btn'),

            icon: const Icon(Icons.group_add_rounded, color: kPrimaryColor),

            onPressed: _showJoinSquadDialog,

          ),

          IconButton(

            tooltip: LanguageService.tr('create_squad_btn'),

            icon: const Icon(Icons.add_circle_outline_rounded, color: kPrimaryColor),

            onPressed: _showCreateSquadDialog,

          ),

        ],

      ),

      body: _squads.isEmpty

          ? Center(

              child: Padding(

                padding: const EdgeInsets.symmetric(horizontal: 24),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    Container(

                      width: 84,

                      height: 84,

                      decoration: BoxDecoration(

                        color: kPrimaryColor.withValues(alpha: 0.1),

                        shape: BoxShape.circle,

                      ),

                      alignment: Alignment.center,

                      child: const Text('🔒', style: TextStyle(fontSize: 42)),

                    ),

                    const SizedBox(height: 18),

                    Text(

                      LanguageService.tr('no_squads_title'),

                      style: TextStyle(

                        fontSize: 20,

                        fontWeight: FontWeight.bold,

                        color: isDark ? Colors.white : kDarkText,

                      ),

                    ),

                    const SizedBox(height: 8),

                    Text(

                      'स्क्वॉड सुरक्षित आणि खाजगी आहेत. फक्त स्क्वॉड कोड टाकूनच सदस्य जॉईन होऊ शकतात आणि एकमेकांची प्रोग्रेस पाहू शकतात.',

                      textAlign: TextAlign.center,

                      style: TextStyle(

                        fontSize: 14,

                        color: isDark ? const Color(0xFF94A3B8) : kSecondaryText,

                        height: 1.4,

                      ),

                    ),

                    const SizedBox(height: 24),

                    Row(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        ElevatedButton.icon(

                          style: ElevatedButton.styleFrom(

                            backgroundColor: kPrimaryColor,

                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

                          ),

                          onPressed: _showCreateSquadDialog,

                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),

                          label: Text(

                            LanguageService.tr('create_squad_btn'),

                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),

                          ),

                        ),

                        const SizedBox(width: 12),

                        OutlinedButton.icon(

                          style: OutlinedButton.styleFrom(

                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

                            side: const BorderSide(color: kPrimaryColor),

                          ),

                          onPressed: _showJoinSquadDialog,

                          icon: const Icon(Icons.vpn_key_rounded, color: kPrimaryColor, size: 18),

                          label: Text(

                            LanguageService.tr('join_squad_btn'),

                            style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),

                          ),

                        ),

                      ],

                    ),

                  ],

                ),

              ),

            )

          : RefreshIndicator(

              onRefresh: () => _refreshActiveSquad(silent: false),

              child: SingleChildScrollView(

                physics: const AlwaysScrollableScrollPhysics(),

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

                        separatorBuilder: (_, _) => const SizedBox(width: 8),

                        itemBuilder: (context, idx) {

                          if (idx == _squads.length) {

                            return ActionChip(

                              avatar: const Icon(Icons.add, size: 16, color: kPrimaryColor),

                              label: Text(LanguageService.tr('create_squad_btn')),

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

                            color: kPrimaryColor.withValues(alpha: 0.3),

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

                                        '${activeSquad.category} • Captain: ${activeSquad.leaderName}',

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

                                        content: Text('${LanguageService.tr('code_copied')} (${activeSquad.code})'),

                                        duration: const Duration(seconds: 1),

                                      ),

                                    );

                                  },

                                  borderRadius: BorderRadius.circular(12),

                                  child: Container(

                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                                    decoration: BoxDecoration(

                                      color: kPrimaryColor.withValues(alpha: 0.15),

                                      borderRadius: BorderRadius.circular(12),

                                      border: Border.all(color: kPrimaryColor.withValues(alpha: 0.4)),

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

                                // Squad Options Menu

                                PopupMenuButton<String>(

                                  icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : kDarkText),

                                  onSelected: (val) {

                                    if (val == 'leave') {

                                      _confirmLeaveSquad(activeSquad);

                                    } else if (val == 'invite') {

                                      SquadService.inviteViaWhatsApp(activeSquad);

                                    }

                                  },

                                  itemBuilder: (ctx) => [

                                    const PopupMenuItem(

                                      value: 'invite',

                                      child: Row(

                                        children: [

                                          Icon(Icons.share_rounded, size: 18, color: Color(0xFF25D366)),

                                          SizedBox(width: 8),

                                          Text('Share Code on WhatsApp'),

                                        ],

                                      ),

                                    ),

                                    const PopupMenuItem(

                                      value: 'leave',

                                      child: Row(

                                        children: [

                                          Icon(Icons.exit_to_app_rounded, size: 18, color: Color(0xFFEF4444)),

                                          SizedBox(width: 8),

                                          Text('Leave Squad', style: TextStyle(color: Color(0xFFEF4444))),

                                        ],

                                      ),

                                    ),

                                  ],

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

                                  backgroundColor: const Color(0xFF25D366),

                                  shape: RoundedRectangleBorder(

                                    borderRadius: BorderRadius.circular(14),

                                  ),

                                  elevation: 3,

                                ),

                                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),

                                label: Text(

                                  LanguageService.tr('invite_whatsapp'),

                                  style: const TextStyle(

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



                      // 3. Squad Live Battle Rankings Header with Real-Time Pill

                      Row(

                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [

                          Row(

                            children: [

                              Text(

                                '🏆 ${LanguageService.tr('battle_standings')} (${activeSquad.members.length})',

                                style: TextStyle(

                                  fontSize: 16,

                                  fontWeight: FontWeight.bold,

                                  color: isDark ? Colors.white : kDarkText,

                                ),

                              ),

                              const SizedBox(width: 8),

                              Container(

                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),

                                decoration: BoxDecoration(

                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),

                                  borderRadius: BorderRadius.circular(10),

                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),

                                ),

                                child: Row(

                                  mainAxisSize: MainAxisSize.min,

                                  children: [

                                    Container(

                                      width: 6,

                                      height: 6,

                                      decoration: const BoxDecoration(

                                        shape: BoxShape.circle,

                                        color: Color(0xFF10B981),

                                      ),

                                    ),

                                    const SizedBox(width: 4),

                                    Text(

                                      _lastSyncedTime != null

                                          ? 'Live Sync • ${DateTime.now().difference(_lastSyncedTime!).inSeconds < 10 ? "Just now" : "${DateTime.now().difference(_lastSyncedTime!).inSeconds}s ago"}'

                                          : 'Live Realtime',

                                      style: const TextStyle(

                                        fontSize: 10,

                                        fontWeight: FontWeight.bold,

                                        color: Color(0xFF10B981),

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                            ],

                          ),

                          if (_isRefreshing)

                            const SizedBox(

                              width: 14,

                              height: 14,

                              child: CircularProgressIndicator(strokeWidth: 2),

                            ),

                        ],

                      ),

                      const SizedBox(height: 12),



                      // 4. Members List

                      ListView.separated(

                        shrinkWrap: true,

                        physics: const NeverScrollableScrollPhysics(),

                        itemCount: activeSquad.members.length,

                        separatorBuilder: (_, _) => const SizedBox(height: 10),

                        itemBuilder: (context, mIdx) {

                          final m = activeSquad.members[mIdx];

                          return InkWell(

                            onTap: () => _showMemberDetailSheet(m, mIdx + 1),

                            borderRadius: BorderRadius.circular(18),

                            child: _buildMemberCard(m, mIdx + 1, isDark),

                          );

                        },

                      ),

                    ],

                  ],

                ),

              ),

            ),

    );

  }



  Widget _buildMemberCard(SquadMember member, int rank, bool isDark) {

    Color cardBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    Color cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;



    if (member.isMVP) {

      cardBorder = const Color(0xFFF59E0B);

      cardBg = isDark ? const Color(0xFF1E1708) : const Color(0xFFFFFBEB);

    } else if (member.isSlacker) {

      cardBorder = const Color(0xFFEF4444).withValues(alpha: 0.6);

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

            color: Colors.black.withValues(alpha: 0.04),

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

              Text(member.avatar.length <= 4 ? member.avatar : '🦁', style: const TextStyle(fontSize: 24)),

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

                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),

                              borderRadius: BorderRadius.circular(6),

                            ),

                            child: Text(

                              LanguageService.tr('mvp_tag'),

                              style: const TextStyle(

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

                              color: const Color(0xFFEF4444).withValues(alpha: 0.2),

                              borderRadius: BorderRadius.circular(6),

                            ),

                            child: Text(

                              LanguageService.tr('slacker_tag'),

                              style: const TextStyle(

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

                      '🔥 ${member.streakDays} ${LanguageService.tr('streak_label')} • ${member.completedHabitsCount}/5 ${LanguageService.tr('habits_label')}',

                      style: TextStyle(

                        fontSize: 12,

                        color: isDark ? const Color(0xFF94A3B8) : kSecondaryText,

                      ),

                    ),

                  ],

                ),

              ),

              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),

            ],

          ),

          const SizedBox(height: 12),



          // Stat counters bar

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [

              _buildMetricChip(

                icon: Icons.timer_rounded,

                label: LanguageService.tr('study_label'),

                value: '${member.studyMinutesToday}m',

                color: const Color(0xFF10B981),

                isDark: isDark,

              ),

              _buildMetricChip(

                icon: Icons.phone_android_rounded,

                label: LanguageService.tr('screen_label'),

                value: '${member.screenTimeMinutesToday}m',

                color: member.screenTimeMinutesToday > 120

                    ? const Color(0xFFEF4444)

                    : const Color(0xFF3B82F6),

                isDark: isDark,

              ),

              _buildMetricChip(

                icon: Icons.check_circle_outline_rounded,

                label: LanguageService.tr('habits_label'),

                value: '${member.completedHabitsCount}/5',

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

