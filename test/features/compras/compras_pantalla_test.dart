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

  Future<void> llenarTomate(WidgetTester tester) async {
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
    expect(find.text(MensajesCompras.campoObligatorio), findsNWidgets(4));
    expect(compras.enviados, isEmpty);
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
    await tester.tap(find.text('Emergencia'));
    await tester.pump();
    await llenarTomate(tester);

    await tester.tap(_guardar);
    await tester.pumpAndSettle();

    expect(compras.enviados.single['tipo'], 'emergencia');
    expect(find.text('Emergencia'), findsOneWidget);
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

  group('CA12: solo el administrador', () {
    final daniela = perfilDePrueba(nombres: 'Daniela', rol: Rol.auxiliarCocina);

    testWidgets('el auxiliar no ve "Compras"', (tester) async {
      await abrirApp(tester, sesion: SesionFalsa(guardada: daniela));
      expect(find.text('Compras'), findsNothing);
    });

    for (final ruta in [Rutas.compras, Rutas.historialCompras]) {
      testWidgets('el auxiliar que llega a $ruta ve "No tienes permisos"', (
        tester,
      ) async {
        await abrirApp(tester, sesion: SesionFalsa(guardada: daniela));

        GoRouter.of(tester.element(find.byType(InicioPantalla))).go(ruta);
        await tester.pumpAndSettle();

        expect(find.text(MensajesUsuarios.sinPermisoTitulo), findsOneWidget);
        expect(find.text('Guardar compra'), findsNothing);
      });
    }
  });
}
