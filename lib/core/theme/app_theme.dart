import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema único de la app: fondo blanco, campos con borde gris claro,
/// botón primario durazno (naranja al presionarlo) y enlaces verdes.
abstract final class AppTheme {
  static const _radio = BorderRadius.all(Radius.circular(10));

  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(
      seedColor: AppColors.verde,
      primary: AppColors.verde,
      error: AppColors.error,
      surface: AppColors.fondo,
      onSurface: AppColors.tinta,
    );

    OutlineInputBorder borde(Color color, [double ancho = 1]) =>
        OutlineInputBorder(
          borderRadius: _radio,
          borderSide: BorderSide(color: color, width: ancho),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: AppColors.fondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.verde,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WidgetStateColor.resolveWith(
          (estados) => estados.contains(WidgetState.disabled)
              ? AppColors.campoDeshabilitado
              : AppColors.fondo,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.atenuado),
        helperStyle: const TextStyle(color: AppColors.atenuado),
        helperMaxLines: 2,
        errorStyle: const TextStyle(color: AppColors.error),
        errorMaxLines: 2,
        border: borde(AppColors.borde),
        enabledBorder: borde(AppColors.borde),
        focusedBorder: borde(AppColors.verde, 1.5),
        errorBorder: borde(AppColors.error),
        focusedErrorBorder: borde(AppColors.error, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: _radio),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.disabled)
                ? AppColors.deshabilitado
                : estados.contains(WidgetState.pressed)
                ? AppColors.naranja
                : AppColors.durazno,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (estados) => estados.contains(WidgetState.disabled)
                ? AppColors.deshabilitadoTexto
                : estados.contains(WidgetState.pressed)
                ? Colors.white
                : AppColors.duraznoTexto,
          ),
          side: WidgetStateProperty.resolveWith(
            (estados) => BorderSide(
              color: estados.contains(WidgetState.disabled)
                  ? AppColors.deshabilitadoBorde
                  : estados.contains(WidgetState.pressed)
                  ? AppColors.naranja
                  : AppColors.duraznoBorde,
            ),
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.verde,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
