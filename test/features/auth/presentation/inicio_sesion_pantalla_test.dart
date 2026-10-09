import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/features/auth/domain/inicio_sesion.dart';

import '../../../ayudantes.dart';

Finder _campo(String nombre) => find.descendant(
  of: find.byKey(Key('campo-$nombre')),
  matching: find.byType(TextField),
);

Finder get _botonIngresar =>
    find.widgetWithText(FilledButton, 'INICIAR SESIÓN');

bool _habilitado(WidgetTester tester) =>
    tester.widget<FilledButton>(_botonIngresar).onPressed != null;

void main() {
  late SesionFalsa sesion;

  setUp(() => sesion = SesionFalsa());

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

  testWidgets('CA1, CA2: correo, contraseña oculta con ojo y botón', (
    tester,
  ) async {
    await abrirApp(tester, sesion: sesion);

    expect(_campo('correo'), findsOneWidget);
    bool oculta() => tester.widget<TextField>(_campo('contrasena')).obscureText;
    expect(oculta(), isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(oculta(), isFalse);
    expect(_botonIngresar, findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsNothing);
  });

  testWidgets('CA3 (E1): sin datos pide ambos campos y no intenta entrar', (
    tester,
  ) async {
    await abrirApp(tester, sesion: sesion);

    await tester.tap(_botonIngresar);
    await tester.pumpAndSettle();

    expect(find.text(MensajesInicioSesion.completaAmbos), findsOneWidget);
    expect(find.text(MensajesInicioSesion.ingresaCorreo), findsOneWidget);
    expect(find.text(MensajesInicioSesion.ingresaContrasena), findsOneWidget);
    expect(sesion.intentos, isEmpty);
  });

  testWidgets('CA4, CA5, CA6: con credenciales correctas entra a su pantalla', (
    tester,
  ) async {
    await abrirApp(tester, sesion: sesion);

    await ingresar(tester, ' Camila@Correo.com ', 'Cocina12');

    expect(find.text('Hola Camila,\n¿Qué quieres hacer hoy?'), findsOneWidget);
    expect(_botonIngresar, findsNothing);
  });

  testWidgets('CA8 (E2): credenciales erradas dan un mensaje genérico', (
    tester,
  ) async {
    await abrirApp(tester, sesion: sesion);

    await ingresar(tester, 'camila@correo.com', 'Otra1234');

    expect(
      find.text(MensajesInicioSesion.credencialesInvalidas),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(_campo('correo')).controller!.text,
      'camila@correo.com',
    );
    expect(_botonIngresar, findsOneWidget);
  });

  testWidgets('CA9: después de un error se puede reintentar y entrar', (
    tester,
  ) async {
    await abrirApp(tester, sesion: sesion);
    await ingresar(tester, 'camila@correo.com', 'Otra1234');

    await tester.enterText(_campo('contrasena'), 'Cocina12');
    await tester.pump();
    expect(find.text(MensajesInicioSesion.credencialesInvalidas), findsNothing);

    await tester.tap(_botonIngresar);
    await tester.pumpAndSettle();
    expect(find.text('Hola Camila,\n¿Qué quieres hacer hoy?'), findsOneWidget);
    expect(sesion.intentos, hasLength(2));
  });

  testWidgets('CA10, CA11 (E3): bloqueada deshabilita todo y lo explica', (
    tester,
  ) async {
    sesion.respuesta = SesionBloqueada(
      hasta: DateTime.now().add(const Duration(hours: 2)),
      minutos: 120,
    );
    await abrirApp(tester, sesion: sesion);

    await ingresar(tester, 'camila@correo.com', 'Cocina12');

    expect(
      find.text(MensajesInicioSesion.cuentaBloqueada(120)),
      findsOneWidget,
    );
    expect(find.text(MensajesInicioSesion.notaBloqueo), findsOneWidget);
    expect(_habilitado(tester), isFalse);
    expect(tester.widget<TextField>(_campo('correo')).enabled, isFalse);
    expect(tester.widget<TextField>(_campo('contrasena')).enabled, isFalse);

    // Tocar el botón deshabilitado no hace otro intento.
    await tester.tap(_botonIngresar);
    await tester.pump();
    expect(sesion.intentos, hasLength(1));
  });

  testWidgets('CA12: al vencer el bloqueo el formulario se habilita de nuevo', (
    tester,
  ) async {
    sesion.respuesta = SesionBloqueada(
      hasta: DateTime.now().add(const Duration(minutes: 1)),
      minutos: 1,
    );
    await abrirApp(tester, sesion: sesion);
    await ingresar(tester, 'camila@correo.com', 'Cocina12');
    expect(_habilitado(tester), isFalse);

    await tester.pump(const Duration(minutes: 1, seconds: 1));

    expect(_habilitado(tester), isTrue);
    expect(find.text(MensajesInicioSesion.notaBloqueo), findsNothing);
    expect(find.text(MensajesInicioSesion.cuentaBloqueada(1)), findsNothing);
  });

  testWidgets('cuenta desactivada no entra y lo explica', (tester) async {
    sesion.respuesta = const SesionRechazada(
      MensajesInicioSesion.cuentaDesactivada,
    );
    await abrirApp(tester, sesion: sesion);

    await ingresar(tester, 'pedro@correo.com', 'Cocina12');

    expect(find.text(MensajesInicioSesion.cuentaDesactivada), findsOneWidget);
    expect(_botonIngresar, findsOneWidget);
  });

  testWidgets('mientras ingresa, el botón se bloquea y no se envía dos veces', (
    tester,
  ) async {
    sesion.pausa = Completer<void>();
    await abrirApp(tester, sesion: sesion);
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
}
