import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/titulo_resaltado.dart';
import '../../auth/domain/perfil_usuario.dart';
import '../../auth/presentation/sesion_controlador.dart';
import 'avatar_usuario.dart';

/// Menú ☰ de la cuenta, con "Cerrar sesión" (HU-002, CA13).
class MiCuentaPantalla extends ConsumerWidget {
  const MiCuentaPantalla({super.key, required this.perfil});

  final PerfilUsuario perfil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Rutas.inicio),
        ),
        title: const TituloResaltado('Mi cuenta'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(child: AvatarUsuario(tamano: 88)),
            const SizedBox(height: 12),
            Text(
              perfil.nombreCompleto,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.tinta,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.verdeFondo,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  perfil.rol.etiqueta,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.verdeTexto,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.verdeTexto,
                backgroundColor: AppColors.verdeFondo,
                side: const BorderSide(color: AppColors.verde, width: 1.5),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              onPressed: () => ref.read(sesionProvider.notifier).cerrar(),
            ),
          ],
        ),
      ),
    );
  }
}
