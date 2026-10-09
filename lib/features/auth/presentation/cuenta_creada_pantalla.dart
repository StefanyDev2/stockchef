import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

/// Confirmación de cuenta creada (HU-001, CA11).
class CuentaCreadaPantalla extends StatelessWidget {
  const CuentaCreadaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    void irAlInicio() => context.go(Rutas.inicioSesion);

    return PopScope(
      // El botón "atrás" no vuelve al formulario: lleva al inicio de sesión.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) irAlInicio();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.menta,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 56,
                    color: AppColors.verde,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Cuenta creada exitosamente!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tinta,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ya puedes iniciar sesión con tu correo electrónico '
                  'y contraseña.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.atenuado),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: irAlInicio,
                  child: const Text('Ir a iniciar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
