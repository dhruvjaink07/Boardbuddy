import 'card_model.dart';

class GeneratedCardPreview {
  final String title;
  final String description;
  final int columnIndex;
  final CardPriority priority;
  final int estimateMinutes;
  final List<String> labels;

  const GeneratedCardPreview({
    required this.title,
    required this.description,
    required this.columnIndex,
    required this.priority,
    required this.estimateMinutes,
    required this.labels,
  });

  factory GeneratedCardPreview.fromJson(Map<String, dynamic> json) {
    CardPriority parsePriority(String? p) {
      switch (p?.toLowerCase()) {
        case 'urgent':
          return CardPriority.urgent;
        case 'high':
          return CardPriority.high;
        case 'low':
          return CardPriority.low;
        case 'medium':
        default:
          return CardPriority.medium;
      }
    }

    return GeneratedCardPreview(
      title: json['title'] as String? ?? 'Untitled Task',
      description: json['description'] as String? ?? '',
      columnIndex: json['column_index'] as int? ?? 0,
      priority: parsePriority(json['priority'] as String?),
      estimateMinutes: json['estimate_minutes'] as int? ?? 30,
      labels: (json['labels'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class GeneratedBoardPlan {
  final String planId;
  final String boardName;
  final String boardDescription;
  final List<String> columns;
  final List<GeneratedCardPreview> cards;
  final String summary;
  final List<String> warnings;

  const GeneratedBoardPlan({
    required this.planId,
    required this.boardName,
    required this.boardDescription,
    required this.columns,
    required this.cards,
    required this.summary,
    this.warnings = const [],
  });

  factory GeneratedBoardPlan.fromJson(Map<String, dynamic> json) {
    final boardMap = json['board'] as Map<String, dynamic>? ?? {};
    final columnsList = (json['columns'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['To Do', 'In Progress', 'Done'];

    final cardsList = (json['cards'] as List<dynamic>?)
            ?.map((e) => GeneratedCardPreview.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final warningsList = (json['warnings'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return GeneratedBoardPlan(
      planId: json['plan_id']?.toString() ?? 'plan-${DateTime.now().millisecondsSinceEpoch}',
      boardName: boardMap['name'] as String? ?? 'Generated Board',
      boardDescription: boardMap['description'] as String? ?? '',
      columns: columnsList,
      cards: cardsList,
      summary: json['summary'] as String? ?? 'AI-generated plan with structured columns and cards.',
      warnings: warningsList,
    );
  }
}
