import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/domain/perfil_usuario.dart';

/// Etiqueta del rol en la lista y el detalle (CA2): verde para
/// Administrador, durazno para Auxiliar de cocina, gris para Sin rol y roja
/// para un usuario desactivado.
class EtiquetaRol extends StatelessWidget {
  const EtiquetaRol({super.key, required this.usuario, this.prefijo = ''});

  final PerfilUsuario usuario;

  /// Texto antes del rol, por ejemplo "Rol actual: ".
  final String prefijo;

  @override
  Widget build(BuildContext context) {
    final (texto, fondo, borde, color) = !usuario.activo
        ? (
            'Desactivado',
            AppColors.errorFondo,
            AppColors.error,
            AppColors.error,
          )
        : switch (usuario.rol) {
            Rol.administrador => (
              'Administrador',
              AppColors.menta,
              AppColors.verde,
              AppColors.verdeTexto,
            ),
            Rol.auxiliarCocina => (
              'Auxiliar de cocina',
              AppColors.durazno,
              AppColors.duraznoBorde,
              AppColors.duraznoTexto,
            ),
            Rol.sinRol => (
              'Sin rol',
              AppColors.campoDeshabilitado,
              AppColors.atenuado,
              AppColors.tinta,
            ),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: fondo,
        border: Border.all(color: borde),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$prefijo$texto',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
