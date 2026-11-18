import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'choose_vibe_screen.dart';

class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() => _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Create Boards That\nWork for You',
      'subtitle':
          'Whether it\'s your next big idea or daily to-dos — organize it your way.',
    },
    {
      'title': 'Plan Smarter. Together.',
      'subtitle':
          'Work with friends, classmates or teammates — from idea to execution.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) {
                    setState(() => _currentPage = idx);
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          slide['title']!,
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide['subtitle']!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),

                        // Visual Representation
                        if (index == 0)
                          _buildBoardsGraphic()
                        else
                          _buildCollaborationGraphic(),

                        const Spacer(),
                      ],
                    );
                  },
                ),
              ),

              // Dot Indicators (3 dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isActive = index == (_currentPage + 1);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 8 : 6,
                    height: isActive ? 8 : 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.orangePrimary : AppColors.textMuted,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangePrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ChooseVibeScreen(),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Get Started',
                    style: AppTypography.buttonText.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardsGraphic() {
    return Center(
      child: SizedBox(
        height: 260,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left column of mini cards
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniCard(80, 110),
                const SizedBox(height: 12),
                _miniCard(80, 60),
              ],
            ),
            const SizedBox(width: 14),
            // Center column of mini cards
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniCard(90, 80),
                const SizedBox(height: 12),
                _miniCard(90, 95),
              ],
            ),
            const SizedBox(width: 14),
            // Right column of mini cards
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniCard(80, 100),
                const SizedBox(height: 12),
                _miniCard(80, 70),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniCard(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1918),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4A2F20), width: 1.2),
      ),
    );
  }

  Widget _buildCollaborationGraphic() {
    return Center(
      child: SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _avatarCircle(60),
                Container(width: 40, height: 2, color: const Color(0xFF5A3620)),
                _avatarCircle(70),
                Container(width: 40, height: 2, color: const Color(0xFF5A3620)),
                _avatarCircle(60),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniCard(85, 45),
                const SizedBox(width: 16),
                _miniCard(95, 45),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E1C1A),
        border: Border.all(color: const Color(0xFF6E3F25), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22FF6433),
            blurRadius: 16,
          ),
        ],
      ),
    );
  }
}
