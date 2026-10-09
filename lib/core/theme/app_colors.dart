import 'package:flutter/material.dart';

/// Paleta de StockChef, tomada de los prototipos de `docs/prototipos/`.
abstract final class AppColors {
  /// Fondo de títulos y banners positivos.
  static const menta = Color(0xFFB8F0D0);

  /// Flechas de regreso y enlaces.
  static const verde = Color(0xFF1F8F5F);

  /// Botón primario en reposo.
  static const durazno = Color(0xFFF9CFA6);
  static const duraznoBorde = Color(0xFFF0B27A);
  static const duraznoTexto = Color(0xFF5C3A14);

  /// Botón primario presionado.
  static const naranja = Color(0xFFF5A65B);

  /// "Chef" en la marca.
  static const naranjaMarca = Color(0xFFE8892B);

  /// Fondo de avatares y del botón de menú.
  static const mentaSuave = Color(0xFFDFF5E8);

  /// Etiqueta del rol y botón "Cerrar sesión".
  static const verdeFondo = Color(0xFFE6F8EE);
  static const verdeTexto = Color(0xFF1F6F4C);

  /// Círculo del aviso de cuenta sin rol.
  static const ambarSuave = Color(0xFFFFF1C9);

  /// Botón y campos deshabilitados (cuenta bloqueada).
  static const deshabilitado = Color(0xFFE6E8EB);
  static const deshabilitadoBorde = Color(0xFFD3D6DB);
  static const deshabilitadoTexto = Color(0xFF9AA0A8);
  static const campoDeshabilitado = Color(0xFFF1F2F4);

  static const error = Color(0xFFE03E3E);
  static const errorFondo = Color(0xFFFDE4E4);

  static const tinta = Color(0xFF1F2430);
  static const atenuado = Color(0xFF8B93A1);
  static const borde = Color(0xFFD3D7DE);
  static const fondo = Colors.white;
}
