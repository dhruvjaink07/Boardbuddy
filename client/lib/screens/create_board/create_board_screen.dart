import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/board_list/board_list_bloc.dart';
import '../../blocs/board_list/board_list_event.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../models/board_model.dart';
import '../../models/card_model.dart';
import '../../models/column_model.dart';
import '../../models/generated_board_plan.dart';
import '../../repositories/board_repository.dart';
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
  bool _isGenerating = false;
  String _selectedTheme = 'Purple Galaxy';
  GeneratedBoardPlan? _generatedPlan;

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

  final List<String> _promptTemplates = [
    '📱 Mobile Banking App with Auth and Transfers',
    '🚀 Product Launch and Growth Marketing Plan',
    '🎓 Final Year Computer Science Research Project',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generatePlanWithAi() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a goal or prompt describing what you want to build.'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final repository = context.read<BoardRepository>();
      final plan = await repository.generateBoardPlan(prompt);

      if (!mounted) return;
      setState(() {
        _generatedPlan = plan;
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = plan.boardName;
        }
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Generated ${plan.columns.length} columns and ${plan.cards.length} task cards!'),
          backgroundColor: AppColors.accentPurple,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generation failed: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentW = Responsive.contentWidth(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
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
        child: Center(
          child: SizedBox(
            width: contentW,
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
                      hintText: 'e.g., Final Year Project, Mobile App',
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
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildStartMethodCard(
                            title: 'AI Goal-to-Board',
                            desc: 'Describe your goal, we structure columns & cards',
                            icon: Icons.psychology_rounded,
                            isSelected: _useAiPrompt,
                            onTap: () => setState(() => _useAiPrompt = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStartMethodCard(
                            title: 'Manual Setup',
                            desc: 'Create your own stages and cards from scratch',
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
                  ),
                  const SizedBox(height: 20),

                  // Prompt Input Field (when AI Prompt is selected)
                  if (_useAiPrompt) ...[
                    Text(
                      'AI Project Goal Description',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _promptController,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Describe your project goal, scope, and target outcomes...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Quick prompt template chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _promptTemplates.map((template) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ActionChip(
                                    backgroundColor: AppColors.surfaceElevated,
                                    label: Text(
                                      template,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                    onPressed: () {
                                      _promptController.text = template;
                                      setState(() {});
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Generate with AI Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isGenerating ? null : _generatePlanWithAi,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                        label: Text(
                          _isGenerating ? 'Structuring Kanban Board...' : 'Generate Plan with AI',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
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
                    height: 145,
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
                            padding: const EdgeInsets.all(12),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Board Preview',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_generatedPlan != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentPurple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'AI Planned',
                            style: TextStyle(
                              color: AppColors.accentPurple,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
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
                        _generatedPlan != null ? 'Create & Save Board' : 'Create Board',
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
        padding: const EdgeInsets.all(12),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? AppColors.accentPurple : AppColors.textMuted,
                size: 26),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
        ? (_generatedPlan?.boardName ?? 'Final Year Project')
        : _nameController.text.trim();

    final columns = _generatedPlan?.columns ?? ['To Do', 'In Progress', 'Done'];
    final cards = _generatedPlan?.cards ?? [];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${columns.length} columns',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          if (_generatedPlan?.summary != null) ...[
            const SizedBox(height: 6),
            Text(
              _generatedPlan!.summary,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),

          // Horizontal scrollable column preview boxes (prevents text clipping on any screen width)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: columns.asMap().entries.map((entry) {
                final colIdx = entry.key;
                final colName = entry.value;
                final colCardCount = cards.where((c) => c.columnIndex == colIdx).length;
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              colName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.orangePrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$colCardCount',
                              style: const TextStyle(
                                color: AppColors.orangePrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Mini preview cards
                      ...cards
                          .where((c) => c.columnIndex == colIdx)
                          .take(2)
                          .map((c) => Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  c.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              )),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _createBoard() {
    final name = _nameController.text.trim().isEmpty
        ? (_generatedPlan?.boardName ?? 'My New Project')
        : _nameController.text.trim();

    final boardId = 'board-${DateTime.now().millisecondsSinceEpoch}';

    List<ColumnModel> finalColumns = [];
    if (_generatedPlan != null) {
      finalColumns = _generatedPlan!.columns.asMap().entries.map((entry) {
        final colIdx = entry.key;
        final colTitle = entry.value;
        final colId = 'col-$colIdx-$boardId';

        final matchingCards = _generatedPlan!.cards
            .where((c) => c.columnIndex == colIdx)
            .toList()
            .asMap()
            .entries
            .map((cardEntry) {
          final cardIdx = cardEntry.key;
          final genCard = cardEntry.value;

          return CardModel(
            id: 'card-$colIdx-$cardIdx-$boardId',
            columnId: colId,
            boardId: boardId,
            title: genCard.title,
            description: genCard.description,
            priority: genCard.priority,
            position: cardIdx,
            status: colTitle.toLowerCase().contains('done')
                ? CardStatus.done
                : (colTitle.toLowerCase().contains('prog')
                    ? CardStatus.inProgress
                    : CardStatus.todo),
            estimateMinutes: genCard.estimateMinutes,
            labels: genCard.labels,
            assigneeNames: const ['Dhruv Jain'],
            assigneeAvatars: const ['https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'],
          );
        }).toList();

        return ColumnModel(
          id: colId,
          boardId: boardId,
          title: colTitle,
          position: colIdx,
          cards: matchingCards,
        );
      }).toList();
    } else {
      finalColumns = [
        ColumnModel(id: 'col-1-$boardId', boardId: boardId, title: 'To Do', position: 0),
        ColumnModel(id: 'col-2-$boardId', boardId: boardId, title: 'In Progress', position: 1),
        ColumnModel(id: 'col-3-$boardId', boardId: boardId, title: 'Done', position: 2),
      ];
    }

    final newBoard = BoardModel(
      id: boardId,
      name: name,
      description: _promptController.text.trim(),
      accentColor: AppColors.accentPurple,
      iconType: 'rocket',
      updatedTimeAgo: 'Just now',
      progress: 0,
      columns: finalColumns,
    );

    context.read<BoardListBloc>().add(CreateBoardSubmitted(newBoard));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Board "$name" with ${finalColumns.length} columns created successfully!'),
        backgroundColor: AppColors.orangePrimary,
      ),
    );
  }
}
