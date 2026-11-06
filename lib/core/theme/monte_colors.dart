import 'package:flutter/material.dart';

/// Brand and semantic colors that do not fit Material's [ColorScheme].
///
/// Read it with `context.monte` (see `monte_theme.dart`). Income and expense
/// colors are always paired with an arrow and a sign in the UI, never used as
/// the only signal.
@immutable
final class MonteColors extends ThemeExtension<MonteColors> {
  const MonteColors({
    required this.brandDeep,
    required this.brand,
    required this.brandMid,
    required this.gold,
    required this.onGold,
    required this.income,
    required this.expense,
    required this.warning,
    required this.chip,
    required this.subtle,
  });

  static const light = MonteColors(
    brandDeep: Color(0xFF0B3D2A),
    brand: Color(0xFF0F6B45),
    brandMid: Color(0xFF1A7A50),
    gold: Color(0xFFF5C531),
    onGold: Color(0xFF0B3D2A),
    income: Color(0xFF138A4B),
    expense: Color(0xFFC2372B),
    warning: Color(0xFFB7791F),
    chip: Color(0xFFE8EFEA),
    subtle: Color(0xFF5A6B62),
  );

  static const dark = MonteColors(
    brandDeep: Color(0xFF0B3D2A),
    brand: Color(0xFF3DCB7D),
    brandMid: Color(0xFF1A7A50),
    gold: Color(0xFFF5C531),
    onGold: Color(0xFF0B3D2A),
    income: Color(0xFF3DCB7D),
    expense: Color(0xFFF2766A),
    warning: Color(0xFFE0A54A),
    chip: Color(0xFF1C2E25),
    subtle: Color(0xFF93A89C),
  );

  /// Header and splash background (#0B3D2A, "verde-mata").
  final Color brandDeep;

  /// Main brand green; lighter in dark mode to keep contrast.
  final Color brand;

  /// Mountain fill in the logo and secondary brand surfaces.
  final Color brandMid;

  /// The gold coin (#F5C531): highlights and the main shortcuts.
  final Color gold;

  /// Text and icons placed on [gold].
  final Color onGold;

  final Color income;
  final Color expense;
  final Color warning;

  /// Filter chips and quiet backgrounds.
  final Color chip;

  /// Secondary text.
  final Color subtle;

  @override
  MonteColors copyWith({
    Color? brandDeep,
    Color? brand,
    Color? brandMid,
    Color? gold,
    Color? onGold,
    Color? income,
    Color? expense,
    Color? warning,
    Color? chip,
    Color? subtle,
  }) => MonteColors(
    brandDeep: brandDeep ?? this.brandDeep,
    brand: brand ?? this.brand,
    brandMid: brandMid ?? this.brandMid,
    gold: gold ?? this.gold,
    onGold: onGold ?? this.onGold,
    income: income ?? this.income,
    expense: expense ?? this.expense,
    warning: warning ?? this.warning,
    chip: chip ?? this.chip,
    subtle: subtle ?? this.subtle,
  );

  @override
  MonteColors lerp(MonteColors? other, double t) {
    if (other == null) return this;
    return MonteColors(
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandMid: Color.lerp(brandMid, other.brandMid, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
    );
  }
}
