import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Aviso rojo de la parte superior de un formulario.
class AvisoError extends StatelessWidget {
  const AvisoError(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.errorFondo,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
