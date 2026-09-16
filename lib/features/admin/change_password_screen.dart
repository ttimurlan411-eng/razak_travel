import 'package:flutter/material.dart';
import 'package:razak_travel/data/repositories/admin_repository.dart';
import 'package:razak_travel/core/localization/app_localizations.dart';
import 'package:razak_travel/shared/widgets/app_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final current = _currentController.text.trim();
    final newPass = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.text('fill_all_fields'))),
        );
      return;
    }

    if (newPass.length < 4) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.text('password_min_length'))),
        );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.text('passwords_do_not_match'))),
        );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ok = await AdminRepository().changePassword(
        currentPassword: current,
        newPassword: newPass,
      );
      if (!mounted) {
        return;
      }
      if (ok) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.text('password_changed'))),
          );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.text('wrong_current_password'))),
          );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.text('error_generic'))),
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('change_password')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(
              controller: _currentController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: l10n.text('current_password'),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: l10n.text('new_password'),
                prefixIcon: const Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: l10n.text('confirm_password'),
                prefixIcon: const Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: l10n.text('save'),
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
