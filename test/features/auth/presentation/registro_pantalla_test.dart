import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/app.dart';
import 'package:stockchef/features/auth/domain/datos_registro.dart';
import 'package:stockchef/features/auth/domain/mensajes_validacion.dart';
import 'package:stockchef/features/auth/domain/registro_repositorio.dart';
import 'package:stockchef/features/auth/presentation/registro_controlador.dart';

/// Repositorio falso: guarda lo que recibe y responde lo que se le indique.
class RegistroFalso implements RegistroRepositorio {
  ResultadoRegistro respuesta = const RegistroExitoso(rol: 'administrador');
  Completer<void>? pausa;
  final recibidos = <DatosRegistro>[];

  @override
  Future<ResultadoRegistro> registrar(DatosRegistro datos) async {
    recibidos.add(datos);
    await pausa?.future;
    return respuesta;
  }
}

const _validos = {
  CampoRegistro.nombres: 'Camila',
  CampoRegistro.apellidos: 'Ruiz',
  CampoRegistro.correo: 'Camila@Correo.com',
  CampoRegistro.restaurante: 'Sabor Casero',
  CampoRegistro.contrasena: 'Cocina12',
  CampoRegistro.confirmacion: 'Cocina12',
};

Finder _campo(CampoRegistro campo) => find.descendant(
  of: find.byKey(Key('campo-${campo.name}')),
  matching: find.byType(TextField),
);

String _valor(WidgetTester tester, CampoRegistro campo) =>
    tester.widget<TextField>(_campo(campo)).controller!.text;

Finder get _botonRegistrarse =>
    find.widgetWithText(FilledButton, 'Registrarse');

void main() {
  late RegistroFalso repositorio;

  Future<void> abrirRegistro(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [registroRepositorioProvider.overrideWithValue(repositorio)],
        child: const StockChefApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();
  }

  Future<void> llenar(
    WidgetTester tester,
    Map<CampoRegistro, String> valores,
  ) async {
    for (final MapEntry(key: campo, value: texto) in valores.entries) {
      await tester.enterText(_campo(campo), texto);
    }
    await tester.pump();
  }

  Future<void> tocarRegistrarse(WidgetTester tester) async {
    await tester.tap(_botonRegistrarse);
    await tester.pumpAndSettle();
  }

  setUp(() => repositorio = RegistroFalso());

  testWidgets('CA1: muestra los 6 campos, la ayuda de contraseña y el botón', (
    tester,
  ) async {
    await abrirRegistro(tester);

    for (final campo in CampoRegistro.values) {
      expect(
        find.descendant(
          of: find.byKey(Key('campo-${campo.name}')),
          matching: find.text(campo.etiqueta),
        ),
        findsWidgets,
        reason: campo.name,
      );
      expect(_campo(campo), findsOneWidget);
    }
    expect(find.text(MensajesValidacion.ayudaContrasena), findsOneWidget);
    expect(_botonRegistrarse, findsOneWidget);
  });

  testWidgets('CA2, CA3 (E1): sin datos marca cada campo y no envía nada', (
    tester,
  ) async {
    await abrirRegistro(tester);

    await tocarRegistrarse(tester);

    expect(find.text(MensajesValidacion.completaCampos), findsOneWidget);
    expect(find.text(MensajesValidacion.campoObligatorio), findsNWidgets(6));
    expect(repositorio.recibidos, isEmpty);
  });

  testWidgets('CA3: solo marca los campos que faltan', (tester) async {
    await abrirRegistro(tester);
    await llenar(tester, {
      ..._validos,
      CampoRegistro.apellidos: '',
      CampoRegistro.restaurante: '   ',
    });

    await tocarRegistrarse(tester);

    expect(find.text(MensajesValidacion.campoObligatorio), findsNWidgets(2));
    expect(repositorio.recibidos, isEmpty);
  });

  testWidgets(
    'CA4, CA6, CA7, CA8 (E2): muestra cada error y conserva los datos',
    (tester) async {
      await abrirRegistro(tester);
      final invalidos = {
        ..._validos,
        CampoRegistro.correo: 'camila@correo',
        CampoRegistro.contrasena: 'cocina',
        CampoRegistro.confirmacion: 'cocin',
      };
      await llenar(tester, invalidos);

      await tocarRegistrarse(tester);

      expect(find.text(MensajesValidacion.corrigeCampos), findsOneWidget);
      expect(find.text(MensajesValidacion.correoInvalido), findsOneWidget);
      expect(find.text(MensajesValidacion.contrasenaDebil), findsOneWidget);
      expect(
        find.text(MensajesValidacion.contrasenasNoCoinciden),
        findsOneWidget,
      );
      for (final MapEntry(key: campo, value: texto) in invalidos.entries) {
        expect(_valor(tester, campo), texto, reason: 'conserva ${campo.name}');
      }
      expect(repositorio.recibidos, isEmpty);
    },
  );

  testWidgets('CA8: al corregir un campo se quita su error y luego el aviso', (
    tester,
  ) async {
    await abrirRegistro(tester);
    await llenar(tester, {..._validos, CampoRegistro.correo: 'camila@correo'});
    await tocarRegistrarse(tester);
    expect(find.text(MensajesValidacion.correoInvalido), findsOneWidget);

    await tester.enterText(_campo(CampoRegistro.correo), 'camila@correo.com');
    await tester.pump();

    expect(find.text(MensajesValidacion.correoInvalido), findsNothing);
    expect(find.text(MensajesValidacion.corrigeCampos), findsNothing);
    expect(_valor(tester, CampoRegistro.nombres), 'Camila');
  });

  testWidgets('CA9, CA11: con datos válidos crea la cuenta y lleva al inicio', (
    tester,
  ) async {
    await abrirRegistro(tester);
    await llenar(tester, _validos);

    await tocarRegistrarse(tester);

    expect(repositorio.recibidos, hasLength(1));
    expect(
      repositorio.recibidos.single.aEnvio()['correo'],
      'camila@correo.com',
    );
    expect(find.text('¡Cuenta creada exitosamente!'), findsOneWidget);

    await tester.tap(find.text('Ir a iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a StockChef'), findsOneWidget);
  });

  testWidgets('CA11: "atrás" en la cuenta creada no vuelve al formulario', (
    tester,
  ) async {
    await abrirRegistro(tester);
    await llenar(tester, _validos);
    await tocarRegistrarse(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a StockChef'), findsOneWidget);
    expect(find.text('Registro de usuario'), findsNothing);
  });

  testWidgets(
    'CA5: correo ya registrado se marca en el campo y conserva todo',
    (tester) async {
      repositorio.respuesta = const RegistroRechazado({
        CampoRegistro.correo: MensajesValidacion.correoRegistrado,
      });
      await abrirRegistro(tester);
      await llenar(tester, _validos);

      await tocarRegistrarse(tester);

      expect(find.text(MensajesValidacion.correoRegistrado), findsOneWidget);
      expect(find.text(MensajesValidacion.corrigeCampos), findsOneWidget);
      for (final MapEntry(key: campo, value: texto) in _validos.entries) {
        expect(_valor(tester, campo), texto, reason: 'conserva ${campo.name}');
      }
    },
  );

  testWidgets('sin conexión muestra el aviso y permite reintentar', (
    tester,
  ) async {
    repositorio.respuesta = const RegistroFallido(
      MensajesValidacion.sinConexion,
    );
    await abrirRegistro(tester);
    await llenar(tester, _validos);

    await tocarRegistrarse(tester);
    expect(find.text(MensajesValidacion.sinConexion), findsOneWidget);

    repositorio.respuesta = const RegistroExitoso();
    await tocarRegistrarse(tester);
    expect(find.text('¡Cuenta creada exitosamente!'), findsOneWidget);
    expect(repositorio.recibidos, hasLength(2));
  });

  testWidgets('mientras envía, el botón se bloquea y no se envía dos veces', (
    tester,
  ) async {
    repositorio.pausa = Completer<void>();
    await abrirRegistro(tester);
    await llenar(tester, _validos);

    await tester.tap(_botonRegistrarse);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    repositorio.pausa!.complete();
    await tester.pumpAndSettle();
    expect(repositorio.recibidos, hasLength(1));
    expect(find.text('¡Cuenta creada exitosamente!'), findsOneWidget);
  });

  testWidgets('la contraseña va oculta y el ojo permite verla', (tester) async {
    await abrirRegistro(tester);
    bool oculta() =>
        tester.widget<TextField>(_campo(CampoRegistro.contrasena)).obscureText;

    expect(oculta(), isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña').first);
    await tester.pump();
    expect(oculta(), isFalse);
  });
}
