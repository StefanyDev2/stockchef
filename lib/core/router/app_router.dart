import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/perfil_usuario.dart';
import '../../features/auth/presentation/cargando_pantalla.dart';
import '../../features/auth/presentation/cuenta_creada_pantalla.dart';
import '../../features/auth/presentation/inicio_sesion_pantalla.dart';
import '../../features/auth/presentation/registro_pantalla.dart';
import '../../features/auth/presentation/sesion_controlador.dart';
import '../../features/inicio/presentation/inicio_pantalla.dart';
import '../../features/inicio/presentation/mi_cuenta_pantalla.dart';

/// Rutas de la app. Cada funcionalidad agrega aquí las suyas.
abstract final class Rutas {
  static const cargando = '/cargando';
  static const inicioSesion = '/inicio-sesion';
  static const registro = '/registro';
  static const cuentaCreada = '/cuenta-creada';
  static const inicio = '/inicio';
  static const miCuenta = '/inicio/mi-cuenta';

  /// Se ven sin haber iniciado sesión.
  static const publicas = {inicioSesion, registro, cuentaCreada};
}

/// Decide a dónde ir según la sesión: sin sesión solo se ven las pantallas
/// públicas, y con sesión, la pantalla principal y lo que cuelga de ella.
String? redirigir(EstadoSesion sesion, String ubicacion) => switch (sesion) {
  SesionCargando() => ubicacion == Rutas.cargando ? null : Rutas.cargando,
  SinSesion() => Rutas.publicas.contains(ubicacion) ? null : Rutas.inicioSesion,
  ConSesion() => _esDeInicio(ubicacion) ? null : Rutas.inicio,
};

final appRouterProvider = Provider<GoRouter>((ref) {
  // go_router vuelve a calcular las rutas cada vez que cambia la sesión.
  final sesion = ValueNotifier<EstadoSesion>(ref.read(sesionProvider));
  ref
    ..listen(sesionProvider, (_, nueva) => sesion.value = nueva)
    ..onDispose(sesion.dispose);

  /// Pantalla que necesita el perfil. Mientras la sesión cambia (al cerrar
  /// sesión), se muestra la de carga hasta que la redirección termine.
  Widget conPerfil(Widget Function(PerfilUsuario perfil) pantalla) =>
      switch (sesion.value) {
        ConSesion(:final perfil) => pantalla(perfil),
        _ => const CargandoPantalla(),
      };

  final router = GoRouter(
    initialLocation: Rutas.cargando,
    refreshListenable: sesion,
    redirect: (context, state) =>
        redirigir(sesion.value, state.matchedLocation),
    routes: [
      GoRoute(
        path: Rutas.cargando,
        builder: (context, state) => const CargandoPantalla(),
      ),
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
      GoRoute(
        path: Rutas.inicio,
        builder: (context, state) =>
            conPerfil((perfil) => InicioPantalla(perfil: perfil)),
        routes: [
          GoRoute(
            path: 'mi-cuenta',
            builder: (context, state) =>
                conPerfil((perfil) => MiCuentaPantalla(perfil: perfil)),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// La pantalla principal o una que cuelga de ella. Ojo: "/inicio-sesion"
/// empieza igual, pero no es de inicio.
bool _esDeInicio(String ubicacion) =>
    ubicacion == Rutas.inicio || ubicacion.startsWith('${Rutas.inicio}/');
