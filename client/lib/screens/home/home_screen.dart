import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/board_list/board_list_bloc.dart';
import '../../blocs/board_list/board_list_event.dart';
import '../../blocs/board_list/board_list_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../models/board_model.dart';
import '../assistant/ai_assistant_screen.dart';
import '../board/board_detail_screen.dart';
import '../create_board/create_board_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<BoardListBloc>().add(const BoardListRequested(filter: 'all'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _currentNavIndex == 2
            ? const AiAssistantScreen()
            : (_currentNavIndex == 3
                ? const NotificationsScreen()
                : _buildHomeContent(context)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orangePrimary,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateBoardScreen()),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() => _currentNavIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Boards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_rounded),
              label: 'Assistant',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_rounded),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return BlocBuilder<BoardListBloc, BoardListState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey Dhruv 👋',
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your boards await!',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.grid_view_rounded,
                                color: AppColors.textPrimary,
                                size: 24,
                              ),
                              onPressed: () {},
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.accentRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Filter Chips Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _filterChip(context, 'All Boards', 'all', state),
                    const SizedBox(width: 10),
                    _filterChip(context, 'Recent', 'recent', state),
                    const SizedBox(width: 10),
                    _filterChip(context, 'Favorites', 'favorites', state),
                  ],
                ),
              ),
            ),

            // Content List / Grid
            if (state is BoardListLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.orangePrimary),
                ),
              )
            else if (state is BoardListLoaded)
              _buildBoardGrid(context, state.boards)
            else if (state is BoardListEmpty)
              _buildEmptyState(context)
            else
              const SliverToBoxAdapter(child: SizedBox.shrink()),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    String filterKey,
    BoardListState state,
  ) {
    final activeFilter =
        state is BoardListLoaded ? state.activeFilter : 'all';
    final isSelected = activeFilter == filterKey;

    return GestureDetector(
      onTap: () {
        context.read<BoardListBloc>().add(BoardFilterChanged(filterKey));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF292440) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.accentPurple : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.titleSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBoardGrid(BuildContext context, List<BoardModel> boards) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.88,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final board = boards[index];
            return _buildBoardCard(context, board);
          },
          childCount: boards.length,
        ),
      ),
    );
  }

  Widget _buildBoardCard(BuildContext context, BoardModel board) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BoardDetailScreen(boardId: board.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Left Colored Accent Strip
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(color: board.accentColor),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + Recency Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          _getIconData(board.iconType),
                          color: board.accentColor,
                          size: 22,
                        ),
                        Text(
                          board.updatedTimeAgo,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      board.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: board.progress / 100,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(board.accentColor),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Progress label & Members Avatars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${board.progress}%',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        _buildMemberAvatars(board.memberAvatars),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberAvatars(List<String> avatars) {
    if (avatars.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...avatars.take(3).map(
                (url) => Container(
                  margin: const EdgeInsets.only(right: 3),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 1.5),
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
          if (avatars.length > 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${avatars.length - 3}',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconData(String type) {
    switch (type) {
      case 'rocket':
        return Icons.rocket_launch_rounded;
      case 'calendar':
        return Icons.calendar_today_rounded;
      case 'pen':
        return Icons.edit_rounded;
      case 'megaphone':
        return Icons.campaign_rounded;
      case 'star':
        return Icons.star_rounded;
      default:
        return Icons.dashboard_rounded;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.orangePrimary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Boards Yet',
                style: AppTypography.headlineMedium.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first board to get started',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create Board'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateBoardScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
