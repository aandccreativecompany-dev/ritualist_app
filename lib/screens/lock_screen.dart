import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Journal lock — biometric with PIN fallback, entirely local. Not a security
/// boundary (there is no encryption underneath), just a privacy nudge so the
/// journal isn't the first thing someone sees if they pick up the phone.
class AppLock {
  /// Returns true once the caller may proceed. If no PIN has been set, there
  /// is nothing to unlock, so this returns true immediately.
  static Future<bool> ensureUnlocked(BuildContext context) async {
    if (!store.hasPin) return true;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LockScreen(mode: LockMode.unlock)),
    );
    return ok ?? false;
  }
}

enum LockMode { setup, unlock }

class LockScreen extends StatefulWidget {
  final LockMode mode;
  const LockScreen({super.key, required this.mode});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _triedBiometric = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == LockMode.unlock && store.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (_triedBiometric) return;
    _triedBiometric = true;
    final auth = LocalAuthentication();
    try {
      final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canCheck) return;
      final ok = await auth.authenticate(
        localizedReason: 'Unlock your journal',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (ok && mounted) Navigator.pop(context, true);
    } catch (_) {
      // Falls through to PIN entry — the device may not support biometrics,
      // or the app was built without the native activity biometrics needs.
    }
  }

  void _submitSetup() {
    if (_pin.text.length < 4) {
      setState(() => _error = 'Use at least 4 digits.');
      return;
    }
    if (_pin.text != _confirm.text) {
      setState(() => _error = "PINs don't match.");
      return;
    }
    store.setPin(_pin.text);
    Navigator.pop(context, true);
  }

  void _submitUnlock() {
    if (store.verifyPin(_pin.text)) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = 'Wrong PIN.';
        _pin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isSetup = widget.mode == LockMode.setup;

    return Scaffold(
      body: Container(
        decoration: Surfaces.pageBackground(dark),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: Icon(isSetup ? Icons.close : Icons.arrow_back,
                          color: Surfaces.bodyText(dark)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Icon(Icons.lock_outline, color: Surfaces.accent(dark), size: 34),
                const SizedBox(height: 20),
                Text(isSetup ? 'Set a PIN for your journal' : 'Enter your PIN',
                    style: display(24, Surfaces.heading(dark))),
                const SizedBox(height: 8),
                Text(
                  isSetup
                      ? 'Your evening reflection stays local. This PIN is a privacy nudge, not encryption.'
                      : 'Your evening reflection is locked.',
                  style: body(13, Surfaces.muted(dark)),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _pin,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 8,
                  style: display(20, Surfaces.heading(dark)),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'PIN',
                    hintStyle: body(16, Surfaces.muted(dark)),
                  ),
                ),
                if (isSetup) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirm,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 8,
                    style: display(20, Surfaces.heading(dark)),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Confirm PIN',
                      hintStyle: body(16, Surfaces.muted(dark)),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: body(12.5, Colors.redAccent)),
                ],
                const SizedBox(height: 24),
                GoldButton(
                  labelText: isSetup ? 'Save PIN' : 'Unlock',
                  onPressed: isSetup ? _submitSetup : _submitUnlock,
                ),
                if (!isSetup && store.biometricEnabled) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton.icon(
                      onPressed: _tryBiometric,
                      icon: Icon(Icons.fingerprint, color: Surfaces.accent(dark)),
                      label: Text('Use biometric unlock',
                          style: body(13, Surfaces.accent(dark), weight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
