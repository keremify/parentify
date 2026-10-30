import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Parentify palette: warm paper, deep ink and a small set of
/// friendly accent colours used to identify children, apps and categories.
abstract final class AppColors {
  static const ink = Color(0xFF1B1A2E);
  static const inkSoft = Color(0xFF2E2B48);
  static const inkMuted = Color(0xFF44405E);
  static const cream = Color(0xFFF7F4EE);
  static const paper = Color(0xFFFFFFFF);
  static const parchment = Color(0xFFF0EBE1);

  static const violet = Color(0xFF6C5CE7);
  static const violetDeep = Color(0xFF4B3CC4);
  static const violetSoft = Color(0xFFEDE9FF);
  static const lavender = Color(0xFFB9AFFF);

  static const mint = Color(0xFF3FAF8C);
  static const mintBright = Color(0xFF57C7A8);
  static const mintSoft = Color(0xFFE1F5EE);

  static const coral = Color(0xFFE8624A);
  static const coralSoft = Color(0xFFFFE9E3);

  static const lemon = Color(0xFFF2C14E);
  static const lemonSoft = Color(0xFFFBF0D3);

  static const sky = Color(0xFF4E8EE8);
  static const skySoft = Color(0xFFE6F0FD);

  static const rose = Color(0xFFD95C8A);
  static const roseSoft = Color(0xFFFBE7EE);

  static const muted = Color(0xFF5F5A70);
  static const subtle = Color(0xFF6B6579);
  static const line = Color(0xFFEAE5DB);
  static const lineStrong = Color(0xFFDCD6CA);
  static const good = Color(0xFF2F8F70);
  static const warning = Color(0xFFD9822B);
}

abstract final class AppGradients {
  static const inkCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B1A2E), Color(0xFF38325F)],
  );

  static const violetCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5A49D6), Color(0xFF8B7BF5)],
  );

  static const violetButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF6C5CE7), Color(0xFF8D7BFA)],
  );

  static const loginBackdrop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFBF8F2), Color(0xFFF1ECFF), Color(0xFFF7F4EE)],
  );
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0F1B1A2E), blurRadius: 30, offset: Offset(0, 14)),
  ];

  static const floating = [
    BoxShadow(color: Color(0x1F4B3CC4), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const soft = [
    BoxShadow(color: Color(0x0A1B1A2E), blurRadius: 14, offset: Offset(0, 6)),
  ];
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: AppColors.cream,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.light(
        primary: AppColors.violet,
        onPrimary: Colors.white,
        secondary: AppColors.mint,
        onSecondary: Colors.white,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
        error: AppColors.coral,
        onError: Colors.white,
        outline: AppColors.lineStrong,
        outlineVariant: AppColors.line,
        surfaceContainerHighest: AppColors.parchment,
      ),
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: 'PlusJakartaSans',
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        )
        .copyWith(
          displayLarge: const TextStyle(
            fontSize: 42,
            height: 1.06,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
            color: AppColors.ink,
          ),
          displayMedium: const TextStyle(
            fontSize: 36,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
            color: AppColors.ink,
          ),
          headlineLarge: const TextStyle(
            fontSize: 29,
            height: 1.16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.ink,
          ),
          headlineMedium: const TextStyle(
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.ink,
          ),
          headlineSmall: const TextStyle(
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.ink,
          ),
          titleLarge: const TextStyle(
            fontSize: 18,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.ink,
          ),
          titleMedium: const TextStyle(
            fontSize: 15.5,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          titleSmall: const TextStyle(
            fontSize: 13.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          bodyLarge: const TextStyle(
            fontSize: 15.5,
            height: 1.55,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted,
          ),
          bodySmall: const TextStyle(
            fontSize: 12.5,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
          labelLarge: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          labelMedium: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          labelSmall: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        );

    return base.copyWith(
      textTheme: textTheme.apply(fontFamily: 'PlusJakartaSans'),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.ink),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.violet,
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.lineStrong),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.violet,
        ),
        hintStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.muted.withValues(alpha: 0.7),
        ),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.violet, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.coral),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.violet
              : AppColors.lineStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.violet,
      ),
    );
  }

  /// Horizontal breathing room that keeps content comfortable on tablets.
  static double gutter(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > 760 ? (width - 700) / 2 : 20;
  }
}
