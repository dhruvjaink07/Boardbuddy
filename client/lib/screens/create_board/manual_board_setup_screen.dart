import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/board_list/board_list_bloc.dart';
import '../../blocs/board_list/board_list_event.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/board_model.dart';
import '../../models/column_model.dart';

class ManualBoardSetupScreen extends StatefulWidget {
  final String initialName;

  const ManualBoardSetupScreen({super.key, required this.initialName});

  @override
  State<ManualBoardSetupScreen> createState() => _ManualBoardSetupScreenState();
}

class _ManualBoardSetupScreenState extends State<ManualBoardSetupScreen> {
  late TextEditingController _nameController;
  final TextEditingController _descController = TextEditingController();
  final List<String> _stages = ['To Do', 'In Progress', 'Done'];
  String _selectedTheme = 'Forest';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialName.isNotEmpty
          ? widget.initialName
          : 'Portfolio Website',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
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
        title: Column(
          children: [
            Text(
              'Manual Board Setup',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              'Step 2 of 2',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Board Name
              Text('Board Name', style: AppTypography.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g., Portfolio Website, Internship Tracker',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Define Stages (Kanban Columns)
              Text('Define Stages (Kanban Columns)', style: AppTypography.titleSmall),
              const SizedBox(height: 12),
              ...List.generate(_stages.length, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      // Orange Index Pill
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.orangePrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _stages[index],
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.textMuted, size: 20),
                        onPressed: () {
                          if (_stages.length > 1) {
                            setState(() => _stages.removeAt(index));
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),

              // + Add Stage Button
              GestureDetector(
                onTap: _showAddStageDialog,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.orangePrimary.withValues(alpha: 0.5),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: AppColors.orangePrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Add Stage',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.orangePrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Add Descriptions (Optional)
              Text('Add Descriptions (Optional)', style: AppTypography.titleSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'This board will be used for...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Choose Board Theme
              Text('Choose Board Theme', style: AppTypography.titleSmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  _themeThumbnail('Forest', AppColors.accentGreen),
                  const SizedBox(width: 12),
                  _themeThumbnail('Space', AppColors.accentBlue),
                  const SizedBox(width: 12),
                  _themeThumbnail('Neon', AppColors.accentPurple),
                ],
              ),
              const SizedBox(height: 24),

              // Preview
              Text('Preview', style: AppTypography.titleSmall),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.trim().isEmpty
                          ? 'Portfolio Website'
                          : _nameController.text.trim(),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _stages.map((stage) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              stage,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
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
                  onPressed: _finalizeBoard,
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

  Widget _themeThumbnail(String name, Color color) {
    final isSelected = _selectedTheme == name;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTheme = name),
        child: Column(
          children: [
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.white : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Icon(Icons.palette_outlined, color: color, size: 28),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStageDialog() {
    final stageController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Column Stage', style: AppTypography.titleMedium),
        content: TextField(
          controller: stageController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'e.g. Review, QA, Backlog'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final stage = stageController.text.trim();
              if (stage.isNotEmpty) {
                setState(() => _stages.add(stage));
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _finalizeBoard() {
    final name = _nameController.text.trim().isEmpty
        ? 'Portfolio Website'
        : _nameController.text.trim();
    final boardId = 'board-${DateTime.now().millisecondsSinceEpoch}';

    final columns = _stages.asMap().entries.map((entry) {
      return ColumnModel(
        id: 'col-${entry.key}-$boardId',
        boardId: boardId,
        title: entry.value,
        position: entry.key,
      );
    }).toList();

    final newBoard = BoardModel(
      id: boardId,
      name: name,
      description: _descController.text.trim(),
      accentColor: _selectedTheme == 'Forest'
          ? AppColors.accentGreen
          : (_selectedTheme == 'Space'
              ? AppColors.accentBlue
              : AppColors.accentPurple),
      iconType: 'pen',
      updatedTimeAgo: 'Just now',
      progress: 0,
      columns: columns,
    );

    context.read<BoardListBloc>().add(CreateBoardSubmitted(newBoard));
    // Pop back to home
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Board "$name" setup completed!'),
        backgroundColor: AppColors.orangePrimary,
      ),
    );
  }
}
