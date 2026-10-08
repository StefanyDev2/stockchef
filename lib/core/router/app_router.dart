import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cuenta_creada_pantalla.dart';
import '../../features/auth/presentation/inicio_sesion_pantalla.dart';
import '../../features/auth/presentation/registro_pantalla.dart';

/// Rutas de la app. Cada funcionalidad agrega aquí las suyas.
abstract final class Rutas {
  static const inicioSesion = '/inicio-sesion';
  static const registro = '/registro';
  static const cuentaCreada = '/cuenta-creada';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Rutas.inicioSesion,
    routes: [
      GoRoute(
        path: Rutas.inicioSesion,
        builder: (context, state) => const InicioSesionPantalla(),
      ),
      GoRoute(
        path: Rutas.registro,
        builder: (context, state) => const RegistroPantalla(),
      ),
      GoRoute(
        path: Rutas.cuentaCreada,
        builder: (context, state) => const CuentaCreadaPantalla(),
      ),
    ],
  );
});
