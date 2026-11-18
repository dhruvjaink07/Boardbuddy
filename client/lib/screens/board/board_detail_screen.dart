import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/board_detail/board_detail_bloc.dart';
import '../../blocs/board_detail/board_detail_event.dart';
import '../../blocs/board_detail/board_detail_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/card_model.dart';
import '../../models/column_model.dart';
import '../../repositories/board_repository.dart';
import '../task_detail/task_detail_sheet.dart';
import 'board_chat_screen.dart';
import 'board_settings_screen.dart';
import 'draggable_board_insights_sheet.dart';

class BoardDetailScreen extends StatefulWidget {
  final String boardId;

  const BoardDetailScreen({super.key, required this.boardId});

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  int _selectedColumnIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<BoardDetailBloc>().add(LoadBoardDetail(widget.boardId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardDetailBloc, BoardDetailState>(
      builder: (context, state) {
        if (state is BoardDetailLoading || state is BoardDetailInitial) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.orangePrimary),
            ),
          );
        }

        if (state is BoardDetailError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(),
            body: Center(
              child: Text(state.message, style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        final board = (state as BoardDetailLoaded).board;
        final columns = board.columns;
        final currentColumn = columns.isNotEmpty && _selectedColumnIndex < columns.length
            ? columns[_selectedColumnIndex]
            : null;

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
              board.name,
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.orangePrimary, size: 22),
                tooltip: 'Deerflow Insights',
                onPressed: () {
                  DraggableBoardInsightsSheet.show(
                    context,
                    board.id,
                    context.read<BoardRepository>(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BoardChatScreen(boardName: board.name),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BoardSettingsScreen(board: board),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Horizontal Column Headers Tab Bar
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: columns.length,
                    itemBuilder: (context, index) {
                      final col = columns[index];
                      final isSelected = index == _selectedColumnIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColumnIndex = index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    col.title,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.surfaceElevated
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${col.cards.length}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.orangePrimary
                                            : AppColors.textMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (isSelected)
                                Container(
                                  height: 3,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.orangePrimary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Responsive Kanban Cards View
                Expanded(
                  child: currentColumn == null || currentColumn.cards.isEmpty
                      ? _buildEmptyColumn(currentColumn?.title ?? 'Column')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                          itemCount: currentColumn.cards.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final card = currentColumn.cards[index];
                            return _buildTaskCard(context, card, currentColumn, columns);
                          },
                        ),
                ),
              ],
            ),
          ),
          bottomSheet: Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangePrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _showQuickAddTaskDialog(context, currentColumn),
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      label: Text(
                        'Add New Task',
                        style: AppTypography.buttonText.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.orangePrimary.withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.orangePrimary, size: 22),
                    tooltip: 'Drag up Deerflow Insights',
                    onPressed: () {
                      DraggableBoardInsightsSheet.show(
                        context,
                        board.id,
                        context.read<BoardRepository>(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    CardModel card,
    ColumnModel currentColumn,
    List<ColumnModel> allColumns,
  ) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => TaskDetailSheet(card: card),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Move Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    card.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded,
                      color: AppColors.textMuted, size: 20),
                  color: AppColors.surfaceElevated,
                  onSelected: (targetColId) {
                    context.read<BoardDetailBloc>().add(
                          MoveCardRequested(
                            cardId: card.id,
                            sourceColumnId: currentColumn.id,
                            targetColumnId: targetColId,
                            newPosition: 0,
                          ),
                        );
                  },
                  itemBuilder: (context) {
                    return allColumns
                        .where((c) => c.id != currentColumn.id)
                        .map(
                          (c) => PopupMenuItem(
                            value: c.id,
                            child: Text(
                              'Move to ${c.title}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList();
                  },
                ),
              ],
            ),

            if (card.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                card.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Chips: Priority & Category
            Row(
              children: [
                _buildPriorityChip(card.priority),
                if (card.category != null && card.category!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card.category!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  card.subtasks.isNotEmpty
                      ? '${card.subtasks.where((s) => s.isCompleted).length}/${card.subtasks.length}'
                      : '${card.progress}%',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: card.progress / 100,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orangePrimary),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 14),

            // Due Date & Assignee Avatar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (card.dueDateText != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        card.dueDateText!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),

                if (card.assigneeAvatars.isNotEmpty)
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(card.assigneeAvatars.first),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(CardPriority priority) {
    Color color;
    String label;
    switch (priority) {
      case CardPriority.urgent:
        color = AppColors.accentRed;
        label = 'Urgent';
        break;
      case CardPriority.high:
        color = AppColors.orangePrimary;
        label = 'High Priority';
        break;
      case CardPriority.medium:
        color = AppColors.accentYellow;
        label = 'Medium';
        break;
      case CardPriority.low:
        color = AppColors.accentCyan;
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyColumn(String colTitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 50, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No tasks in $colTitle',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showQuickAddTaskDialog(BuildContext context, ColumnModel? column) {
    if (column == null) return;
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Add Task to ${column.title}', style: AppTypography.titleMedium),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Task Title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = titleController.text.trim();
              if (text.isNotEmpty) {
                final newCard = CardModel(
                  id: 'card-${DateTime.now().millisecondsSinceEpoch}',
                  boardId: column.boardId,
                  columnId: column.id,
                  title: text,
                  priority: CardPriority.medium,
                  dueDateText: 'Due Soon',
                );
                context.read<BoardDetailBloc>().add(AddCardRequested(newCard));
                Navigator.of(dialogCtx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
