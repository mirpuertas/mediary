import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.schedule_rounded,
      title: 'Tu registro diario, sin esfuerzo',
      description: 'Anotá medicación, sueño y notas del día en pocos segundos.',
      color: const Color(0xFF2F2F2F),
    ),
    _OnboardingPage(
      icon: Icons.alarm_rounded,
      title: 'Recordatorios, si los necesitás',
      description:
          'Programá alarmas para tus tomas o usalo solo para registrar.',
      color: const Color(0xFFF2C94C),
    ),
    _OnboardingPage(
      icon: Icons.calendar_month_rounded,
      title: 'Tu historial en calendario',
      description:
          'Vas a poder ver días registrados y detectar patrones con el tiempo.',
      color: const Color(0xFF3F4A4F),
    ),
    _OnboardingPage(
      icon: Icons.lock_rounded,
      title: 'Todo queda en tu teléfono',
      description:
          'Se guarda localmente. Sin cuentas, sin servidores, sin internet.',
      color: const Color(0xFF8A8A8A),
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
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Color _onAccent(Color accent) {
    return accent.computeLuminance() > 0.55 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _pages[_currentPage].color;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Indicadores de página
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
                              ? accent
                              : cs.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Botones
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
                          child: const Text('Atrás'),
                        ),
                      const Spacer(),
                      if (_currentPage < _pages.length - 1)
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: const Text('Omitir'),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
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
                          foregroundColor: _onAccent(accent),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Comenzar'
                              : 'Siguiente',
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
  }

  Widget _buildPage(_OnboardingPage page) {
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
