import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/titulo_resaltado.dart';
import 'inicio_sesion_controlador.dart';

/// Pantalla provisional después de iniciar sesión (HU-001, CA12).
/// HU-002 la reemplaza por la pantalla principal de cada rol.
class InicioProvisionalPantalla extends ConsumerWidget {
  const InicioProvisionalPantalla({super.key, required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> cerrarSesion() async {
      await ref.read(sesionRepositorioProvider).cerrarSesion();
      if (context.mounted) context.go(Rutas.inicioSesion);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TituloResaltado(
                nombre.isEmpty ? 'Hola' : 'Hola, $nombre',
                tamano: 22,
              ),
              const SizedBox(height: 16),
              const Text(
                'Iniciaste sesión correctamente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.atenuado),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: cerrarSesion,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
