import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/providers/auth_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      icon: Icons.receipt_long,
      title: 'onboarding_title_1',
      subtitle: 'onboarding_subtitle_1',
      color: AppTheme.incomeColor,
    ),
    OnboardingData(
      icon: Icons.track_changes,
      title: 'onboarding_title_2',
      subtitle: 'onboarding_subtitle_2',
      color: AppTheme.successColor,
    ),
    OnboardingData(
      icon: Icons.smart_toy,
      title: 'onboarding_title_3',
      subtitle: 'onboarding_subtitle_3',
      color: AppTheme.accentColor,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToAuth();
    }
  }

  void _skipOnboarding() {
    _navigateToAuth();
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacementNamed(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: Text(
                  'skip'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: page.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: Icon(
                            page.icon,
                            size: 60,
                            color: page.color,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Title
                        Text(
                          page.title.tr(),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          page.subtitle.tr(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondaryColor,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Section
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // Page Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.primaryColor
                              : AppTheme.textLightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'get_started'.tr()
                            : 'continue'.tr(),
                      ),
                    ),
                  ),

                  if (_currentPage == _pages.length - 1) ...[
                    const SizedBox(height: 16),
                    
                    // Continue as Guest
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          final success = await ref.read(authProvider.notifier).signInAsGuest();
                          if (success && mounted) {
                            Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
                          }
                        },
                        child: Text('continue_as_guest'.tr()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}