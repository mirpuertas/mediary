import 'package:flutter/material.dart';

@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;

  final Color success;
  final Color onSuccess;
  final Color successContainer;

  final Color info;
  final Color onInfo;
  final Color infoContainer;

  const AppStatusColors({
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
  });


  static AppStatusColors light() {
    return AppStatusColors(
      danger: Colors.red,
      onDanger: Colors.white,
      dangerContainer: Colors.red.shade50,
      warning: Colors.orange,
      onWarning: Colors.black,
      warningContainer: Colors.orange.shade50,
      success: Colors.green,
      onSuccess: Colors.white,
      successContainer: Colors.green.shade50,
      info: Colors.blue,
      onInfo: Colors.white,
      infoContainer: Colors.blue.shade50,
    );
  }


  static AppStatusColors dark() {
    return AppStatusColors(
      danger: Colors.red.shade300,
      onDanger: Colors.black,
      dangerContainer: const Color(0xFF3D2020),
      warning: Colors.orange.shade300,
      onWarning: Colors.black,
      warningContainer: const Color(0xFF3D3020),
      success: Colors.green.shade300,
      onSuccess: Colors.black,
      successContainer: const Color(0xFF203D20),
      info: Colors.blue.shade300,
      onInfo: Colors.black,
      infoContainer: const Color(0xFF20303D),
    );
  }

  @override
  AppStatusColors copyWith({
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
  }) {
    return AppStatusColors(
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}

@immutable
class AppSurfaceColors extends ThemeExtension<AppSurfaceColors> {
  final Color accentSurface;

  const AppSurfaceColors({required this.accentSurface});

  static const AppSurfaceColors light = AppSurfaceColors(
    accentSurface: Color(0xFFC6CCFF),
  );

  static const AppSurfaceColors dark = AppSurfaceColors(
    accentSurface: Color(0xFF586091),
  );

  @override
  AppSurfaceColors copyWith({Color? accentSurface}) {
    return AppSurfaceColors(accentSurface: accentSurface ?? this.accentSurface);
  }

  @override
  AppSurfaceColors lerp(ThemeExtension<AppSurfaceColors>? other, double t) {
    if (other is! AppSurfaceColors) return this;
    return AppSurfaceColors(
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
    );
  }
}

@immutable
class AppNeutralColors extends ThemeExtension<AppNeutralColors> {
  final Color grey300;
  final Color grey400;
  final Color grey500;
  final Color grey600;
  final Color grey700;

  final Color black;
  final Color white;
  final Color black87;

  const AppNeutralColors({
    required this.grey300,
    required this.grey400,
    required this.grey500,
    required this.grey600,
    required this.grey700,
    required this.black,
    required this.white,
    required this.black87,
  });

  static AppNeutralColors standard() {
    return AppNeutralColors(
      grey300: Colors.grey.shade300,
      grey400: Colors.grey.shade400,
      grey500: Colors.grey.shade500,
      grey600: Colors.grey.shade600,
      grey700: Colors.grey.shade700,
      black: Colors.black,
      white: Colors.white,
      black87: Colors.black87,
    );
  }

  @override
  AppNeutralColors copyWith({
    Color? grey300,
    Color? grey400,
    Color? grey500,
    Color? grey600,
    Color? grey700,
    Color? black,
    Color? white,
    Color? black87,
  }) {
    return AppNeutralColors(
      grey300: grey300 ?? this.grey300,
      grey400: grey400 ?? this.grey400,
      grey500: grey500 ?? this.grey500,
      grey600: grey600 ?? this.grey600,
      grey700: grey700 ?? this.grey700,
      black: black ?? this.black,
      white: white ?? this.white,
      black87: black87 ?? this.black87,
    );
  }

  @override
  AppNeutralColors lerp(ThemeExtension<AppNeutralColors>? other, double t) {
    if (other is! AppNeutralColors) return this;
    return AppNeutralColors(
      grey300: Color.lerp(grey300, other.grey300, t)!,
      grey400: Color.lerp(grey400, other.grey400, t)!,
      grey500: Color.lerp(grey500, other.grey500, t)!,
      grey600: Color.lerp(grey600, other.grey600, t)!,
      grey700: Color.lerp(grey700, other.grey700, t)!,
      black: Color.lerp(black, other.black, t)!,
      white: Color.lerp(white, other.white, t)!,
      black87: Color.lerp(black87, other.black87, t)!,
    );
  }
}

@immutable
class AppBrandColors extends ThemeExtension<AppBrandColors> {
  /// Onboarding icon accents (Welcome screen|Pantalla de bienvenida)
  final Color onboardingPage1;
  final Color onboardingPage2;
  final Color onboardingPage3;
  final Color onboardingPage4;

  final Color splashBackground;
  final Color splashSun;
  final Color splashTitle;
  final Color splashSubtitle;

  const AppBrandColors({
    required this.onboardingPage1,
    required this.onboardingPage2,
    required this.onboardingPage3,
    required this.onboardingPage4,
    required this.splashBackground,
    required this.splashSun,
    required this.splashTitle,
    required this.splashSubtitle,
  });

  static const AppBrandColors standard = AppBrandColors(
    onboardingPage1: Color(0xFF2F2F2F),
    onboardingPage2: Color(0xFFF2C94C),
    onboardingPage3: Color(0xFF3F4A4F),
    onboardingPage4: Color(0xFF8A8A8A),
    splashBackground: Color(0xFFF7F6F3),
    splashSun: Color(0xFFF2C94C),
    splashTitle: Color(0xFF2F2F2F),
    splashSubtitle: Color(0xFF8A8A8A),
  );

  @override
  AppBrandColors copyWith({
    Color? onboardingPage1,
    Color? onboardingPage2,
    Color? onboardingPage3,
    Color? onboardingPage4,
    Color? splashBackground,
    Color? splashSun,
    Color? splashTitle,
    Color? splashSubtitle,
  }) {
    return AppBrandColors(
      onboardingPage1: onboardingPage1 ?? this.onboardingPage1,
      onboardingPage2: onboardingPage2 ?? this.onboardingPage2,
      onboardingPage3: onboardingPage3 ?? this.onboardingPage3,
      onboardingPage4: onboardingPage4 ?? this.onboardingPage4,
      splashBackground: splashBackground ?? this.splashBackground,
      splashSun: splashSun ?? this.splashSun,
      splashTitle: splashTitle ?? this.splashTitle,
      splashSubtitle: splashSubtitle ?? this.splashSubtitle,
    );
  }

  @override
  AppBrandColors lerp(ThemeExtension<AppBrandColors>? other, double t) {
    if (other is! AppBrandColors) return this;
    return AppBrandColors(
      onboardingPage1: Color.lerp(onboardingPage1, other.onboardingPage1, t)!,
      onboardingPage2: Color.lerp(onboardingPage2, other.onboardingPage2, t)!,
      onboardingPage3: Color.lerp(onboardingPage3, other.onboardingPage3, t)!,
      onboardingPage4: Color.lerp(onboardingPage4, other.onboardingPage4, t)!,
      splashBackground: Color.lerp(
        splashBackground,
        other.splashBackground,
        t,
      )!,
      splashSun: Color.lerp(splashSun, other.splashSun, t)!,
      splashTitle: Color.lerp(splashTitle, other.splashTitle, t)!,
      splashSubtitle: Color.lerp(splashSubtitle, other.splashSubtitle, t)!,
    );
  }
}

extension AppThemeTokensX on BuildContext {
  AppSurfaceColors get surfaces =>
      Theme.of(this).extension<AppSurfaceColors>() ?? AppSurfaceColors.light;

  AppStatusColors get statusColors =>
      Theme.of(this).extension<AppStatusColors>() ?? AppStatusColors.light();

  AppNeutralColors get neutralColors =>
      Theme.of(this).extension<AppNeutralColors>() ??
      AppNeutralColors.standard();

  AppBrandColors get brand =>
      Theme.of(this).extension<AppBrandColors>() ?? AppBrandColors.standard;
}
