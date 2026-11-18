import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'onboarding_carousel_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // App Logo
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.orangeGlow,
                      blurRadius: 28,
                      spreadRadius: 4,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'BoardBuddy',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(flex: 2),

              // Visual: Layered Frosted Glowing Cards
              Center(
                child: SizedBox(
                  width: size.width * 0.75,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Back card
                      Positioned(
                        top: 0,
                        child: Container(
                          width: size.width * 0.65,
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFF231C18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF6B452D), width: 1),
                          ),
                        ),
                      ),
                      // Middle card
                      Positioned(
                        top: 24,
                        child: Container(
                          width: size.width * 0.68,
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFF261D2E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF6A3D8A), width: 1),
                          ),
                        ),
                      ),
                      // Front card
                      Positioned(
                        top: 48,
                        child: Container(
                          width: size.width * 0.72,
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F241F).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFB45A28), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33FF6433),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),

              // Headline & Subtitle
              Text(
                'Organize Ideas.\nAchieve Goals.',
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Visual project management made easy.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 2),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangePrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.orangeGlow,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingCarouselScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Get Started',
                    style: AppTypography.buttonText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
