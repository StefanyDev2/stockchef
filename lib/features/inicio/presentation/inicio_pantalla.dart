import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/perfil_usuario.dart';
import '../../auth/presentation/sesion_controlador.dart';
import '../domain/funciones_por_rol.dart';
import 'avatar_usuario.dart';

/// Pantalla principal después de iniciar sesión (HU-002): las funciones del
/// rol (pantallas 3A y 3B, CA6) o el aviso de cuenta sin rol (3C, CA7).
class InicioPantalla extends ConsumerWidget {
  const InicioPantalla({super.key, required this.perfil});

  final PerfilUsuario perfil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sinRol = perfil.rol == Rol.sinRol;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const AvatarUsuario(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      perfil.primerNombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tinta,
                      ),
                    ),
                  ),
                  // La cuenta sin rol no muestra el menú (prototipo 3C).
                  if (!sinRol)
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.mentaSuave,
                        foregroundColor: AppColors.verde,
                      ),
                      icon: const Icon(Icons.menu_rounded),
                      tooltip: 'Mi cuenta',
                      onPressed: () => context.push(Rutas.miCuenta),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: sinRol
                    ? const _AvisoSinRol()
                    : _Funciones(perfil: perfil),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Funciones extends StatelessWidget {
  const _Funciones({required this.perfil});

  final PerfilUsuario perfil;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          color: AppColors.menta,
          padding: const EdgeInsets.all(14),
          child: Text(
            'Hola ${perfil.primerNombre},\n¿Qué quieres hacer hoy?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.tinta,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (final funcion in funcionesDe(perfil.rol))
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.tinta,
                side: const BorderSide(color: AppColors.tinta, width: 1.2),
                minimumSize: const Size.fromHeight(56),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // En el Sprint 1 las funciones solo se muestran.
              onPressed: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('$funcion: próximamente')),
                ),
              child: Text(funcion),
            ),
          ),
      ],
    );
  }
}

class _AvisoSinRol extends ConsumerWidget {
  const _AvisoSinRol();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: AppColors.ambarSuave,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('⏳', style: TextStyle(fontSize: 44)),
        ),
        const SizedBox(height: 24),
        const Text(
          'Tu cuenta está pendiente de asignación de rol',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.tinta,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Un administrador debe asignarte un rol para que puedas usar '
          'la aplicación.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppColors.atenuado),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => ref.read(sesionProvider.notifier).cerrar(),
          child: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
