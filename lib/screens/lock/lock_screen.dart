import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/app_router.dart';
import '../../widgets/primary_button.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pinController = TextEditingController();
  String _error = '';
  bool _isLoading = false;

  Future<void> _unlock() async {
    final validationError = ReadingValidator.validatePin(_pinController.text);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    final security = ref.read(securityServiceProvider);
    bool valid;
    try {
      valid = await security.verifyPin(_pinController.text);
    } on Object {
      valid = false;
    }

    if (valid && mounted) {
      isAppUnlocked = true;
      context.go(AppRoutes.home);
    } else if (mounted) {
      setState(() {
        _error = 'Incorrect PIN. Try again.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'VitalTrack',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to unlock',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
                decoration: InputDecoration(
                  counterText: '',
                  errorText: _error.isEmpty ? null : _error,
                ),
                onSubmitted: (_) => _unlock(),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Unlock',
                isLoading: _isLoading,
                onPressed: _unlock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
