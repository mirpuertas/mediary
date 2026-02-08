import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../l10n/l10n.dart';
import '../../../../ui/app_theme_tokens.dart';
import 'splash_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  ThemeData _welcomeLightTheme() {
    const seed = Color(0xFF3F51B5);
    final lightScheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ).copyWith(
          tertiary: const Color(0xFF355F7C),
          onTertiary: Colors.white,
          tertiaryContainer: const Color(0xFFDCE8F2),
          onTertiaryContainer: const Color(0xFF0F2433),
          inversePrimary: AppSurfaceColors.light.accentSurface,
          error: const Color(0xFFB84C4C),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: lightScheme,
      extensions: <ThemeExtension<dynamic>>[
        AppSurfaceColors.light,
        AppStatusColors.light(),
        AppNeutralColors.standard(),
        AppBrandColors.standard,
      ],
    );
  }

  List<_OnboardingPage> _pagesFor(
    BuildContext context,
    AppLocalizations l10n,
  ) => [
    _OnboardingPage(
      icon: Icons.schedule_rounded,
      title: l10n.welcomePage1Title,
      description: l10n.welcomePage1Body,
      color: context.brand.onboardingPage1,
    ),
    _OnboardingPage(
      icon: Icons.alarm_rounded,
      title: l10n.welcomePage2Title,
      description: l10n.welcomePage2Body,
      color: context.brand.onboardingPage2,
    ),
    _OnboardingPage(
      icon: Icons.calendar_month_rounded,
      title: l10n.welcomePage3Title,
      description: l10n.welcomePage3Body,
      color: context.brand.onboardingPage3,
    ),
    _OnboardingPage(
      icon: Icons.lock_rounded,
      title: l10n.welcomePage4Title,
      description: l10n.welcomePage4Body,
      color: context.brand.onboardingPage4,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  Color _onAccent(BuildContext context, Color accent) {
    return accent.computeLuminance() > 0.55
        ? context.neutralColors.black
        : context.neutralColors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _welcomeLightTheme(),
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final cs = Theme.of(context).colorScheme;
          final pages = _pagesFor(context, l10n);
          final accent = pages[_currentPage].color;

          return Scaffold(
            backgroundColor: cs.surface,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        return _buildPage(context, pages[index]);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            pages.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? accent
                                    : cs.outlineVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            if (_currentPage > 0)
                              TextButton(
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Text(l10n.commonBack),
                              ),
                            const Spacer(),
                            if (_currentPage < pages.length - 1)
                              TextButton(
                                onPressed: _completeOnboarding,
                                child: Text(l10n.commonSkip),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (_currentPage == pages.length - 1) {
                                  _completeOnboarding();
                                } else {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: _onAccent(context, accent),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                _currentPage == pages.length - 1
                                    ? l10n.welcomeStart
                                    : l10n.commonNext,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPage(BuildContext context, _OnboardingPage page) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Icon(page.icon, size: 100, color: page.color),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
