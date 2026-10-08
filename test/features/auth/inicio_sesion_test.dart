import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/app.dart';
import 'package:stockchef/features/auth/data/sesion_repositorio_firebase.dart';
import 'package:stockchef/features/auth/domain/inicio_sesion.dart';
import 'package:stockchef/features/auth/presentation/inicio_sesion_controlador.dart';

/// Sesión falsa: acepta solo la cuenta de Camila.
class SesionFalsa implements SesionRepositorio {
  final intentos = <DatosInicioSesion>[];
  ResultadoInicioSesion? respuestaForzada;
  Completer<void>? pausa;
  var sesionesCerradas = 0;

  @override
  Future<ResultadoInicioSesion> iniciarSesion(DatosInicioSesion datos) async {
    intentos.add(datos);
    await pausa?.future;
    if (respuestaForzada != null) return respuestaForzada!;
    final correcto =
        datos.correoNormalizado == 'camila@correo.com' &&
        datos.contrasena == 'Cocina12';
    return correcto
        ? const SesionIniciada(nombre: 'Camila Ruiz')
        : const SesionRechazada(MensajesInicioSesion.credencialesInvalidas);
  }

  @override
  Future<void> cerrarSesion() async => sesionesCerradas++;
}

Finder _campo(String nombre) => find.descendant(
  of: find.byKey(Key('campo-$nombre')),
  matching: find.byType(TextField),
);

Finder get _botonIngresar =>
    find.widgetWithText(FilledButton, 'INICIAR SESIÓN');

void main() {
  group('DatosInicioSesion.validar', () {
    test('pide ambos campos', () {
      expect(const DatosInicioSesion().validar(), {
        CampoInicioSesion.correo: MensajesInicioSesion.ingresaCorreo,
        CampoInicioSesion.contrasena: MensajesInicioSesion.ingresaContrasena,
      });
      expect(const DatosInicioSesion(correo: '  ', contrasena: 'x').validar(), {
        CampoInicioSesion.correo: MensajesInicioSesion.ingresaCorreo,
      });
    });

    test('con ambos campos no hay errores y el correo se normaliza', () {
      const datos = DatosInicioSesion(
        correo: ' Camila@Correo.com ',
        contrasena: 'Cocina12',
      );
      expect(datos.validar(), isEmpty);
      expect(datos.correoNormalizado, 'camila@correo.com');
    });
  });

  group('mensajeErrorInicioSesion', () {
    test('correo desconocido y contraseña errada dan el mismo mensaje', () {
      for (final codigo in [
        'invalid-credential',
        'wrong-password',
        'user-not-found',
        'invalid-email',
      ]) {
        expect(
          mensajeErrorInicioSesion(codigo),
          MensajesInicioSesion.credencialesInvalidas,
          reason: codigo,
        );
      }
    });

    test('sin red pide revisar la conexión; lo demás es error general', () {
      expect(
        mensajeErrorInicioSesion('network-request-failed'),
        MensajesInicioSesion.sinConexion,
      );
      expect(
        mensajeErrorInicioSesion('internal-error'),
        MensajesInicioSesion.errorInterno,
      );
    });
  });

  group('pantalla de inicio de sesión', () {
    late SesionFalsa sesion;

    setUp(() => sesion = SesionFalsa());

    Future<void> abrirApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sesionRepositorioProvider.overrideWithValue(sesion)],
          child: const StockChefApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> ingresar(
      WidgetTester tester,
      String correo,
      String contrasena,
    ) async {
      await tester.enterText(_campo('correo'), correo);
      await tester.enterText(_campo('contrasena'), contrasena);
      await tester.tap(_botonIngresar);
      await tester.pumpAndSettle();
    }

    testWidgets('muestra correo, contraseña oculta y el botón del prototipo', (
      tester,
    ) async {
      await abrirApp(tester);

      expect(_campo('correo'), findsOneWidget);
      expect(
        tester.widget<TextField>(_campo('contrasena')).obscureText,
        isTrue,
      );
      expect(_botonIngresar, findsOneWidget);
      expect(find.text('¿Olvidaste tu contraseña?'), findsNothing);
    });

    testWidgets('sin datos pide ambos campos y no intenta entrar', (
      tester,
    ) async {
      await abrirApp(tester);

      await tester.tap(_botonIngresar);
      await tester.pumpAndSettle();

      expect(find.text(MensajesInicioSesion.completaAmbos), findsOneWidget);
      expect(find.text(MensajesInicioSesion.ingresaCorreo), findsOneWidget);
      expect(find.text(MensajesInicioSesion.ingresaContrasena), findsOneWidget);
      expect(sesion.intentos, isEmpty);
    });

    testWidgets(
      'CA12: el usuario registrado entra con su correo y contraseña',
      (tester) async {
        await abrirApp(tester);

        await ingresar(tester, ' Camila@Correo.com ', 'Cocina12');

        expect(find.text('Hola, Camila Ruiz'), findsOneWidget);
        expect(find.text('Iniciaste sesión correctamente.'), findsOneWidget);
      },
    );

    testWidgets(
      'credenciales erradas muestran un mensaje genérico y conservan el correo',
      (tester) async {
        await abrirApp(tester);

        await ingresar(tester, 'camila@correo.com', 'Otra1234');

        expect(
          find.text(MensajesInicioSesion.credencialesInvalidas),
          findsOneWidget,
        );
        expect(
          tester.widget<TextField>(_campo('correo')).controller!.text,
          'camila@correo.com',
        );
        expect(find.text('Hola, Camila Ruiz'), findsNothing);
      },
    );

    testWidgets('después de un error se puede reintentar y entrar', (
      tester,
    ) async {
      await abrirApp(tester);
      await ingresar(tester, 'camila@correo.com', 'Otra1234');

      await tester.enterText(_campo('contrasena'), 'Cocina12');
      await tester.pump();
      expect(
        find.text(MensajesInicioSesion.credencialesInvalidas),
        findsNothing,
      );

      await tester.tap(_botonIngresar);
      await tester.pumpAndSettle();
      expect(find.text('Hola, Camila Ruiz'), findsOneWidget);
      expect(sesion.intentos, hasLength(2));
    });

    testWidgets('mientras ingresa, el botón se bloquea', (tester) async {
      sesion.pausa = Completer<void>();
      await abrirApp(tester);
      await tester.enterText(_campo('correo'), 'camila@correo.com');
      await tester.enterText(_campo('contrasena'), 'Cocina12');

      await tester.tap(_botonIngresar);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      sesion.pausa!.complete();
      await tester.pumpAndSettle();
      expect(sesion.intentos, hasLength(1));
    });

    testWidgets('"Cerrar sesión" termina la sesión y vuelve al inicio', (
      tester,
    ) async {
      await abrirApp(tester);
      await ingresar(tester, 'camila@correo.com', 'Cocina12');

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(sesion.sesionesCerradas, 1);
      expect(_botonIngresar, findsOneWidget);
    });
  });
}
