import 'package:flutter/material.dart';
import 'package:razak_travel/features/admin/admin_dashboard.dart';
import 'package:razak_travel/features/admin/admin_login_screen.dart';
import 'package:razak_travel/shared/animations/premium_motion.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const adminLogin = '/admin-login';
  static const adminPanel = '/admin-panel';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
      case adminLogin:
        return PremiumMotion.pageRoute<void>(
          builder: (_) => const AdminLoginScreen(),
          settings: settings,
          style: PremiumRouteStyle.blurScale,
        );
      case adminPanel:
        return PremiumMotion.pageRoute<void>(
          builder: (_) => const AdminDashboardScreen(),
          settings: settings,
          style: PremiumRouteStyle.blurScale,
        );
      default:
        return PremiumMotion.pageRoute<void>(
          builder: (_) => const AdminLoginScreen(),
          settings: settings,
          style: PremiumRouteStyle.blurScale,
        );
    }
  }
}
