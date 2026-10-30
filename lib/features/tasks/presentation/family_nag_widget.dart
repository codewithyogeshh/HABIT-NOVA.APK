import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synvero/core/services/language_service.dart';

/// Playful and affectionate "Family Nag & Scold" card.
///
/// When the user adds tasks and leaves them incomplete, HabitNova lovingly
/// teases and reprimands them in their native language (Marathi, Hindi, English)
/// like a caring Indian mom, dad, or big brother. When all tasks are finished,
/// it showers them with proud family blessings and appreciation!
class FamilyNagWidget extends StatefulWidget {
  final int pendingCount;
  final int totalCount;
  final String username;
  final VoidCallback? onFocusWork;

  const FamilyNagWidget({
    super.key,
    required this.pendingCount,
    required this.totalCount,
    required this.username,
    this.onFocusWork,
  });

  @override
  State<FamilyNagWidget> createState() => _FamilyNagWidgetState();
}

class _FamilyNagWidgetState extends State<FamilyNagWidget> {
  int _quoteIndex = 0;

  List<String> _getMarathiNags(String name) => [
    "अरे $name, कामं फक्त लिहून ठेवायला काय मेडल मिळतं का? उठ आणि आधी ते काम पूर्ण कर!",
    "दोन-दोन तास झाले, टास्क तसाच पडून आहे! मोबाईलमध्ये तोंड घालून बसण्यापेक्षा काम संपव आधी!",
    "उद्या करू, परवा करू... ही आळशीपणाची सवय कधी सोडणार? आई बघतेय इकडे, आत्ताच्या आत्ता पूर्ण कर!",
    "कामं पेंडिंग ठेवून निवांत कसा बसतोस? आधी टास्क पूर्ण कर, मगच बाकीचा आराम!",
    "एवढी कामं बाकी आहेत, कधी करणार? वेळेवर काम संपवलं नाही तर चहा-नाश्ता बंद होईल! ☕❌",
    "अरे देवा! $name, कामाची यादी बघून मला चक्कर येतेय! स्वतःशी तरी प्रामाणिक राहा, पटकन संपव!",
  ];

  List<String> _getHindiNags(String name) => [
    "अरे $name! सिर्फ टास्क जोड़ने से काम नहीं होता! उठो और खत्म करो इसे!",
    "इतना काम पेंडिंग पड़ा है और तुम आराम से फोन चला रहे हो? मम्मी को आवाज लगाऊं क्या?",
    "कल करेंगे, परसों करेंगे... ये बहाने कब बंद होंगे? चलो जल्दी हाथ चलाओ!",
    "टास्क लिस्ट देखकर मेरी बीपी बढ़ रही है! पहले काम निपटाओ, फिर रील देखना!",
    "जब तक ये टास्क खत्म नहीं होगा, तब तक कोई आराम नहीं! समझे या समझाऊं?",
    "अरे $name, आलस छोड़ो और काम पर लगो! घरवाले सब देख रहे हैं!",
  ];

  List<String> _getEnglishNags(String name) => [
    "Hey $name! Adding tasks doesn't mean they complete themselves! Put the phone down and finish them!",
    "Look at those pending tasks staring at your soul! Stop procrastinating and get to work!",
    "Do you want Mom to come in and yell at you? Go finish that pending task right now!",
    "Procrastination level: 100! Get up, clear that task, and make us proud!",
    "No snacks, no doomscrolling until this task is checked off! Chop chop!",
    "Come on $name! Future you is begging you to finish this right now!",
  ];

  List<String> _getMarathiPraises(String name) => [
    "शाब्बास माझ्या वाघा! 🦁 आजची सगळी कामं वेळेवर पूर्ण केलीस! असाच पुढे जा, खूप मोठा होणार तू! ❤️",
    "कौतुक करावं तेवढं कमी आहे $name! सर्व टास्क संपवून मोकळा झालास. आता मस्त आराम कर! 🌟",
  ];

  List<String> _getHindiPraises(String name) => [
    "शाबाश शेर! 🌟 आज के सारे काम पूरे कर लिए! बहुत गर्व है तुम पर $name, ऐसे ही आगे बढ़ते रहो! 👏",
    "कमाल कर दिया $name! सारे टास्क फिनिश! आज तो पार्टी बनती है! 🚀",
  ];

  List<String> _getEnglishPraises(String name) => [
    "Proud of you $name! 🏆 You completed every single task today! Keep shining, superstar!",
    "Outstanding discipline $name! All tasks knocked out clean! Take a well-deserved breather! 🌟",
  ];

  String _getCurrentMessage() {
    final lang = LanguageService.currentLanguageCode;
    final name = widget.username.isNotEmpty ? widget.username : 'Champ';

    if (widget.pendingCount == 0 && widget.totalCount > 0) {
      List<String> praises;
      if (lang == LanguageService.marathi) {
        praises = _getMarathiPraises(name);
      } else if (lang == LanguageService.hindi) {
        praises = _getHindiPraises(name);
      } else {
        praises = _getEnglishPraises(name);
      }
      return praises[_quoteIndex % praises.length];
    } else {
      List<String> nags;
      if (lang == LanguageService.marathi) {
        nags = _getMarathiNags(name);
      } else if (lang == LanguageService.hindi) {
        nags = _getHindiNags(name);
      } else {
        nags = _getEnglishNags(name);
      }
      return nags[_quoteIndex % nags.length];
    }
  }

  void _cycleQuote() {
    HapticFeedback.mediumImpact();
    setState(() {
      _quoteIndex = _quoteIndex + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalCount == 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAllDone = widget.pendingCount == 0 && widget.totalCount > 0;

    final primaryAccent = isAllDone
        ? const Color(0xFF10B981) // Emerald Green
        : (widget.pendingCount >= 3 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)); // Red or Warm Amber

    final cardBg = isDark
        ? (isAllDone
            ? const Color(0xFF042018)
            : (widget.pendingCount >= 3 ? const Color(0xFF260C12) : const Color(0xFF201306)))
        : (isAllDone
            ? const Color(0xFFECFDF5)
            : (widget.pendingCount >= 3 ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB)));

    final borderColor = primaryAccent.withValues(alpha: isDark ? 0.45 : 0.35);

    final title = isAllDone
        ? LanguageService.tr('family_praise_title')
        : LanguageService.tr('family_nag_title');

    final message = _getCurrentMessage();

    final statusTag = isAllDone
        ? LanguageService.tr('all_tasks_completed')
        : '${widget.pendingCount} ${LanguageService.tr('pending_tasks')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryAccent.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryAccent, width: 1.2),
                ),
                alignment: Alignment.center,
                child: Text(
                  isAllDone
                      ? '🌟'
                      : (widget.pendingCount >= 3 ? '😤' : '📢'),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryAccent,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusTag,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _cycleQuote,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 14, color: primaryAccent),
                      const SizedBox(width: 4),
                      Text(
                        isAllDone ? 'पुन्हा पहा' : LanguageService.tr('scold_btn').split(' ').first,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Expressive message box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: primaryAccent.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              '“$message”',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
          ),

          if (!isAllDone) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onFocusWork?.call();
                    },
                    icon: const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                    label: Text(
                      LanguageService.tr('work_btn'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _cycleQuote,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryAccent.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    LanguageService.tr('scold_btn'),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
