import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Título con fondo verde menta, como en los encabezados del prototipo.
class TituloResaltado extends StatelessWidget {
  const TituloResaltado(this.texto, {super.key, this.tamano = 18});

  final String texto;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.menta,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: tamano,
          fontWeight: FontWeight.w700,
          color: AppColors.tinta,
        ),
      ),
    );
  }
}
