                                                       import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:razak_travel/core/services/notification_service.dart';
import 'package:razak_travel/core/services/supabase_config.dart';
import 'package:razak_travel/features/auth/auth_controller.dart';
import 'package:razak_travel/routes/app_routes.dart';
import 'package:razak_travel/shared/animations/premium_motion.dart';
import 'package:razak_travel/shared/localization/app_localizations.dart';
import 'package:razak_travel/shared/localization/locale_controller.dart';
import 'package:razak_travel/shared/theme/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _premiumPrimary = Color(0xFF14B8A6);
const _premiumSecondary = Color(0xFF0EA5E9);
const _premiumAccent = Color(0xFF7C3AED);
const _premiumDarkBackground = Color(0xFF07111A);
const _premiumDarkSurface = Color(0xFF0F172A);
const _premiumLightBackground = Color(0xFFF3FCFF);
const _premiumLightSurface = Color(0xFFF8FDFF);

Future<void> main() async {
  debugPrint('APP START');
  debugPrint('Supabase URL: ${SupabaseConfig.supabaseUrl}');
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.anonKey,
    );
    debugPrint('Supabase initialized');
    final auth = Supabase.instance.client.auth;
    debugPrint('CURRENT USER: ${auth.currentUser}');
    debugPrint('CURRENT USER ID: ${auth.currentUser?.id}');
    debugPrint('CURRENT SESSION: ${auth.currentSession}');
  } catch (error) {
    debugPrint('Supabase init error: $error');
    rethrow;
  }

  final localeController = LocaleController();
  final authController = AuthController();
  final themeController = ThemeController();

  // ignore: avoid_print
  print('RUNAPP');
  runApp(
    RazakTravelApp(
      localeController: localeController,
      authController: authController,
      themeController: themeController,
    ),
  );
}

class RazakTravelApp extends StatelessWidget {
  const RazakTravelApp({
    super.key,
    required this.localeController,
    required this.authController,
    required this.themeController,
  });

  final LocaleController localeController;
  final AuthController authController;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeController),
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: themeController),
      ],
      child: StartupBootstrap(
        localeController: localeController,
        authController: authController,
        themeController: themeController,
      ),
    );
  }
}

class StartupBootstrap extends StatefulWidget {
  const StartupBootstrap({
    super.key,
    required this.localeController,
    required this.authController,
    required this.themeController,
  });

  final LocaleController localeController;
  final AuthController authController;
  final ThemeController themeController;

  @override
  State<StartupBootstrap> createState() => _StartupBootstrapState();
}

class _StartupBootstrapState extends State<StartupBootstrap> {
  bool _didStartInitialization = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartInitialization) {
      return;
    }

    _didStartInitialization = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeAfterStartup());
    });
  }

  Future<void> _initializeAfterStartup() async {
    // ignore: avoid_print
    print('APP START: deferred initialization started');

    unawaited(_initializeNotifications());
    unawaited(_loadLocale());
    unawaited(_loadTheme());
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService.instance.initialize();
    } catch (e, st) {
      debugPrint('Notification init failed: $e\n$st');
    }
  }

  Future<void> _loadLocale() async {
    try {
      await widget.localeController.loadLocale();
    } catch (error) {
      // ignore: avoid_print
      print('STARTUP WARNING: locale load failed: $error');
    }
  }

  Future<void> _loadTheme() async {
    try {
      await widget.themeController.loadTheme();
    } catch (error) {
      // ignore: avoid_print
      print('STARTUP WARNING: theme load failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    final localeController = context.watch<LocaleController>();
    final themeController = context.watch<ThemeController>();
    final lightScheme = ColorScheme.fromSeed(
      seedColor: _premiumPrimary,
      primary: _premiumPrimary,
      secondary: _premiumSecondary,
      tertiary: _premiumAccent,
      brightness: Brightness.light,
    ).copyWith(
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      surface: _premiumLightSurface,
      onSurface: const Color(0xFF081926),
      surfaceContainerHighest: const Color(0xFFD9F6F9),
      onSurfaceVariant: const Color(0xFF496271),
      outline: const Color(0xFF85D8E4),
      outlineVariant: const Color(0xFFC9EEF4),
      shadow: const Color(0xFF042033),
      scrim: const Color(0xFF020617),
      inverseSurface: _premiumDarkSurface,
      onInverseSurface: Colors.white,
      inversePrimary: const Color(0xFF5EEAD4),
      primaryContainer: const Color(0xFFB8FFF2),
      secondaryContainer: const Color(0xFFC8F3FF),
      tertiaryContainer: const Color(0xFFE1D4FF),
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: _premiumPrimary,
      primary: _premiumPrimary,
      secondary: _premiumSecondary,
      tertiary: _premiumAccent,
      brightness: Brightness.dark,
    ).copyWith(
      onPrimary: const Color(0xFF041414),
      onSecondary: const Color(0xFF03131C),
      onTertiary: Colors.white,
      error: const Color(0xFFF87171),
      onError: const Color(0xFF2A0909),
      surface: _premiumDarkSurface,
      onSurface: const Color(0xFFE6F7FF),
      surfaceContainerHighest: const Color(0xFF1B2A3F),
      onSurfaceVariant: const Color(0xFF9CC6D6),
      outline: const Color(0xFF23536A),
      outlineVariant: const Color(0xFF173449),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFFEAFBFF),
      onInverseSurface: const Color(0xFF04111A),
      inversePrimary: const Color(0xFF0F766E),
      primaryContainer: const Color(0xFF0B3E43),
      secondaryContainer: const Color(0xFF0A3143),
      tertiaryContainer: const Color(0xFF25144A),
    );

    return MaterialApp(
      scaffoldMessengerKey: NotificationService.instance.scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      locale: localeController.currentLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
        Locale('ky'),
        Locale('kk'),
        Locale('tr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('en');
      },
      onGenerateTitle: (context) {
        final localizations = AppLocalizations.of(context);
        return localizations.text('app_name');
      },
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: home == null ? AppRoutes.categoryManagement : null,
      home: home,
      theme: _buildTheme(
        colorScheme: lightScheme,
        scaffoldBackgroundColor: _premiumLightBackground,
        isDark: false,
      ),
      darkTheme: _buildTheme(
        colorScheme: darkScheme,
        scaffoldBackgroundColor: _premiumDarkBackground,
        isDark: true,
      ),
      themeMode: themeController.themeMode,
    );
  }
}

ThemeData _buildTheme({
  required ColorScheme colorScheme,
  required Color scaffoldBackgroundColor,
  required bool isDark,
}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    fontFamily: 'SF Pro Display',
  );

  return base.copyWith(
    splashFactory: InkSparkle.splashFactory,
    splashColor: colorScheme.primary.withValues(alpha: 0.12),
    highlightColor: colorScheme.secondary.withValues(alpha: 0.08),
    hoverColor: colorScheme.primary.withValues(alpha: 0.05),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: (isDark ? colorScheme.surface : Colors.white).withValues(
        alpha: isDark ? 0.74 : 0.84,
      ),
      shadowColor: colorScheme.shadow.withValues(alpha: isDark ? 0.58 : 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: (isDark ? Colors.white : colorScheme.primary).withValues(
            alpha: isDark ? 0.14 : 0.14,
          ),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: (isDark ? colorScheme.surface : Colors.white).withValues(
        alpha: isDark ? 0.76 : 0.88,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: (isDark ? Colors.white : colorScheme.primary).withValues(
            alpha: isDark ? 0.12 : 0.18,
          ),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: (isDark ? Colors.white : colorScheme.primary).withValues(
            alpha: isDark ? 0.14 : 0.16,
          ),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.88),
          width: 1.4,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor:
          colorScheme.surface.withValues(alpha: isDark ? 0.72 : 0.92),
      selectedColor: colorScheme.primary.withValues(alpha: 0.18),
      side: BorderSide(
        color: colorScheme.outline.withValues(alpha: isDark ? 0.5 : 0.28),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: base.textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.12),
      thumbColor: colorScheme.secondary,
      overlayColor: colorScheme.secondary.withValues(alpha: 0.12),
      rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
      rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
    ),
    dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.42),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        foregroundColor: colorScheme.onPrimary,
        backgroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.5 : 0.75),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _PremiumPageTransitionsBuilder(),
        TargetPlatform.iOS: _PremiumPageTransitionsBuilder(),
        TargetPlatform.macOS: _PremiumPageTransitionsBuilder(),
        TargetPlatform.windows: _PremiumPageTransitionsBuilder(),
        TargetPlatform.linux: _PremiumPageTransitionsBuilder(),
      },
    ),
  );
}

class _PremiumPageTransitionsBuilder extends PageTransitionsBuilder {
  const _PremiumPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: PremiumCurves.entrance,
      reverseCurve: PremiumCurves.standard,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
