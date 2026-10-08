import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Círculo verde claro con el ícono de persona, como en el prototipo.
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({super.key, this.tamano = 40});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: const BoxDecoration(
        color: AppColors.mentaSuave,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        size: tamano * 0.6,
        color: AppColors.verde,
      ),
    );
  }
}
