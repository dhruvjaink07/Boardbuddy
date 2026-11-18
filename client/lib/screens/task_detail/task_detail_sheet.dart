import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/board_detail/board_detail_bloc.dart';
import '../../blocs/board_detail/board_detail_event.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/card_model.dart';
import '../../models/checklist_item_model.dart';
import '../../models/comment_model.dart';

class TaskDetailSheet extends StatefulWidget {
  final CardModel card;

  const TaskDetailSheet({super.key, required this.card});

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final TextEditingController _commentController = TextEditingController();
  late List<ChecklistItem> _subtasks;
  late List<Comment> _comments;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card.title);
    _descController = TextEditingController(text: widget.card.description);
    _subtasks = List.from(widget.card.subtasks);
    _comments = List.from(widget.card.comments);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _subtasks.where((s) => s.isCompleted).length;
    final totalCount = _subtasks.length;
    final progressVal = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Task Details',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // Editable Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            style: AppTypography.headlineMedium.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const Icon(Icons.edit_outlined,
                            color: AppColors.orangePrimary, size: 20),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Description Input
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _descController,
                        maxLines: 3,
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Add description...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Chips: Priority & Category
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.orangePrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'High Priority',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6E3618),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Design',
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFFFFB186),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Due Date
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: AppColors.orangePrimary),
                        const SizedBox(width: 10),
                        Text(
                          widget.card.dueDateText ?? 'Due: Oct 15, 2024',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Assignee
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                            widget.card.assigneeAvatars.isNotEmpty
                                ? widget.card.assigneeAvatars.first
                                : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.card.assigneeNames.isNotEmpty
                                  ? widget.card.assigneeNames.first
                                  : 'Sarah Cooper',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Lead Designer',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Subtasks Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtasks ($completedCount/$totalCount)',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressVal,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.orangePrimary),
                              minHeight: 5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Checklist Items
                    ..._subtasks.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  final idx = _subtasks.indexWhere((s) => s.id == item.id);
                                  if (idx != -1) {
                                    _subtasks[idx] = item.copyWith(
                                      isCompleted: !item.isCompleted,
                                    );
                                  }
                                });
                                context.read<BoardDetailBloc>().add(
                                      ToggleSubtaskRequested(
                                        cardId: widget.card.id,
                                        subtaskId: item.id,
                                      ),
                                    );
                              },
                              child: Icon(
                                item.isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: item.isCompleted
                                    ? AppColors.orangePrimary
                                    : AppColors.textMuted,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: AppTypography.bodyMedium.copyWith(
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: item.isCompleted
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Add Subtask button
                    GestureDetector(
                      onTap: _showAddSubtaskDialog,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded,
                                color: AppColors.orangePrimary, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Add Subtask',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.orangePrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Attachments Section
                    Text(
                      'Attachments (${widget.card.attachmentCount > 0 ? widget.card.attachmentCount : 3})',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _attachmentTile(Icons.image_outlined),
                        const SizedBox(width: 10),
                        _attachmentTile(Icons.description_outlined),
                        const SizedBox(width: 10),
                        _attachmentTile(Icons.attach_file_rounded),
                        const SizedBox(width: 10),
                        _attachmentTile(Icons.add_rounded, isAdd: true),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orangePrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          final updatedCard = widget.card.copyWith(
                            title: _titleController.text.trim(),
                            description: _descController.text.trim(),
                            subtasks: _subtasks,
                          );
                          context.read<BoardDetailBloc>().add(UpdateCardRequested(updatedCard));
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task changes saved!')),
                          );
                        },
                        child: Text(
                          'Save Changes',
                          style: AppTypography.buttonText.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Comments Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Comments (${_comments.length})',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'View all',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.orangePrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Comments List
                    ..._comments.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(
                                c.authorAvatar ??
                                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        c.authorName,
                                        style: AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        c.timeAgo,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.body,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Add Comment Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_rounded,
                                color: AppColors.orangePrimary),
                            onPressed: _addComment,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _attachmentTile(IconData icon, {bool isAdd = false}) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAdd ? AppColors.orangePrimary : AppColors.border,
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: isAdd ? AppColors.orangePrimary : AppColors.textSecondary,
        size: 22,
      ),
    );
  }

  void _showAddSubtaskDialog() {
    final subtaskController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Add Subtask', style: AppTypography.titleMedium),
        content: TextField(
          controller: subtaskController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Subtask title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final title = subtaskController.text.trim();
              if (title.isNotEmpty) {
                setState(() {
                  _subtasks.add(ChecklistItem(
                    id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
                    cardId: widget.card.id,
                    title: title,
                  ));
                });
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.add(Comment(
        id: 'com-${DateTime.now().millisecondsSinceEpoch}',
        cardId: widget.card.id,
        authorName: 'Dhruv',
        authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        body: text,
        timeAgo: 'Just now',
        createdAt: DateTime.now(),
      ));
      _commentController.clear();
    });
  }
}
