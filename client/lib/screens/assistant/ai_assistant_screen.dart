import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/ai_assistant/ai_assistant_bloc.dart';
import '../../blocs/ai_assistant/ai_assistant_event.dart';
import '../../blocs/ai_assistant/ai_assistant_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();

  final List<String> _categories = ['All', 'Personal', 'Work', 'Shopping'];
  final List<String> _styles = ['Classic', 'Orbit', 'Fluid'];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiAssistantBloc, AiAssistantState>(
      listener: (context, state) {
        if (state is AiAssistantSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.accentPurple,
            ),
          );
        }
      },
      builder: (context, state) {
        final activeCat = state is AiAssistantInitial
            ? state.activeCategory
            : (state is AiAssistantThinking
                ? state.activeCategory
                : (state as AiAssistantSuccess).activeCategory);

        final activeStyle = state is AiAssistantInitial
            ? state.activeStyle
            : (state is AiAssistantThinking
                ? state.activeStyle
                : (state as AiAssistantSuccess).activeStyle);

        final isThinking = state is AiAssistantThinking;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Top App Bar: Title & Avatar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.accentPurple,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'AI Assistant',
                            style: AppTypography.headlineMedium.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                        ),
                      ),
                    ],
                  ),
                ),

                // Prompt Input Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _promptController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          context
                              .read<AiAssistantBloc>()
                              .add(AssistantPromptSubmitted(val.trim()));
                          _promptController.clear();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'What would you like to do?',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.mic_none_rounded,
                            color: Color(0xFFE05A47),
                          ),
                          onPressed: () {
                            _promptController.text =
                                'Prioritize sprint tasks and assign documentation';
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Context Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = activeCat == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            context
                                .read<AiAssistantBloc>()
                                .add(FilterChipSelected(cat));
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat,
                              style: AppTypography.titleSmall.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Style Segmented Control (Classic | Orbit | Fluid)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: _styles.map((style) {
                        final isSelected = activeStyle == style;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context
                                  .read<AiAssistantBloc>()
                                  .add(BoardStyleSelected(style));
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF323238)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Text(
                                style,
                                style: AppTypography.titleSmall.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textMuted,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                if (isThinking)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: LinearProgressIndicator(
                      color: AppColors.accentPurple,
                      backgroundColor: AppColors.border,
                      minHeight: 2,
                    ),
                  ),

                // 3 Columns Preview (Orbit Style Kanban)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _orbitColumn('To Do', 2, [
                          _orbitCard(
                            title: 'Design Review',
                            desc: 'Review new UI components',
                            dotColor: AppColors.accentRed,
                            time: 'Today',
                            avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
                          ),
                          _orbitCard(
                            title: 'Team Meeting',
                            desc: 'Weekly sync with design team',
                            dotColor: AppColors.accentYellow,
                            time: 'Tomorrow',
                            avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                          ),
                        ]),
                        _orbitColumn('In Progress', 1, [
                          _orbitCard(
                            title: 'API Integration',
                            desc: 'Connect backend services',
                            dotColor: AppColors.accentRed,
                            time: 'Today',
                            avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
                          ),
                        ]),
                        _orbitColumn('Done', 2, [
                          _orbitCard(
                            title: 'Bug Fixes',
                            desc: 'Fix reported issues',
                            dotColor: AppColors.accentYellow,
                            time: 'Yesterday',
                            avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
                          ),
                          _orbitCard(
                            title: 'Documentation',
                            desc: 'Update API docs',
                            dotColor: AppColors.accentGreen,
                            time: 'Yesterday',
                            avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),

                // Bottom Action: Magic Sort Gradient Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: AppColors.magicSortGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x44EC4899),
                                blurRadius: 20,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: () {
                              context
                                  .read<AiAssistantBloc>()
                                  .add(const MagicSortTriggered());
                            },
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: Text(
                              'Magic Sort',
                              style: AppTypography.buttonText.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.grid_view_rounded,
                              color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _orbitColumn(String title, int count, List<Widget> cards) {
    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$count',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Cards
          ...cards,

          // Add card button
          Container(
            width: double.infinity,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.add, color: AppColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _orbitCard({
    required String title,
    required String desc,
    required Color dotColor,
    required String time,
    required String avatar,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 10,
                backgroundImage: NetworkImage(avatar),
              ),
              Text(
                time,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
