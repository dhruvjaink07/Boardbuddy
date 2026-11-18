import '../models/board_insight_model.dart';
import '../models/board_model.dart';
import '../models/card_model.dart';
import '../models/generated_board_plan.dart';
import 'mock_data.dart';

abstract class BoardRepository {
  Future<List<BoardModel>> getBoards({String filter = 'all'});
  Future<BoardModel> getBoardById(String id);
  Future<BoardModel> createBoard(BoardModel board);
  Future<void> deleteBoard(String id);
  Future<void> moveCard({
    required String cardId,
    required String sourceColumnId,
    required String targetColumnId,
    required int newPosition,
  });
  Future<void> addCard(CardModel card);
  Future<void> updateCard(CardModel card);
  Future<void> toggleSubtask({required String cardId, required String subtaskId});
  Future<BoardInsightModel> getBoardInsights(String boardId, {bool forceRefresh = false});
  Future<GeneratedBoardPlan> generateBoardPlan(String prompt);
}

class InMemoryBoardRepository implements BoardRepository {
  List<BoardModel> _boards = MockData.getInitialBoards();

  @override
  Future<List<BoardModel>> getBoards({String filter = 'all'}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (filter == 'favorites') {
      return _boards.where((b) => b.isFavorite).toList();
    }
    if (filter == 'recent') {
      return _boards.take(2).toList();
    }
    return _boards;
  }

  @override
  Future<BoardModel> getBoardById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _boards.firstWhere(
      (b) => b.id == id,
      orElse: () => _boards.first,
    );
  }

  @override
  Future<BoardModel> createBoard(BoardModel board) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _boards = [board, ..._boards];
    return board;
  }

  @override
  Future<void> deleteBoard(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _boards.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> moveCard({
    required String cardId,
    required String sourceColumnId,
    required String targetColumnId,
    required int newPosition,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (int b = 0; b < _boards.length; b++) {
      final board = _boards[b];
      CardModel? cardToMove;
      
      // Find and remove from source
      final newColumns = board.columns.map((col) {
        if (col.id == sourceColumnId) {
          final updatedCards = List<CardModel>.from(col.cards);
          final index = updatedCards.indexWhere((c) => c.id == cardId);
          if (index != -1) {
            cardToMove = updatedCards.removeAt(index);
          }
          return col.copyWith(cards: updatedCards);
        }
        return col;
      }).toList();

      if (cardToMove != null) {
        // Update card status and columnId
        final updatedCard = cardToMove!.copyWith(
          columnId: targetColumnId,
          status: targetColumnId.contains('done')
              ? CardStatus.done
              : (targetColumnId.contains('prog')
                  ? CardStatus.inProgress
                  : CardStatus.todo),
        );

        // Insert into target
        final finalColumns = newColumns.map((col) {
          if (col.id == targetColumnId) {
            final targetCards = List<CardModel>.from(col.cards);
            final pos = newPosition.clamp(0, targetCards.length);
            targetCards.insert(pos, updatedCard);
            return col.copyWith(cards: targetCards);
          }
          return col;
        }).toList();

        _boards[b] = board.copyWith(columns: finalColumns);
        break;
      }
    }
  }

  @override
  Future<void> addCard(CardModel card) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (int b = 0; b < _boards.length; b++) {
      if (_boards[b].id == card.boardId) {
        final updatedCols = _boards[b].columns.map((col) {
          if (col.id == card.columnId) {
            return col.copyWith(cards: [...col.cards, card]);
          }
          return col;
        }).toList();
        _boards[b] = _boards[b].copyWith(columns: updatedCols);
        break;
      }
    }
  }

  @override
  Future<void> updateCard(CardModel card) async {
    await Future.delayed(const Duration(milliseconds: 150));
    for (int b = 0; b < _boards.length; b++) {
      if (_boards[b].id == card.boardId) {
        final updatedCols = _boards[b].columns.map((col) {
          if (col.id == card.columnId) {
            final cards = col.cards.map((c) => c.id == card.id ? card : c).toList();
            return col.copyWith(cards: cards);
          }
          return col;
        }).toList();
        _boards[b] = _boards[b].copyWith(columns: updatedCols);
        break;
      }
    }
  }

  @override
  Future<void> toggleSubtask({required String cardId, required String subtaskId}) async {
    for (int b = 0; b < _boards.length; b++) {
      final board = _boards[b];
      bool found = false;
      final updatedCols = board.columns.map((col) {
        final updatedCards = col.cards.map((card) {
          if (card.id == cardId) {
            found = true;
            final updatedSubtasks = card.subtasks.map((sub) {
              if (sub.id == subtaskId) {
                return sub.copyWith(isCompleted: !sub.isCompleted);
              }
              return sub;
            }).toList();
            final completedCount = updatedSubtasks.where((s) => s.isCompleted).length;
            final newProgress = updatedSubtasks.isEmpty
                ? 0
                : ((completedCount / updatedSubtasks.length) * 100).round();
            return card.copyWith(
              subtasks: updatedSubtasks,
              progress: newProgress,
            );
          }
          return card;
        }).toList();
        return col.copyWith(cards: updatedCards);
      }).toList();

      if (found) {
        _boards[b] = board.copyWith(columns: updatedCols);
        break;
      }
    }
  }

  @override
  Future<BoardInsightModel> getBoardInsights(String boardId, {bool forceRefresh = false}) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final board = await getBoardById(boardId);

    final allCards = board.columns.expand((c) => c.cards).toList();
    final total = allCards.length;
    final done = allCards.where((c) => c.status == CardStatus.done).length;
    final inProgress = allCards.where((c) => c.status == CardStatus.inProgress).length;
    final urgent = allCards.where((c) => c.priority == CardPriority.urgent || c.priority == CardPriority.high).length;
    final progress = total > 0 ? ((done / total) * 100).round() : 0;

    return BoardInsightModel(
      boardId: boardId,
      summary: "Strategic insight for '${board.name}': Team delivery rhythm is healthy. Overall project completion is currently at $progress% with $inProgress active streams.",
      findings: [
        "Board completion is at $progress% across ${board.columns.length} columns.",
        "$inProgress work streams are currently underway simultaneously.",
        if (urgent > 0)
          "$urgent high/urgent priority cards require active unblocking."
        else
          "No critical priority bottlenecks currently detected.",
      ],
      recommendations: [
        "Maintain focus on finishing active In-Progress tasks before pulling new items.",
        "Review estimated workloads during upcoming team sync.",
      ],
      sources: [
        {"title": "Board Metrics Snapshot", "url": "boardbuddy://boards/$boardId"},
        {"title": "Tavily Search: Agile delivery best practices", "url": "https://tavily.com"},
      ],
      warnings: [],
      isFallback: false,
      generatedAt: DateTime.now().toUtc().toIso8601String(),
      totalTasks: total,
      completedTasks: done,
      inProgressTasks: inProgress,
      progressPercent: progress,
    );
  }

  @override
  Future<GeneratedBoardPlan> generateBoardPlan(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final lower = prompt.toLowerCase();
    final planId = 'plan-${DateTime.now().millisecondsSinceEpoch}';

    if (lower.contains('bank') || lower.contains('finance') || lower.contains('pay')) {
      return GeneratedBoardPlan(
        planId: planId,
        boardName: 'Mobile Banking App',
        boardDescription: prompt,
        columns: ['Backlog', 'In Development', 'Security & QA', 'Done'],
        cards: const [
          GeneratedCardPreview(
            title: 'Biometric Auth & Session Tokens',
            description: 'Implement FaceID, TouchID, and auto-refreshing bearer tokens.',
            columnIndex: 0,
            priority: CardPriority.urgent,
            estimateMinutes: 120,
            labels: ['auth', 'security'],
          ),
          GeneratedCardPreview(
            title: 'Account Balance & Real-time Ledger',
            description: 'Build responsive ledger showing checking, savings, and card balances.',
            columnIndex: 1,
            priority: CardPriority.high,
            estimateMinutes: 90,
            labels: ['core', 'ui'],
          ),
          GeneratedCardPreview(
            title: 'Instant P2P Fund Transfers',
            description: 'Wire up transfer API with double-entry validation and idempotency keys.',
            columnIndex: 1,
            priority: CardPriority.urgent,
            estimateMinutes: 150,
            labels: ['payments', 'api'],
          ),
          GeneratedCardPreview(
            title: 'Push Alerts for Low Balance',
            description: 'Send APNS/FCM notifications when account dips below threshold.',
            columnIndex: 0,
            priority: CardPriority.medium,
            estimateMinutes: 45,
            labels: ['notifications'],
          ),
          GeneratedCardPreview(
            title: 'Penetration Testing & Encryption Audit',
            description: 'Verify AES-256 field encryption and TLS certificate pinning.',
            columnIndex: 2,
            priority: CardPriority.urgent,
            estimateMinutes: 180,
            labels: ['audit', 'compliance'],
          ),
        ],
        summary: 'Generated 4 workflow stages and 5 prioritized fintech tasks with security safeguards.',
      );
    } else if (lower.contains('market') || lower.contains('launch') || lower.contains('campaign')) {
      return GeneratedBoardPlan(
        planId: planId,
        boardName: 'Product Go-To-Market Campaign',
        boardDescription: prompt,
        columns: ['Ideation', 'Asset Creation', 'Review', 'Published'],
        cards: const [
          GeneratedCardPreview(
            title: 'Define ICP & Core Messaging Angles',
            description: 'Draft target personas, pain points, and product differentiation matrix.',
            columnIndex: 0,
            priority: CardPriority.high,
            estimateMinutes: 90,
            labels: ['strategy'],
          ),
          GeneratedCardPreview(
            title: 'Interactive Product Demo Screencast',
            description: 'Record 60-second video demo showing AI board generation in action.',
            columnIndex: 1,
            priority: CardPriority.high,
            estimateMinutes: 120,
            labels: ['video', 'media'],
          ),
          GeneratedCardPreview(
            title: 'Launch Announcement Newsletter & Blog',
            description: 'Write launch post with feature highlights and migration guide.',
            columnIndex: 1,
            priority: CardPriority.medium,
            estimateMinutes: 75,
            labels: ['copywriting'],
          ),
          GeneratedCardPreview(
            title: 'Targeted Growth Ads on Developer Channels',
            description: 'Configure and monitor ad campaigns across tech platforms.',
            columnIndex: 2,
            priority: CardPriority.medium,
            estimateMinutes: 60,
            labels: ['growth'],
          ),
        ],
        summary: 'Generated 4 campaign stages and 4 go-to-market action cards.',
      );
    } else {
      final title = prompt.length > 28 ? '${prompt.substring(0, 25)}...' : (prompt.isNotEmpty ? prompt : 'Sprint Delivery Project');
      return GeneratedBoardPlan(
        planId: planId,
        boardName: title,
        boardDescription: prompt,
        columns: ['Backlog', 'To Do', 'In Progress', 'Done'],
        cards: const [
          GeneratedCardPreview(
            title: 'Architecture & Scope Alignment',
            description: 'Confirm user stories, milestones, and technical dependencies.',
            columnIndex: 1,
            priority: CardPriority.urgent,
            estimateMinutes: 60,
            labels: ['planning'],
          ),
          GeneratedCardPreview(
            title: 'Implement Core Feature Workflow',
            description: 'Develop primary domain logic, services, and user interfaces.',
            columnIndex: 2,
            priority: CardPriority.high,
            estimateMinutes: 180,
            labels: ['feature', 'core'],
          ),
          GeneratedCardPreview(
            title: 'Automated Test Suite & Edge Cases',
            description: 'Write unit tests, regression evaluations, and verify clean state.',
            columnIndex: 1,
            priority: CardPriority.high,
            estimateMinutes: 90,
            labels: ['testing'],
          ),
          GeneratedCardPreview(
            title: 'Deployment & Observability Setup',
            description: 'Configure Docker container, health checks, and monitoring.',
            columnIndex: 0,
            priority: CardPriority.medium,
            estimateMinutes: 60,
            labels: ['devops'],
          ),
        ],
        summary: 'Structured goal into 4 workflow columns and 4 prioritized delivery cards.',
      );
    }
  }
}
