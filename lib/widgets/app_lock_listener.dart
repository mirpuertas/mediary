import 'dart:async';

import 'package:flutter/material.dart';

import '../app/navigation.dart';
import '../services/app_lock_service.dart';
import '../features/security/presentation/screens/lock_screen.dart';

class AppLockListener extends StatefulWidget {
  final Widget child;

  const AppLockListener({super.key, required this.child});

  @override
  State<AppLockListener> createState() => _AppLockListenerState();
}

class _AppLockListenerState extends State<AppLockListener>
    with WidgetsBindingObserver {
  bool _locking = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      AppLockService.instance.markBackgroundedNow();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      // Evitar doble-trigger con algunos dispositivos.
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), _maybeLock);
    }
  }

  Future<void> _maybeLock() async {
    if (_locking) return;
    final should = await AppLockService.instance.shouldRequireUnlockNow();
    if (!should) return;
    if (!mounted) return;
    _locking = true;
    final nav = navigatorKey.currentState;
    if (nav == null) {
      _locking = false;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 200), _maybeLock);
      return;
    }
    await LockScreen.showWithNavigator(nav);
    _locking = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

