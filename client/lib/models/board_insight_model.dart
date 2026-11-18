class BoardInsightModel {
  final String boardId;
  final String summary;
  final List<String> findings;
  final List<String> recommendations;
  final List<Map<String, String>> sources;
  final List<String> warnings;
  final bool isFallback;
  final String generatedAt;
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int progressPercent;

  const BoardInsightModel({
    required this.boardId,
    required this.summary,
    required this.findings,
    required this.recommendations,
    required this.sources,
    required this.warnings,
    required this.isFallback,
    required this.generatedAt,
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.progressPercent,
  });

  factory BoardInsightModel.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? metrics}) {
    final sourcesList = (json['sources'] as List<dynamic>?)
            ?.map((e) => Map<String, String>.from(e as Map))
            .toList() ??
        [];

    final findingsList = (json['findings'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final recommendationsList = (json['recommendations'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final warningsList = (json['warnings'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return BoardInsightModel(
      boardId: json['board_id']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      findings: findingsList,
      recommendations: recommendationsList,
      sources: sourcesList,
      warnings: warningsList,
      isFallback: json['is_fallback'] == true,
      generatedAt: json['generated_at']?.toString() ?? '',
      totalTasks: metrics?['total_tasks'] ?? 0,
      completedTasks: metrics?['completed_tasks'] ?? 0,
      inProgressTasks: metrics?['in_progress_tasks'] ?? 0,
      progressPercent: metrics?['progress_percent'] ?? 0,
    );
  }
}
