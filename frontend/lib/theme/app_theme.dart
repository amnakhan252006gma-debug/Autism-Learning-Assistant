import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised theme constants for the child-facing app.
///
/// The palette is intentionally soft, muted and low-arousal: a calm indigo
/// primary, dusty feature accents, a warm paper background and generous
/// radii — a modern, professional look that stays autism-friendly.
/// Every screen pulls its colours from here so the app stays consistent.
///
/// Both light and dark palettes are defined here; the active set is chosen
/// by calling [setBrightness], which is wired to the app's [ThemeMode].
class AppTheme {
  AppTheme._();

  static Brightness _brightness = Brightness.light;

  /// Current active brightness.
  static Brightness get brightness => _brightness;

  /// Whether the app is currently in dark mode.
  static bool get isDark => _brightness == Brightness.dark;

  /// Switch the active palette. Call this before rebuilding the widget tree
  /// so custom widgets and [ThemeData] stay in sync.
  static void setBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  // ── Primary palette (muted indigo) ─────────────────────────────────
  static const Color _lightPrimary = Color(0xFF666DC2); // calm indigo
  static const Color _darkPrimary = Color(0xFF7B82D6); // lighter indigo
  static Color get primary => isDark ? _darkPrimary : _lightPrimary;

  static const Color _lightPrimaryLight = Color(0xFFBCC0E8); // soft periwinkle
  static const Color _darkPrimaryLight = Color(0xFF9BA4E8);
  static Color get primaryLight => isDark ? _darkPrimaryLight : _lightPrimaryLight;

  static const Color _lightPrimaryDark = Color(0xFF494F94); // deep indigo
  static const Color _darkPrimaryDark = Color(0xFFBCC0E8);
  static Color get primaryDark => isDark ? _darkPrimaryDark : _lightPrimaryDark;

  // ── Feature accents (dusty, low-arousal mid tones) ─────────────────
  /// Learn – dusty blue.
  static const Color _lightLearnColor = Color(0xFF5E8FBF);
  static const Color _darkLearnColor = Color(0xFF7BAFE6);
  static Color get learnColor => isDark ? _darkLearnColor : _lightLearnColor;

  /// Games – sage green.
  static const Color _lightGamesColor = Color(0xFF679A70);
  static const Color _darkGamesColor = Color(0xFF86C490);
  static Color get gamesColor => isDark ? _darkGamesColor : _lightGamesColor;

  /// Communicate – soft amber.
  static const Color _lightCommunicateColor = Color(0xFFC4814A);
  static const Color _darkCommunicateColor = Color(0xFFE6A06A);
  static Color get communicateColor => isDark ? _darkCommunicateColor : _lightCommunicateColor;

  /// Routine – dusty rose.
  static const Color _lightRoutineColor = Color(0xFFBE7891);
  static const Color _darkRoutineColor = Color(0xFFE093AB);
  static Color get routineColor => isDark ? _darkRoutineColor : _lightRoutineColor;

  // ── Deep companions (small text & emphasis on tinted surfaces) ─────
  static const Color _lightLearnDeep = Color(0xFF3F6D99);
  static const Color _darkLearnDeep = Color(0xFFB8D9F5);
  static Color get learnDeep => isDark ? _darkLearnDeep : _lightLearnDeep;

  static const Color _lightGamesDeep = Color(0xFF4A7A52);
  static const Color _darkGamesDeep = Color(0xFFBCE8C4);
  static Color get gamesDeep => isDark ? _darkGamesDeep : _lightGamesDeep;

  static const Color _lightCommunicateDeep = Color(0xFF9A6132);
  static const Color _darkCommunicateDeep = Color(0xFFF5D0A8);
  static Color get communicateDeep => isDark ? _darkCommunicateDeep : _lightCommunicateDeep;

  static const Color _lightRoutineDeep = Color(0xFF96566A);
  static const Color _darkRoutineDeep = Color(0xFFF5C0D2);
  static Color get routineDeep => isDark ? _darkRoutineDeep : _lightRoutineDeep;

  /// Maps a feature accent to its deep companion so small text stays
  /// readable on tinted surfaces. One-off colours are darkened in light
  /// mode and lightened in dark mode.
  static Color deepOf(Color accent) {
    if (accent == learnColor) return learnDeep;
    if (accent == gamesColor) return gamesDeep;
    if (accent == communicateColor) return communicateDeep;
    if (accent == routineColor) return routineDeep;
    if (accent == primary || accent == primaryLight) return primaryDark;
    return Color.lerp(
      accent,
      isDark ? Colors.white : const Color(0xFF262A33),
      .35,
    )!;
  }

  // ── Feedback ───────────────────────────────────────────────────────
  /// Gentle green for correct-answer feedback.
  static const Color _lightSuccess = Color(0xFF4E8F63);
  static const Color _darkSuccess = Color(0xFF6FC290);
  static Color get success => isDark ? _darkSuccess : _lightSuccess;

  /// Gentle rose for try-again feedback (deliberately not alarm-red).
  static const Color _lightError = Color(0xFFC25E5E);
  static const Color _darkError = Color(0xFFE68A8A);
  static Color get error => isDark ? _darkError : _lightError;

  /// Warm muted gold for reward stars and celebratory accents.
  static const Color _lightStarGold = Color(0xFFD9A648);
  static const Color _darkStarGold = Color(0xFFF5D27A);
  static Color get starGold => isDark ? _darkStarGold : _lightStarGold;

  // ── Surface / background ───────────────────────────────────────────
  static const Color _lightBackground = Color(0xFFF7F5F1); // warm paper
  static const Color _darkBackground = Color(0xFF1A1D24); // soft charcoal
  static Color get background => isDark ? _darkBackground : _lightBackground;

  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _darkSurface = Color(0xFF242936);
  static Color get surface => isDark ? _darkSurface : _lightSurface;

  static const Color _lightSurfaceAlt = Color(0xFFEFECE5); // inset fills & tracks
  static const Color _darkSurfaceAlt = Color(0xFF2E3340);
  static Color get surfaceAlt => isDark ? _darkSurfaceAlt : _lightSurfaceAlt;

  static const Color _lightOutline = Color(0xFFE3DFD7); // hairline card borders
  static const Color _darkOutline = Color(0xFF3A4050);
  static Color get outline => isDark ? _darkOutline : _lightOutline;

  static const Color _lightCardShadow = Color(0x1420252B);
  static const Color _darkCardShadow = Color(0x14000000);
  static Color get cardShadow => isDark ? _darkCardShadow : _lightCardShadow;

  // ── Text ───────────────────────────────────────────────────────────
  static const Color _lightTextPrimary = Color(0xFF3A3F49);
  static const Color _darkTextPrimary = Color(0xFFE8EAEF);
  static Color get textPrimary => isDark ? _darkTextPrimary : _lightTextPrimary;

  static const Color _lightTextSecondary = Color(0xFF6F747E);
  static const Color _darkTextSecondary = Color(0xFF9BA3B0);
  static Color get textSecondary => isDark ? _darkTextSecondary : _lightTextSecondary;

  static const Color _lightTextOnColor = Color(0xFFFFFFFF);
  static const Color _darkTextOnColor = Color(0xFFFFFFFF);
  static Color get textOnColor => isDark ? _darkTextOnColor : _lightTextOnColor;

  // ── Spacing scale (8-pt grid) ──────────────────────────────────────
  static const double spaceXS = 8;
  static const double spaceSM = 12;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;
  static const double spaceXXL = 48;

  // ── Border radius ──────────────────────────────────────────────────
  static const double radiusSM = 14;
  static const double radiusMD = 20;
  static const double radiusLG = 28;
  static const double radiusXL = 36;

  // ── Modern motion / elevation ──────────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 180);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 600);

  /// Soft, diffuse elevation presets — used instead of ad-hoc shadows.
  static List<BoxShadow> get shadowSoft => [
    BoxShadow(
      color: isDark ? const Color(0x0D000000) : const Color(0x0D20252B),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> get shadowCard => [
    BoxShadow(
      color: isDark ? const Color(0x14000000) : const Color(0x1420252B),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> get shadowLifted => [
    BoxShadow(
      color: isDark ? const Color(0x1F000000) : const Color(0x1F20252B),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];

  // ── Icon sizes (large for accessibility) ───────────────────────────
  static const double iconSM = 28;
  static const double iconMD = 40;
  static const double iconLG = 56;
  static const double iconXL = 80;

  /// The child-friendly font family used throughout the app.
  static String get fontFamily => GoogleFonts.nunito().fontFamily ?? 'Nunito';

  /// The global [ThemeData] used by [MaterialApp] in light mode.
  static ThemeData get themeData => _buildThemeData(Brightness.light);

  /// The global [ThemeData] used by [MaterialApp] in dark mode.
  static ThemeData get darkThemeData => _buildThemeData(Brightness.dark);

  static ThemeData _buildThemeData(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final backgroundColor = isDark ? _darkBackground : _lightBackground;
    final surfaceColor = isDark ? _darkSurface : _lightSurface;
    final surfaceAltColor = isDark ? _darkSurfaceAlt : _lightSurfaceAlt;
    final outlineColor = isDark ? _darkOutline : _lightOutline;
    final textPrimaryColor = isDark ? _darkTextPrimary : _lightTextPrimary;
    final textSecondaryColor = isDark ? _darkTextSecondary : _lightTextSecondary;
    final primaryColor = isDark ? _darkPrimary : _lightPrimary;
    final primaryDarkColor = isDark ? _darkPrimaryDark : _lightPrimaryDark;
    final errorColor = isDark ? _darkError : _lightError;
    final gamesColorValue = isDark ? _darkGamesColor : _lightGamesColor;

    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      brightness: brightness,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primaryColor,
              secondary: gamesColorValue,
              surface: surfaceColor,
              error: errorColor,
            )
          : ColorScheme.light(
              primary: primaryColor,
              secondary: gamesColorValue,
              surface: surfaceColor,
              error: errorColor,
            ),
      iconTheme: IconThemeData(color: textSecondaryColor, size: 24),
      textTheme: GoogleFonts.nunitoTextTheme(
        TextTheme(
          displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: textPrimaryColor,
            height: 1.2,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: textPrimaryColor,
            height: 1.2,
            letterSpacing: -0.3,
          ),
          headlineMedium: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: textPrimaryColor,
            letterSpacing: -0.2,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textPrimaryColor,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textPrimaryColor,
          ),
          bodyLarge: TextStyle(
            fontSize: 17,
            color: textSecondaryColor,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            color: textSecondaryColor,
            height: 1.45,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textSecondaryColor,
            letterSpacing: 0.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          side: BorderSide(color: outlineColor),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAltColor,
        labelStyle: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          side: BorderSide(color: outlineColor),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimaryColor,
        contentTextStyle: GoogleFonts.nunito(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceAltColor,
        circularTrackColor: surfaceAltColor,
        refreshBackgroundColor: surfaceColor,
      ),
      dividerTheme: DividerThemeData(
        color: outlineColor,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: surfaceAltColor,
          disabledForegroundColor: textSecondaryColor,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: fontFamily,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDarkColor,
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: fontFamily,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CalmPageTransitions(),
          TargetPlatform.iOS: CalmPageTransitions(),
          TargetPlatform.macOS: CalmPageTransitions(),
          TargetPlatform.windows: CalmPageTransitions(),
          TargetPlatform.linux: CalmPageTransitions(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: outlineColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: outlineColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: textPrimaryColor,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// Gentle fade-and-rise page transition shared by every platform.
///
/// A calm alternative to slide-over transitions: the new screen fades
/// in and settles slightly upward into place — short, smooth and
/// predictable, with no bouncing, flashing or color changes.
class CalmPageTransitions extends PageTransitionsBuilder {
  const CalmPageTransitions();

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
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .025),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
