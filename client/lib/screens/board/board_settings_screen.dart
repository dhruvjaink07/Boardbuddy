import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/board_list/board_list_bloc.dart';
import '../../blocs/board_list/board_list_event.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/board_model.dart';

class BoardSettingsScreen extends StatefulWidget {
  final BoardModel board;

  const BoardSettingsScreen({super.key, required this.board});

  @override
  State<BoardSettingsScreen> createState() => _BoardSettingsScreenState();
}

class _BoardSettingsScreenState extends State<BoardSettingsScreen> {
  late TextEditingController _nameController;
  int _activeThemeIndex = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.board.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Board Settings',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: CHANGE THEME
              Text(
                'CHANGE THEME',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.orangePrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _themeCard(
                      title: 'Dark',
                      image: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?w=300',
                      isActive: _activeThemeIndex == 0,
                      onTap: () => setState(() => _activeThemeIndex = 0),
                    ),
                    const SizedBox(width: 14),
                    _themeCard(
                      title: 'Desert',
                      image: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?w=300',
                      isActive: _activeThemeIndex == 1,
                      onTap: () => setState(() => _activeThemeIndex = 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Section: RENAME BOARD
              Text(
                'RENAME BOARD',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.orangePrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintText: 'Enter a new name for your board',
                    suffixIcon: Icon(Icons.edit_outlined,
                        color: AppColors.textMuted, size: 20),
                  ),
                ),
              ),
              const Spacer(),

              // Section: DANGER ZONE
              Text(
                'DANGER ZONE',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.orangePrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _confirmDeleteBoard,
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white),
                        label: Text(
                          'Delete Board',
                          style: AppTypography.buttonText.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This action cannot be undone',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeCard({
    required String title,
    required String image,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 170,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? AppColors.orangePrimary : AppColors.border,
                width: isActive ? 2 : 1,
              ),
              image: DecorationImage(
                image: NetworkImage(image),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                if (isActive)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orangePrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBoard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Board?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to permanently delete this board and its tasks?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () {
              context.read<BoardListBloc>().add(DeleteBoardRequested(widget.board.id));
              Navigator.of(ctx).pop(); // pop dialog
              Navigator.of(context).pop(); // pop settings
              Navigator.of(context).pop(); // pop board detail back to home
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
