import 'package:flutter/material.dart';
import 'package:razak_travel/features/admin/category_list_screen.dart';
import 'package:razak_travel/features/admin/admin_login_screen.dart';
import 'package:razak_travel/shared/animations/premium_motion.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const adminLogin = '/admin-login';
  static const categoryManagement = '/category-management';

  /// Kept so existing deep links to the former admin-panel route still work.
  /// It now opens category management directly.
  static const adminPanel = '/admin-panel';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
      case categoryManagement:
      case adminPanel:
        return PremiumMotion.pageRoute<void>(
          builder: (_) => const AdminCategoryListScreen(),
          settings: settings,
          style: PremiumRouteStyle.blurScale,
        );
      case adminLogin:
        return PremiumMotion.pageRoute<void>(
          builder: (_) => const AdminLoginScreen(),
          settings: settings,
          style: PremiumRouteStyle.blurScale,
        );
      default:
        return PremiumMotion.pageRoute<void>(
          builder: (_) => const AdminCategoryListScreen(),
          settings: settings,
          style: PremiumRouteStyle.blurScale,
        );
    }
  }
}
