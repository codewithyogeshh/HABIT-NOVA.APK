import 'package:flutter/material.dart';
import 'package:synvero/core/services/avatar_service.dart';

/// Interactive modal sheet to select male/female preset 3D avatars or upload custom photos.
/// Includes gender selection and filtered avatar display matching user's account.
class AvatarPickerSheet extends StatefulWidget {
  const AvatarPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AvatarPickerSheet(),
    );
  }

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final gender = AvatarService.currentGender;
    final isFemale = gender == 'female' || AvatarService.currentAvatar.contains('female') || AvatarService.currentAvatar.contains('_f');
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: isFemale ? 1 : 0,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final newGender = _tabController.index == 1 ? 'female' : 'male';
        AvatarService.setGender(newGender);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onAvatarSelected(String path) async {
    await AvatarService.setAvatar(path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated! ✨'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF0D9488),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isUploading = true);
    final success = await AvatarService.pickFromGallery();
    setState(() => _isUploading = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custom photo set as profile picture! 📸'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF0D9488),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickFromCamera() async {
    setState(() => _isUploading = true);
    final success = await AvatarService.pickFromCamera();
    setState(() => _isUploading = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo captured and set! 📷'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF0D9488),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF071728) : Colors.white;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);
    final tabBg = isDark ? const Color(0xFF030814) : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.face_retouching_natural_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Avatar',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select gender (Male / Female) to see avatars',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: subtextColor),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Gender Tabs (Male / Female)
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: tabBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: subtextColor,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.male_rounded, size: 19),
                      SizedBox(width: 6),
                      Text('Male Avatars 👨'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.female_rounded, size: 19),
                      SizedBox(width: 6),
                      Text('Female Avatars 👩'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tab content
          SizedBox(
            height: 190,
            child: ValueListenableBuilder<String>(
              valueListenable: AvatarService.currentAvatarNotifier,
              builder: (context, currentPath, _) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAvatarRow(AvatarService.maleAvatars, currentPath),
                    _buildAvatarRow(AvatarService.femaleAvatars, currentPath),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: borderColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR UPLOAD OWN PHOTO',
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(child: Divider(color: borderColor)),
            ],
          ),

          const SizedBox(height: 16),

          // Camera & Gallery Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickFromGallery,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Choose Photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickFromCamera,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Take Selfie'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAvatarRow(List<Map<String, String>> avatars, String currentPath) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF030814) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF0E3D48) : const Color(0xFFE2E8F0);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final item = avatars[index];
        final path = item['path']!;
        final name = item['name']!;
        final tag = item['tag']!;
        final isSelected = currentPath == path;

        return GestureDetector(
          onTap: () => _onAvatarSelected(path),
          child: Container(
            width: 114,
            margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? const Color(0xFF00F0FF) : borderColor,
                width: isSelected ? 2.2 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00F0FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF030814),
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF00F0FF)
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00F0FF),
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
}
