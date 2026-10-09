import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/app.dart';
import 'package:stockchef/features/auth/domain/inicio_sesion.dart';
import 'package:stockchef/features/auth/domain/perfil_usuario.dart';
import 'package:stockchef/features/auth/presentation/sesion_controlador.dart';

PerfilUsuario perfilDePrueba({
  String nombres = 'Camila',
  String apellidos = 'Ruiz',
  Rol rol = Rol.administrador,
  bool activo = true,
}) => PerfilUsuario(
  uid: 'uid-$nombres',
  nombres: nombres,
  apellidos: apellidos,
  correo: '${nombres.toLowerCase()}@correo.com',
  rol: rol,
  activo: activo,
);

/// Sesión falsa. Por defecto acepta camila@correo.com / Cocina12 como
/// administradora y rechaza todo lo demás.
class SesionFalsa implements SesionRepositorio {
  SesionFalsa({this.guardada});

  /// Perfil de la sesión que "quedó abierta" al cerrar la app.
  PerfilUsuario? guardada;

  /// Si tiene valor, se responde esto en lugar de revisar las credenciales.
  ResultadoInicioSesion? respuesta;
  PerfilUsuario perfil = perfilDePrueba();
  Completer<void>? pausa;

  final intentos = <DatosInicioSesion>[];
  var sesionesCerradas = 0;

  @override
  Future<ResultadoInicioSesion> iniciarSesion(DatosInicioSesion datos) async {
    intentos.add(datos);
    await pausa?.future;
    if (respuesta != null) return respuesta!;
    final correcto =
        datos.correoNormalizado == 'camila@correo.com' &&
        datos.contrasena == 'Cocina12';
    return correcto
        ? SesionIniciada(perfil)
        : const SesionRechazada(MensajesInicioSesion.credencialesInvalidas);
  }

  @override
  Future<PerfilUsuario?> sesionGuardada() async => guardada;

  @override
  Future<void> cerrarSesion() async {
    sesionesCerradas++;
    guardada = null;
  }
}

/// Abre la app completa con un teléfono de 360 × 800 y la sesión falsa.
Future<void> abrirApp(
  WidgetTester tester, {
  SesionFalsa? sesion,
  Size tamano = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sesionRepositorioProvider.overrideWithValue(sesion ?? SesionFalsa()),
      ],
      child: const StockChefApp(),
    ),
  );
  await tester.pumpAndSettle();
}
