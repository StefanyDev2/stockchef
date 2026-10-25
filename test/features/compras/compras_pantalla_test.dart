import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stockchef/core/router/app_router.dart';
import 'package:stockchef/features/auth/domain/perfil_usuario.dart';
import 'package:stockchef/features/compras/domain/compras.dart';
import 'package:stockchef/features/inicio/presentation/inicio_pantalla.dart';
import 'package:stockchef/features/usuarios/domain/usuarios.dart';

import '../../ayudantes.dart';

Finder _texto(String clave) => find.descendant(
  of: find.byKey(Key('campo-$clave')),
  matching: find.byType(TextField),
);

Finder get _guardar => find.widgetWithText(FilledButton, 'Guardar compra');

void main() {
  late ComprasFalsas compras;

  setUp(() => compras = ComprasFalsas());

  Future<void> abrirCompras(WidgetTester tester) async {
    await abrirApp(
      tester,
      sesion: SesionFalsa(guardada: perfilDePrueba()),
      compras: compras,
      tamano: const Size(1080, 3000),
    );
    await tester.tap(find.text('Compras'));
    await tester.pumpAndSettle();
  }

  Future<void> elegir(WidgetTester tester, String campo, String opcion) async {
    await tester.tap(find.byKey(Key('campo-$campo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcion).last);
    await tester.pumpAndSettle();
  }

  /// Llena la compra de tomate. El tipo es obligatorio (HU-007, CA3).
  Future<void> llenarTomate(
    WidgetTester tester, {
    String tipo = 'Planeada',
  }) async {
    await tester.tap(find.text(tipo));
    await tester.pump();
    await elegir(tester, 'insumo', 'Tomate');
    await tester.enterText(_texto('cantidad'), '10');
    await tester.enterText(_texto('proveedor'), 'Distrialimentos');
    await tester.enterText(_texto('precio'), r'$50.000');
    await tester.pump();
  }

  testWidgets('CA1, CA4: el formulario tiene los campos del prototipo', (
    tester,
  ) async {
    await abrirCompras(tester);

    expect(find.text('Compra de insumos'), findsOneWidget);
    expect(find.text('Planeada'), findsOneWidget);
    expect(find.text('Emergencia'), findsOneWidget);
    for (final etiqueta in [
      'Insumo',
      'Cantidad',
      'Unidad',
      'Proveedor (opcional)',
      'Precio total',
    ]) {
      expect(find.text(etiqueta), findsOneWidget, reason: etiqueta);
    }

    await tester.tap(find.byKey(const Key('campo-unidad')));
    await tester.pumpAndSettle();
    for (final unidad in [
      'Kilogramo',
      'Gramo',
      'Libra',
      'Litro',
      'Mililitro',
      'Unidad',
    ]) {
      expect(find.text(unidad), findsWidgets, reason: unidad);
    }
  });

  testWidgets('CA3: la lista de insumos muestra los activos', (tester) async {
    await abrirCompras(tester);

    await tester.tap(find.byKey(const Key('campo-insumo')));
    await tester.pumpAndSettle();

    expect(find.text('Tomate'), findsWidgets);
    expect(find.text('Aceite'), findsWidgets);
  });

  testWidgets('al elegir el insumo propone su unidad y muestra lo disponible', (
    tester,
  ) async {
    await abrirCompras(tester);

    await elegir(tester, 'insumo', 'Aceite');

    expect(find.text('Disponible: 3 L'), findsOneWidget);
    expect(find.text('Litro'), findsOneWidget);
  });

  testWidgets('CA5: sin datos avisa y marca los campos pendientes', (
    tester,
  ) async {
    await abrirCompras(tester);

    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    expect(find.text(MensajesCompras.camposPendientes), findsOneWidget);
    // Insumo, cantidad, unidad, precio y tipo de compra (HU-007, CA3).
    expect(find.text(MensajesCompras.campoObligatorio), findsNWidgets(5));
    expect(compras.enviados, isEmpty);
  });

  testWidgets('HU-007, CA3: ningún tipo viene marcado y es obligatorio', (
    tester,
  ) async {
    await abrirCompras(tester);
    // Todo lleno menos el tipo: si alguno viniera marcado, se guardaría.
    await elegir(tester, 'insumo', 'Tomate');
    await tester.enterText(_texto('cantidad'), '10');
    await tester.enterText(_texto('precio'), '50000');
    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    expect(find.text(MensajesCompras.camposPendientes), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.byKey(const Key('campo-tipo')),
          matching: find.byType(ListView),
        ),
        matching: find.text(MensajesCompras.campoObligatorio),
      ),
      findsOneWidget,
    );
    expect(compras.enviados, isEmpty);

    // Al elegir el tipo, la alerta se va y ya se puede guardar.
    await tester.tap(find.text('Emergencia'));
    await tester.pump();
    expect(find.text(MensajesCompras.campoObligatorio), findsNothing);
    expect(find.text(MensajesCompras.camposPendientes), findsNothing);

    await tester.tap(_guardar);
    await tester.pumpAndSettle();
    expect(compras.enviados.single['tipo'], 'emergencia');
  });

  testWidgets('CA6: cantidad o precio en cero no se envían', (tester) async {
    await abrirCompras(tester);
    await llenarTomate(tester);
    await tester.enterText(_texto('cantidad'), '0');

    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    expect(find.text(MensajesCompras.valoresInvalidos), findsOneWidget);
    expect(find.text(MensajesCompras.mayorACero), findsOneWidget);
    expect(compras.enviados, isEmpty);
  });

  testWidgets('CA8, CA11: guarda y muestra el resumen y el historial', (
    tester,
  ) async {
    await abrirCompras(tester);
    await llenarTomate(tester);

    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    expect(compras.enviados.single, {
      'insumoId': 'tomate',
      'cantidad': 10.0,
      'unidad': 'kilogramo',
      'proveedor': 'Distrialimentos',
      'precioTotal': 50000.0,
      'tipo': 'planeada',
    });
    expect(find.text('Historial de compras'), findsOneWidget);
    expect(find.text(MensajesCompras.compraGuardada), findsOneWidget);
    expect(find.text('Insumo: Tomate'), findsOneWidget);
    expect(find.text('Cantidad: 10 kg'), findsOneWidget);
    expect(find.text(r'Precio: $50.000'), findsOneWidget);
    expect(find.text('Nueva cantidad disponible: 15 kg'), findsOneWidget);
    expect(find.text('Proveedor: Distrialimentos'), findsOneWidget);
    expect(find.text(r'Precio por kilogramo: $5.000'), findsOneWidget);
  });

  testWidgets('una compra de emergencia queda marcada así', (tester) async {
    await abrirCompras(tester);
    await llenarTomate(tester, tipo: 'Emergencia');

    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    expect(compras.enviados.single['tipo'], 'emergencia');
    // La etiqueta de la tarjeta, además del resumen y el filtro.
    expect(
      find.descendant(
        of: find.byKey(const Key('resumen-emergencia')),
        matching: find.text('1 compra'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('"Registrar otra compra" abre el formulario vacío', (
    tester,
  ) async {
    await abrirCompras(tester);
    await llenarTomate(tester);
    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrar otra compra'));
    await tester.pumpAndSettle();

    expect(find.text('Compra de insumos'), findsOneWidget);
    expect(
      tester.widget<TextField>(_texto('cantidad')).controller!.text,
      isEmpty,
    );
  });

  testWidgets('un error del servidor se muestra y conserva los datos', (
    tester,
  ) async {
    compras.respuesta = const CompraRechazada(
      'Esa unidad no sirve para este insumo, que se mide en kilogramo.',
    );
    await abrirCompras(tester);
    await llenarTomate(tester);
    await elegir(tester, 'unidad', 'Litro');

    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Esa unidad no sirve para este insumo, que se mide en kilogramo.',
      ),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(_texto('cantidad')).controller!.text, '10');
  });

  testWidgets('CA12: el servidor rechaza a quien ya no es administrador', (
    tester,
  ) async {
    compras.respuesta = const CompraSinPermiso();
    await abrirCompras(tester);
    await llenarTomate(tester);

    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    expect(find.text(MensajesUsuarios.sinPermisoTitulo), findsOneWidget);
  });

  group('ver el historial sin registrar una compra', () {
    Future<void> guardarUnaYVolverAlInicio(WidgetTester tester) async {
      await llenarTomate(tester);
      await tester.tap(_guardar);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
    }

    testWidgets('desde el formulario se vuelve a ver el historial', (
      tester,
    ) async {
      await abrirCompras(tester);
      await guardarUnaYVolverAlInicio(tester);
      expect(
        find.text('Hola Camila,\n¿Qué quieres hacer hoy?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Compras'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver historial de compras'));
      await tester.pumpAndSettle();

      expect(find.text('Historial de compras'), findsOneWidget);
      expect(find.text(r'Precio total: $50.000'), findsOneWidget);
      // No es el aviso de una compra recién guardada.
      expect(find.text(MensajesCompras.compraGuardada), findsNothing);
      expect(find.text('Registrar compra'), findsOneWidget);
    });

    testWidgets('el ícono de arriba también abre el historial', (tester) async {
      await abrirCompras(tester);

      await tester.tap(find.byTooltip('Ver historial de compras'));
      await tester.pumpAndSettle();

      expect(find.text('Historial de compras'), findsOneWidget);
      expect(find.text('Todavía no hay compras registradas.'), findsOneWidget);
    });

    testWidgets('al volver del historial, el formulario conserva lo escrito', (
      tester,
    ) async {
      await abrirCompras(tester);
      await tester.enterText(_texto('cantidad'), '12');

      await tester.tap(find.text('Ver historial de compras'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();

      expect(find.text('Compra de insumos'), findsOneWidget);
      expect(
        tester.widget<TextField>(_texto('cantidad')).controller!.text,
        '12',
      );
    });

    testWidgets('"Registrar compra" en el historial vuelve al formulario', (
      tester,
    ) async {
      await abrirCompras(tester);
      await tester.tap(find.text('Ver historial de compras'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registrar compra'));
      await tester.pumpAndSettle();

      expect(find.text('Compra de insumos'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(
        find.text('Hola Camila,\n¿Qué quieres hacer hoy?'),
        findsOneWidget,
      );
    });

    testWidgets('el auxiliar también puede ver el historial', (tester) async {
      await abrirApp(
        tester,
        sesion: SesionFalsa(
          guardada: perfilDePrueba(nombres: 'Daniela', rol: Rol.auxiliarCocina),
        ),
        compras: compras,
        tamano: const Size(1080, 3000),
      );
      await tester.tap(find.text('Registrar compra'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver historial de compras'));
      await tester.pumpAndSettle();

      expect(find.text('Historial de compras'), findsOneWidget);
      expect(find.text('Resumen de compras'), findsNothing);
    });
  });

  group('quién registra compras (HU-006 y HU-007)', () {
    final daniela = perfilDePrueba(nombres: 'Daniela', rol: Rol.auxiliarCocina);
    final andres = perfilDePrueba(nombres: 'Andrés', rol: Rol.sinRol);

    testWidgets('HU-007, CA1: el auxiliar registra una compra de emergencia', (
      tester,
    ) async {
      await abrirApp(
        tester,
        sesion: SesionFalsa(guardada: daniela),
        compras: compras,
        tamano: const Size(1080, 3000),
      );
      expect(find.text('Compras'), findsNothing);

      await tester.tap(find.text('Registrar compra'));
      await tester.pumpAndSettle();
      await llenarTomate(tester, tipo: 'Emergencia');
      await tester.tap(_guardar);
      await tester.pumpAndSettle();

      expect(compras.enviados.single['tipo'], 'emergencia');
      expect(find.text(MensajesCompras.compraGuardada), findsOneWidget);
      // HU-007, CA5: consulta el tipo en el historial.
      expect(find.text('Emergencia'), findsOneWidget);
      // El resumen y el filtro son del administrador.
      expect(find.text('Resumen de compras'), findsNothing);
      expect(find.text('Todas'), findsNothing);
    });

    for (final ruta in [Rutas.compras, Rutas.historialCompras]) {
      testWidgets(
        'un usuario sin rol que llega a $ruta ve "No tienes permisos"',
        (tester) async {
          await abrirApp(tester, sesion: SesionFalsa(guardada: andres));

          GoRouter.of(tester.element(find.byType(InicioPantalla))).go(ruta);
          await tester.pumpAndSettle();

          expect(find.text(MensajesUsuarios.sinPermisoTitulo), findsOneWidget);
          expect(find.text('Guardar compra'), findsNothing);
        },
      );
    }
  });

  group('HU-007, CA6: filtro y resumen del administrador', () {
    Future<void> registrar(
      WidgetTester tester, {
      required bool emergencia,
      required String precio,
    }) async {
      await llenarTomate(tester, tipo: emergencia ? 'Emergencia' : 'Planeada');
      await tester.enterText(_texto('precio'), precio);
      await tester.tap(_guardar);
      await tester.pumpAndSettle();
    }

    Finder resumen(String tipo, String texto) => find.descendant(
      of: find.byKey(Key('resumen-$tipo')),
      matching: find.text(texto),
    );

    testWidgets('muestra cuántas compras y cuánto dinero de cada tipo', (
      tester,
    ) async {
      await abrirCompras(tester);
      await registrar(tester, emergencia: false, precio: '50000');
      await tester.tap(find.text('Registrar otra compra'));
      await tester.pumpAndSettle();
      await registrar(tester, emergencia: true, precio: '20000');
      await tester.tap(find.text('Registrar otra compra'));
      await tester.pumpAndSettle();
      await registrar(tester, emergencia: true, precio: '15000');

      expect(find.text('Resumen de compras'), findsOneWidget);
      expect(resumen('planeada', '1 compra'), findsOneWidget);
      expect(resumen('planeada', r'$50.000'), findsOneWidget);
      expect(resumen('emergencia', '2 compras'), findsOneWidget);
      expect(resumen('emergencia', r'$35.000'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Emergencia'));
      await tester.pumpAndSettle();
      expect(find.text(r'Precio total: $50.000'), findsNothing);
      expect(find.text(r'Precio total: $20.000'), findsOneWidget);
      expect(find.text(r'Precio total: $15.000'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Planeadas'));
      await tester.pumpAndSettle();
      expect(find.text(r'Precio total: $50.000'), findsOneWidget);
      expect(find.text(r'Precio total: $20.000'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Todas'));
      await tester.pumpAndSettle();
      // Vuelven a verse las de los dos tipos (la más reciente arriba).
      expect(find.text(r'Precio total: $15.000'), findsOneWidget);
      expect(find.text(r'Precio total: $20.000'), findsOneWidget);
    });
  });
}
