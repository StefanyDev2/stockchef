import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/core/router/app_router.dart';
import 'package:stockchef/features/auth/presentation/sesion_controlador.dart';

import '../ayudantes.dart';

void main() {
  final conSesion = ConSesion(perfilDePrueba());

  test('mientras se revisa la sesión guardada, se ve la pantalla de carga', () {
    expect(
      redirigir(const SesionCargando(), Rutas.inicioSesion),
      Rutas.cargando,
    );
    expect(redirigir(const SesionCargando(), Rutas.cargando), isNull);
  });

  test('sin sesión solo se ven las pantallas públicas', () {
    for (final publica in Rutas.publicas) {
      expect(redirigir(const SinSesion(), publica), isNull, reason: publica);
    }
    for (final privada in [Rutas.inicio, Rutas.miCuenta, Rutas.cargando]) {
      expect(
        redirigir(const SinSesion(), privada),
        Rutas.inicioSesion,
        reason: privada,
      );
    }
  });

  test('con sesión se va a la pantalla principal y a Mi cuenta', () {
    expect(redirigir(conSesion, Rutas.inicio), isNull);
    expect(redirigir(conSesion, Rutas.miCuenta), isNull);
    for (final otra in [
      Rutas.inicioSesion,
      Rutas.registro,
      Rutas.cuentaCreada,
      Rutas.cargando,
    ]) {
      expect(redirigir(conSesion, otra), Rutas.inicio, reason: otra);
    }
  });
}
