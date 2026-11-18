import '../models/board_insight_model.dart';
import '../models/board_model.dart';
import '../models/card_model.dart';
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
}
