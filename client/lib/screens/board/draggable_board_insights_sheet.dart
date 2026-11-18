import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/board_insight_model.dart';
import '../../repositories/board_repository.dart';

class DraggableBoardInsightsSheet extends StatefulWidget {
  final String boardId;
  final BoardRepository repository;

  const DraggableBoardInsightsSheet({
    super.key,
    required this.boardId,
    required this.repository,
  });

  static Future<void> show(BuildContext context, String boardId, BoardRepository repository) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableBoardInsightsSheet(
        boardId: boardId,
        repository: repository,
      ),
    );
  }

  @override
  State<DraggableBoardInsightsSheet> createState() => _DraggableBoardInsightsSheetState();
}

class _DraggableBoardInsightsSheetState extends State<DraggableBoardInsightsSheet> {
  late Future<BoardInsightModel> _insightsFuture;

  @override
  void initState() {
    super.initState();
    _loadInsights(forceRefresh: false);
  }

  void _loadInsights({bool forceRefresh = false}) {
    setState(() {
      _insightsFuture = widget.repository.getBoardInsights(
        widget.boardId,
        forceRefresh: forceRefresh,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.25, 0.65, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // --- Drag Handle ---
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // --- Sheet Header ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.orangePrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.orangePrimary,
                        size: 20,
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
                                "Deerflow Insights",
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.orangePrimary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "ORIGINAL",
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.orangePrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "Strategic Intelligence + External Context",
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
                      tooltip: "Refresh Insights",
                      onPressed: () => _loadInsights(forceRefresh: true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.border, height: 1),

              // --- Scrollable Content ---
              Expanded(
                child: FutureBuilder<BoardInsightModel>(
                  future: _insightsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.orangePrimary),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
                              const SizedBox(height: 12),
                              Text(
                                "Failed to load board insights",
                                style: AppTypography.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orangePrimary,
                                ),
                                onPressed: () => _loadInsights(forceRefresh: true),
                                child: const Text("Retry with Fallback"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final data = snapshot.data!;
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Fallback Alert Banner (if applicable)
                        if (data.isFallback)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Showing deterministic insights (external research unavailable).",
                                    style: AppTypography.bodySmall.copyWith(color: Colors.amber[200]),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Metrics Grid
                        Row(
                          children: [
                            _buildMetricTile("Total", "${data.totalTasks}", Icons.format_list_bulleted_rounded, AppColors.textSecondary),
                            const SizedBox(width: 8),
                            _buildMetricTile("Done", "${data.completedTasks}", Icons.check_circle_outline_rounded, Colors.greenAccent),
                            const SizedBox(width: 8),
                            _buildMetricTile("In Progress", "${data.inProgressTasks}", Icons.timelapse_rounded, AppColors.orangePrimary),
                            const SizedBox(width: 8),
                            _buildMetricTile("Progress", "${data.progressPercent}%", Icons.trending_up_rounded, Colors.cyanAccent),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Executive Summary Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.orangePrimary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.orangePrimary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Executive Strategy",
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.orangePrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data.summary,
                                style: AppTypography.bodyMedium.copyWith(
                                  height: 1.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Key Findings
                        Text(
                          "Key Findings & Bottlenecks",
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        ...data.findings.map(
                          (finding) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Icon(Icons.circle, size: 6, color: AppColors.orangePrimary),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    finding,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Actionable Recommendations
                        Text(
                          "Actionable Recommendations",
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        ...data.recommendations.map(
                          (rec) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    rec,
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Evidence & External Research Sources (Tavily Citations)
                        if (data.sources.isNotEmpty) ...[
                          Text(
                            "Evidence & External Context",
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: data.sources.map((s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.link_rounded, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      s['title'] ?? 'Source',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
