import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/board_list/board_list_bloc.dart';
import '../../blocs/board_list/board_list_event.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/board_model.dart';
import '../../models/column_model.dart';
import 'manual_board_setup_screen.dart';

class CreateBoardScreen extends StatefulWidget {
  const CreateBoardScreen({super.key});

  @override
  State<CreateBoardScreen> createState() => _CreateBoardScreenState();
}

class _CreateBoardScreenState extends State<CreateBoardScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  bool _useAiPrompt = true;
  String _selectedTheme = 'Purple Galaxy';

  final List<Map<String, dynamic>> _themes = [
    {
      'name': 'Purple Galaxy',
      'sub': 'Research & Study',
      'color': AppColors.accentPurple,
      'icon': Icons.auto_awesome_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      ),
    },
    {
      'name': 'Forest Green',
      'sub': 'Travel & Nature',
      'color': AppColors.accentGreen,
      'icon': Icons.eco_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF047857)],
      ),
    },
    {
      'name': 'Neon Pink',
      'sub': 'Event & Design',
      'color': Color(0xFFEC4899),
      'icon': Icons.bolt_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
      ),
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
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
          'Create New Board',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Board Name Input
              Text(
                'Board Name',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g., Final Year Project, Marketing Plan',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Choose How to Start Section
              Text(
                'Choose How to Start',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStartMethodCard(
                      title: 'AI Prompt\nGenerator',
                      desc: 'Describe your goal, we\'ll build your board',
                      icon: Icons.psychology_rounded,
                      isSelected: _useAiPrompt,
                      onTap: () => setState(() => _useAiPrompt = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStartMethodCard(
                      title: 'Manual\nSetup',
                      desc: 'Create your own stages from scratch',
                      icon: Icons.edit_note_rounded,
                      isSelected: !_useAiPrompt,
                      onTap: () {
                        setState(() => _useAiPrompt = false);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ManualBoardSetupScreen(
                              initialName: _nameController.text.trim(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Prompt Input Field (when AI Prompt is selected)
              if (_useAiPrompt) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _promptController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Write a short prompt describing what you want to achieve...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Pick a Board Theme
              Text(
                'Pick a Board Theme',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _themes.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final theme = _themes[index];
                    final isSelected = _selectedTheme == theme['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedTheme = theme['name']);
                      },
                      child: Container(
                        width: 130,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: theme['gradient'] as LinearGradient,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(theme['icon'] as IconData,
                                color: Colors.white, size: 26),
                            const Spacer(),
                            Text(
                              theme['name'] as String,
                              style: AppTypography.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              theme['sub'] as String,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Preview Section
              Text(
                'Preview',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildBoardPreview(),
              const SizedBox(height: 32),

              // Create Board Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangePrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _createBoard,
                  child: Text(
                    'Create Board',
                    style: AppTypography.buttonText.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartMethodCard({
    required String title,
    required String desc,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentPurple : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: isSelected ? AppColors.accentPurple : AppColors.textMuted,
                size: 26),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardPreview() {
    final title = _nameController.text.trim().isEmpty
        ? 'Final Year Project'
        : _nameController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF291E3B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF563682)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _previewColumnBox('To Do'),
              const SizedBox(width: 8),
              _previewColumnBox('In Progress'),
              const SizedBox(width: 8),
              _previewColumnBox('Done'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewColumnBox(String label) {
    return Expanded(
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _createBoard() {
    final name = _nameController.text.trim().isEmpty
        ? 'My New Project'
        : _nameController.text.trim();

    final boardId = 'board-${DateTime.now().millisecondsSinceEpoch}';

    final newBoard = BoardModel(
      id: boardId,
      name: name,
      description: _promptController.text.trim(),
      accentColor: AppColors.accentPurple,
      iconType: 'rocket',
      updatedTimeAgo: 'Just now',
      progress: 0,
      columns: [
        ColumnModel(id: 'col-1-$boardId', boardId: boardId, title: 'To Do', position: 0),
        ColumnModel(id: 'col-2-$boardId', boardId: boardId, title: 'In Progress', position: 1),
        ColumnModel(id: 'col-3-$boardId', boardId: boardId, title: 'Done', position: 2),
      ],
    );

    context.read<BoardListBloc>().add(CreateBoardSubmitted(newBoard));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Board "$name" created successfully!'),
        backgroundColor: AppColors.orangePrimary,
      ),
    );
  }
}
