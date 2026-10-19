import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/usuarios.dart';

/// R1 · Acción rechazada (HU-003, CA9): alguien que no es administrador
/// intentó abrir o usar una función de administrador.
class SinPermisoPantalla extends StatelessWidget {
  const SinPermisoPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.errorFondo,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    size: 56,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                MensajesUsuarios.sinPermisoTitulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tinta,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                MensajesUsuarios.sinPermisoDetalle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.atenuado),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => context.go(Rutas.inicio),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
