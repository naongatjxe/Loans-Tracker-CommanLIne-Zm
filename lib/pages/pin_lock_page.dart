import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';
import '../main_tabs.dart';
import 'welcome_onboarding_page.dart';

class PinLockPage extends StatefulWidget {
  final bool isSetupMode;
  final bool isOnboarded;
  final ValueChanged<String>? onPinCreated;
  final VoidCallback? onSuccess;

  const PinLockPage({
    super.key,
    this.isSetupMode = false,
    this.isOnboarded = true,
    this.onPinCreated,
    this.onSuccess,
  });

  @override
  State<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends State<PinLockPage> {
  final LocalAuthentication _auth = LocalAuthentication();
  String _enteredPin = '';
  String _firstEnteredPin = ''; // Used for setup confirmation
  bool _isConfirming = false;
  String _message = 'Enter Passcode';

  @override
  void initState() {
    super.initState();
    if (widget.isSetupMode) {
      _message = 'Create 4-Digit PIN';
    } else {
      _message = 'Enter PIN to Unlock';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateWithBiometrics();
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final theme = Provider.of<ThemeController>(context, listen: false);
    if (!theme.biometricsEnabled) return;

    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (canAuthenticate) {
        final didAuthenticate = await _auth.authenticate(
          localizedReason: 'Scan fingerprint or face to unlock Loans Tracker',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        if (didAuthenticate) {
          _handleUnlockSuccess();
        }
      }
    } catch (_) {}
  }

  void _handleUnlockSuccess() {
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => widget.isOnboarded ? const MainTabs() : const WelcomeOnboardingPage(),
        ),
      );
    }
  }

  void _onKeyPress(String value) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += value;
    });

    if (_enteredPin.length == 4) {
      // Delay slightly for visual feedback of the last digit
      Future.delayed(const Duration(milliseconds: 150), () {
        _processPin();
      });
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  void _processPin() {
    final theme = Provider.of<ThemeController>(context, listen: false);

    if (widget.isSetupMode) {
      if (!_isConfirming) {
        // First entry complete, transition to confirmation
        setState(() {
          _firstEnteredPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
          _message = 'Confirm your PIN';
        });
      } else {
        // Checking confirmation PIN
        if (_enteredPin == _firstEnteredPin) {
          if (widget.onPinCreated != null) {
            widget.onPinCreated!(_enteredPin);
          } else {
            theme.setPinCode(_enteredPin);
            theme.setPinLockEnabled(true);
            Navigator.pop(context, true);
          }
        } else {
          // Reset confirmation
          setState(() {
            _enteredPin = '';
            _firstEnteredPin = '';
            _isConfirming = false;
            _message = 'PINs did not match. Create PIN';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PINs did not match. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Verification mode
      if (_enteredPin == theme.pinCode) {
        _handleUnlockSuccess();
      } else {
        setState(() {
          _enteredPin = '';
          _message = 'Incorrect PIN. Try again';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect PIN code'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Provider.of<ThemeController>(context).accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: accent,
            ),
            const SizedBox(height: 24),
            Text(
              _message,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),
            // Pin indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? accent
                        : accent.withValues(alpha: 0.2),
                    border: Border.all(color: accent, width: 1.5),
                  ),
                );
              }),
            ),
            const Spacer(),
            // Keyboard
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildKeyboardRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeyboardRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeyboardRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric button (only in unlock mode and if enabled)
                      Expanded(
                        child: (!widget.isSetupMode && Provider.of<ThemeController>(context).biometricsEnabled)
                            ? IconButton(
                                icon: Icon(Icons.fingerprint_rounded, size: 36, color: accent),
                                onPressed: _authenticateWithBiometrics,
                              )
                            : const SizedBox(),
                      ),
                      Expanded(
                        child: _buildKeyboardKey('0'),
                      ),
                      Expanded(
                        child: IconButton(
                          icon: Icon(Icons.backspace_outlined, size: 28, color: accent),
                          onPressed: _onBackspace,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => Expanded(child: _buildKeyboardKey(key))).toList(),
    );
  }

  Widget _buildKeyboardKey(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(4),
        child: Material(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _onKeyPress(label),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
