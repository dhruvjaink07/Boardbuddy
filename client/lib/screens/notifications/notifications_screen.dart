import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _activeTab = 'All';
  bool _showOfflineBanner = false;

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New comment on Task A',
      'time': '5m ago',
      'icon': Icons.chat_bubble_outline_rounded,
      'color': AppColors.orangePrimary,
      'type': 'Mentions',
    },
    {
      'title': 'Board shared with you',
      'time': '1h ago',
      'icon': Icons.share_outlined,
      'color': AppColors.accentPurple,
      'type': 'Updates',
    },
    {
      'title': 'Task deadline approaching',
      'time': '2h ago',
      'icon': Icons.access_time_rounded,
      'color': AppColors.accentRed,
      'type': 'Updates',
    },
    {
      'title': 'Weekly summary available',
      'time': '1d ago',
      'icon': Icons.analytics_outlined,
      'color': AppColors.accentCyan,
      'type': 'Updates',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _activeTab == 'All'
        ? _notifications
        : _notifications.where((n) => n['type'] == _activeTab).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: AppTypography.headlineMedium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showOfflineBanner
                          ? Icons.wifi_off_rounded
                          : Icons.wifi_rounded,
                      color: _showOfflineBanner
                          ? AppColors.orangePrimary
                          : AppColors.textMuted,
                    ),
                    onPressed: () {
                      setState(() => _showOfflineBanner = !_showOfflineBanner);
                    },
                    tooltip: 'Toggle Offline Banner Preview',
                  ),
                ],
              ),
            ),

            // Offline Banner Preview (from Page 18 & 19)
            if (_showOfflineBanner)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFB83A14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You\'re offline – showing cached boards',
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Filter Tabs (All / Mentions / Updates)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: ['All', 'Mentions', 'Updates'].map((tab) {
                  final isSelected = _activeTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = tab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.orangePrimary
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tab,
                          style: AppTypography.titleSmall.copyWith(
                            color: isSelected ? Colors.white : AppColors.textMuted,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Notification List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filtered.length + 1,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == filtered.length) {
                    return _buildCaughtUp();
                  }
                  final item = filtered[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['time'] as String,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaughtUp() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.orangePrimary, width: 2),
            ),
            child: const Icon(Icons.check, color: AppColors.orangePrimary, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            'You\'re all caught up!',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
