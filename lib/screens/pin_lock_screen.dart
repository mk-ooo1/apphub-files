import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../utils/theme.dart';

class PinLockScreen extends StatefulWidget {
  final bool setupMode;
  final VoidCallback onUnlocked;

  const PinLockScreen({
    super.key,
    this.setupMode = false,
    required this.onUnlocked,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final TextEditingController _pinCtrl = TextEditingController();
  String _error = '';
  final _security = SecurityService();

  void _submit() async {
    final pin = _pinCtrl.text;
    if (pin.length < 4) {
      setState(() => _error = 'Enter at least 4 digits');
      return;
    }

    if (widget.setupMode) {
      await _security.setPin(pin);
      widget.onUnlocked();
    } else {
      final success = await _security.verifyPin(pin);
      if (success) {
        widget.onUnlocked();
      } else {
        setState(() {
          _error = 'Incorrect PIN';
          _pinCtrl.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 64, color: Colors.white),
                      const SizedBox(height: 24),
                      Text(
                        widget.setupMode ? 'Set App PIN' : 'Enter PIN',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _pinCtrl,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 32, letterSpacing: 16),
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        ),
                        onChanged: (_) {
                          if (_pinCtrl.text.length == 4 && !widget.setupMode) {
                            _submit();
                          }
                        },
                      ),
                      if (_error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(_error, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 48),
                      if (widget.setupMode)
                        ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Save PIN'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
