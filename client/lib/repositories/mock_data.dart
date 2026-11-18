import '../core/theme/app_colors.dart';
import '../models/board_model.dart';
import '../models/card_model.dart';
import '../models/checklist_item_model.dart';
import '../models/column_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';

class MockData {
  static const UserModel currentUser = UserModel(
    id: 'user-dhruv-1',
    email: 'dhruv@boardbuddy.app',
    displayName: 'Dhruv',
    photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
  );

  static List<BoardModel> getInitialBoards() {
    return [
      BoardModel(
        id: 'board-1',
        name: 'Product Launch 2024',
        description: 'Coordinating cross-functional release of v2.0',
        accentColor: AppColors.accentPurple,
        iconType: 'rocket',
        updatedTimeAgo: '2h ago',
        progress: 75,
        isFavorite: true,
        memberAvatars: const [
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
        ],
        columns: _getProductLaunchColumns(),
      ),
      BoardModel(
        id: 'board-2',
        name: 'Content Calendar',
        description: 'Blog, social, and newsletter editorial plan',
        accentColor: AppColors.accentCyan,
        iconType: 'calendar',
        updatedTimeAgo: '5h ago',
        progress: 45,
        isFavorite: false,
        memberAvatars: const [
          'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150',
        ],
        columns: _getContentCalendarColumns(),
      ),
      BoardModel(
        id: 'board-3',
        name: 'Design System',
        description: 'Design tokens, typography, and component library',
        accentColor: AppColors.orangePrimary,
        iconType: 'pen',
        updatedTimeAgo: '1d ago',
        progress: 90,
        isFavorite: true,
        memberAvatars: const [
          'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=150',
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
        ],
        columns: _getDesignSystemColumns(),
      ),
      BoardModel(
        id: 'board-4',
        name: 'Marketing Tasks',
        description: 'Campaigns, sponsorships, and paid media targets',
        accentColor: AppColors.accentGreen,
        iconType: 'megaphone',
        updatedTimeAgo: '3d ago',
        progress: 30,
        isFavorite: false,
        memberAvatars: const [
          'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150',
        ],
        columns: _getMarketingColumns(),
      ),
    ];
  }

  static List<ColumnModel> _getProductLaunchColumns() {
    return [
      ColumnModel(
        id: 'col-todo',
        boardId: 'board-1',
        title: 'To Do',
        position: 0,
        cards: [
          CardModel(
            id: 'card-1',
            boardId: 'board-1',
            columnId: 'col-todo',
            title: 'Design System Documentation',
            description: 'Update color palette and typography guidelines for mobile & web',
            priority: CardPriority.high,
            category: 'Design',
            progress: 66,
            labels: const ['Documentation', 'UI/UX'],
            dueDateText: 'Due: Oct 15, 2024',
            estimateMinutes: 180,
            attachmentCount: 3,
            assigneeNames: const ['Sarah Cooper'],
            assigneeAvatars: const [
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
            ],
            subtasks: const [
              ChecklistItem(id: 'sub-1', cardId: 'card-1', title: 'Research existing systems', isCompleted: true),
              ChecklistItem(id: 'sub-2', cardId: 'card-1', title: 'Create component library', isCompleted: true),
              ChecklistItem(id: 'sub-3', cardId: 'card-1', title: 'Design documentation template', isCompleted: true),
              ChecklistItem(id: 'sub-4', cardId: 'card-1', title: 'Write style guidelines', isCompleted: true),
              ChecklistItem(id: 'sub-5', cardId: 'card-1', title: 'Review with team', isCompleted: false),
              ChecklistItem(id: 'sub-6', cardId: 'card-1', title: 'Finalize documentation', isCompleted: false),
            ],
            comments: [
              Comment(
                id: 'com-1',
                cardId: 'card-1',
                authorName: 'Alex',
                authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                body: 'Looking good! Just need to adjust the spacing on buttons.',
                timeAgo: '2h ago',
                createdAt: DateTime.now().subtract(const Duration(hours: 2)),
              ),
              Comment(
                id: 'com-2',
                cardId: 'card-1',
                authorName: 'Maria',
                authorAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
                body: 'Updated the color palette tokens as requested.',
                timeAgo: '4h ago',
                createdAt: DateTime.now().subtract(const Duration(hours: 4)),
              ),
            ],
          ),
          const CardModel(
            id: 'card-2',
            boardId: 'board-1',
            columnId: 'col-todo',
            title: 'User Research Interviews',
            description: 'Conduct user interviews with 5 active college team leads',
            priority: CardPriority.medium,
            category: 'Research',
            progress: 33,
            labels: ['Interviews', 'Q4'],
            dueDateText: 'Due: Oct 20, 2024',
            estimateMinutes: 240,
            assigneeNames: ['Dhruv Jain'],
            assigneeAvatars: [
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
            ],
          ),
          const CardModel(
            id: 'card-3',
            boardId: 'board-1',
            columnId: 'col-todo',
            title: 'Payment Gateway Integration',
            description: 'Implement secure Stripe / UPI payment webhooks and receipt dispatch',
            priority: CardPriority.high,
            category: 'Backend',
            progress: 0,
            labels: ['Payments', 'Security'],
            dueDateText: 'Due: Oct 28, 2024',
            estimateMinutes: 360,
          ),
        ],
      ),
      const ColumnModel(
        id: 'col-inprogress',
        boardId: 'board-1',
        title: 'In Progress',
        position: 1,
        cards: [
          CardModel(
            id: 'card-4',
            boardId: 'board-1',
            columnId: 'col-inprogress',
            title: 'Website Redesign',
            description: 'Update homepage layout and improve mobile responsiveness',
            priority: CardPriority.high,
            category: 'Design',
            progress: 60,
            labels: ['Frontend', 'Responsive'],
            dueDateText: 'Due: Sep 30, 2024',
            estimateMinutes: 300,
            assigneeNames: ['Dhruv', 'Maria'],
            assigneeAvatars: [
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
            ],
          ),
          CardModel(
            id: 'card-5',
            boardId: 'board-1',
            columnId: 'col-inprogress',
            title: 'API Authentication Flow',
            description: 'Connect frontend client with JWT token refresh & session recovery',
            priority: CardPriority.urgent,
            category: 'Backend',
            progress: 50,
            labels: ['Auth', 'Security'],
            dueDateText: 'Due: Oct 05, 2024',
            estimateMinutes: 180,
          ),
        ],
      ),
      const ColumnModel(
        id: 'col-done',
        boardId: 'board-1',
        title: 'Done',
        position: 2,
        cards: [
          CardModel(
            id: 'card-6',
            boardId: 'board-1',
            columnId: 'col-done',
            title: 'Bug Fixes & Patch Release',
            description: 'Resolved reported memory leaks on card drag-and-drop',
            priority: CardPriority.medium,
            category: 'Bugfix',
            progress: 100,
            labels: ['Patched'],
            dueDateText: 'Due: Sep 18, 2024',
            estimateMinutes: 120,
          ),
          CardModel(
            id: 'card-7',
            boardId: 'board-1',
            columnId: 'col-done',
            title: 'Swagger & OpenAPI Spec',
            description: 'Generated clean v1 REST documentation with schemas',
            priority: CardPriority.low,
            category: 'Docs',
            progress: 100,
            labels: ['Specs'],
            dueDateText: 'Due: Sep 22, 2024',
            estimateMinutes: 90,
          ),
        ],
      ),
    ];
  }

  static List<ColumnModel> _getContentCalendarColumns() => const [
        ColumnModel(id: 'cc-1', boardId: 'board-2', title: 'Ideas', position: 0),
        ColumnModel(id: 'cc-2', boardId: 'board-2', title: 'Drafting', position: 1),
        ColumnModel(id: 'cc-3', boardId: 'board-2', title: 'Published', position: 2),
      ];

  static List<ColumnModel> _getDesignSystemColumns() => const [
        ColumnModel(id: 'ds-1', boardId: 'board-3', title: 'Components', position: 0),
        ColumnModel(id: 'ds-2', boardId: 'board-3', title: 'Review', position: 1),
        ColumnModel(id: 'ds-3', boardId: 'board-3', title: 'Merged', position: 2),
      ];

  static List<ColumnModel> _getMarketingColumns() => const [
        ColumnModel(id: 'm-1', boardId: 'board-4', title: 'Planning', position: 0),
        ColumnModel(id: 'm-2', boardId: 'board-4', title: 'Active', position: 1),
        ColumnModel(id: 'm-3', boardId: 'board-4', title: 'Analyzed', position: 2),
      ];
}
