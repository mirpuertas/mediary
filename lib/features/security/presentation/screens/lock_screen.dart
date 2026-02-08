import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../services/app_lock_service.dart';
import '../../../../l10n/l10n.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;

  const LockScreen({super.key, this.onUnlocked});

  static PageRoute<bool> _route() {
    return PageRouteBuilder<bool>(
      opaque: true,
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const LockScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }

  static Future<bool?> show(BuildContext context) async {
    return Navigator.of(context, rootNavigator: true).push<bool>(_route());
  }

  static Future<bool?> showWithNavigator(NavigatorState navigator) async {
    return navigator.push<bool>(_route());
  }

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pin = <int>[];
  bool _isVerifying = false;
  String? _error;
  Duration? _lockoutRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshLockout();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshLockout(),
    );
    _tryBiometricAuth();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLockout() async {
    final remaining = await AppLockService.instance.lockoutRemaining();
    if (!mounted) return;
    setState(() {
      _lockoutRemaining = remaining;
    });
  }

  bool get _isLockedOut =>
      (_lockoutRemaining != null && _lockoutRemaining! > Duration.zero);

  String _format(Duration d) {
    final total = d.inSeconds.clamp(0, 999999);
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _append(int digit) {
    if (_isLockedOut || _isVerifying) return;
    if (_pin.length >= 4) return;
    setState(() {
      _error = null;
      _pin.add(digit);
    });
    if (_pin.length == 4) {
      _verify();
    }
  }

  void _backspace() {
    if (_isLockedOut || _isVerifying) return;
    if (_pin.isEmpty) return;
    setState(() {
      _error = null;
      _pin.removeLast();
    });
  }

  Future<void> _verify() async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final pinStr = _pin.join();
    final ok = await AppLockService.instance.verifyPin(pinStr);

    if (!mounted) return;

    if (ok) {
      setState(() {
        _isVerifying = false;
        _pin.clear();
      });
      widget.onUnlocked?.call();
      Navigator.of(context, rootNavigator: true).pop(true);
      return;
    }

    final remaining = await AppLockService.instance.lockoutRemaining();
    final attempts = await AppLockService.instance.failedAttempts();
    final left = (AppLockService.maxAttempts - attempts).clamp(
      0,
      AppLockService.maxAttempts,
    );

    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _isVerifying = false;
      _pin.clear();
      _lockoutRemaining = remaining;
      _error = (remaining != null && remaining > Duration.zero)
          ? l10n.lockScreenTooManyAttempts(_format(remaining))
          : l10n.lockScreenPinIncorrectAttemptsLeft(left);
    });
  }

  Future<void> _tryBiometricAuth() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final success = await AppLockService.instance.authenticateWithBiometrics();
    if (success && mounted) {
      widget.onUnlocked?.call();
      Navigator.of(context, rootNavigator: true).pop(true);
    }
  }

  Widget _dot(bool filled) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? cs.primary : cs.outlineVariant,
      ),
    );
  }

  Widget _key(int? digit, {IconData? icon, VoidCallback? onTap}) {
    final cs = Theme.of(context).colorScheme;
    final enabled = !_isLockedOut && !_isVerifying && (onTap != null);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 74,
        height: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.surfaceContainerHighest.withValues(
            alpha: enabled ? 1 : 0.55,
          ),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: icon != null
            ? Icon(icon, size: 28)
            : Text(
                digit?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final subtitleColor = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: PopScope(
          canPop: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Icon(Icons.lock, size: 42, color: cs.primary),
                const SizedBox(height: 12),
                Text(
                  l10n.lockScreenEnterPinTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLockedOut
                      ? l10n.lockScreenLockedOut(
                          _format(_lockoutRemaining ?? Duration.zero),
                        )
                      : l10n.lockScreenPinHint,
                  style: TextStyle(color: subtitleColor),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => _dot(i < _pin.length)),
                ),
                if ((_error ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: cs.error)),
                ],
                const Spacer(),
                if (_isVerifying)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: CircularProgressIndicator(),
                  ),
                _Keypad(
                  keyBuilder: (digit) => _key(
                    digit,
                    onTap: digit == null ? null : () => _append(digit),
                  ),
                  backspace: _key(
                    null,
                    icon: Icons.backspace_outlined,
                    onTap: _backspace,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<bool>(
                  future: AppLockService.instance.isBiometricEnabled(),
                  builder: (context, snapshot) {
                    final enabled = snapshot.data ?? false;
                    if (!enabled) return const SizedBox.shrink();

                    return TextButton.icon(
                      onPressed: _isLockedOut || _isVerifying
                          ? null
                          : _tryBiometricAuth,
                      icon: const Icon(Icons.fingerprint),
                      label: Text(l10n.lockScreenUseBiometrics),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final Widget Function(int? digit) keyBuilder;
  final Widget backspace;

  const _Keypad({required this.keyBuilder, required this.backspace});

  @override
  Widget build(BuildContext context) {
    Widget row(List<Widget> children) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: children,
        ),
      );
    }

    return Column(
      children: [
        row([keyBuilder(1), keyBuilder(2), keyBuilder(3)]),
        row([keyBuilder(4), keyBuilder(5), keyBuilder(6)]),
        row([keyBuilder(7), keyBuilder(8), keyBuilder(9)]),
        row([const SizedBox(width: 74, height: 74), keyBuilder(0), backspace]),
      ],
    );
  }
}
