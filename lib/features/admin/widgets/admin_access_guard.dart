import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razak_travel/features/auth/auth_controller.dart';
import 'package:razak_travel/routes/app_routes.dart';

class AdminAccessGuard extends StatefulWidget {
  const AdminAccessGuard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AdminAccessGuard> createState() => _AdminAccessGuardState();
}

class _AdminAccessGuardState extends State<AdminAccessGuard> {
  bool _redirectScheduled = false;

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    if (authController.isLoggedIn) {
      _redirectScheduled = false;
      return widget.child;
    }

    if (!_redirectScheduled) {
      _redirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.adminLogin,
          (route) => false,
        );
      });
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
