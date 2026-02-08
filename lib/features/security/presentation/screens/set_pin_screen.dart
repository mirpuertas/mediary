import 'package:flutter/material.dart';

import '../../../../services/app_lock_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../../ui/app_theme_tokens.dart';

class SetPinScreen extends StatefulWidget {
  final bool isChange;
  final bool requireCurrentPin;

  const SetPinScreen({
    super.key,
    this.isChange = false,
    this.requireCurrentPin = false,
  });

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _currentCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _isValidPin(String s) => RegExp(r'^\d{4}$').hasMatch(s);

  Future<void> _submit() async {
    final l10n = context.l10n;
    final current = _currentCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (widget.requireCurrentPin) {
      if (!_isValidPin(current)) {
        setState(() => _error = l10n.setPinEnterCurrentPinError);
        return;
      }
    }

    if (!_isValidPin(pin)) {
      setState(() => _error = l10n.setPinInvalidPinError);
      return;
    }
    if (pin != confirm) {
      setState(() => _error = l10n.setPinPinsDoNotMatch);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    if (widget.requireCurrentPin) {
      final ok = await AppLockService.instance.verifyPin(current);
      if (!mounted) return;
      if (!ok) {
        final remaining = await AppLockService.instance.lockoutRemaining();
        setState(() {
          _busy = false;
          _error = (remaining != null && remaining > Duration.zero)
              ? l10n.setPinTooManyAttemptsSeconds(remaining.inSeconds)
              : l10n.setPinCurrentPinIncorrect;
        });
        return;
      }
    }

    await AppLockService.instance.setPin(pin);
    await AppLockService.instance.resetLockoutState();
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.isChange
        ? l10n.setPinTitleChange
        : l10n.setPinTitleCreate;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: context.surfaces.accentSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if ((_error ?? '').trim().isNotEmpty) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.requireCurrentPin) ...[
            TextField(
              controller: _currentCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: l10n.setPinCurrentPinLabel,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: InputDecoration(
              labelText: l10n.setPinNewPinLabel,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: InputDecoration(
              labelText: l10n.setPinConfirmNewPinLabel,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _busy ? null : _submit,
            icon: const Icon(Icons.save),
            label: Text(_busy ? l10n.commonSaving : l10n.commonSave),
          ),
        ],
      ),
    );
  }
}
