import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stockchef/core/router/app_router.dart';
import 'package:stockchef/features/auth/domain/perfil_usuario.dart';
import 'package:stockchef/features/inicio/presentation/inicio_pantalla.dart';
import 'package:stockchef/features/insumos/data/insumos_repositorio_firebase.dart';
import 'package:stockchef/features/insumos/domain/insumos.dart';
import 'package:stockchef/features/usuarios/domain/usuarios.dart';

import '../../ayudantes.dart';

Finder _interruptor(String id) => find.descendant(
  of: find.byKey(Key('insumo-$id')),
  matching: find.byType(Switch),
);

Finder _en(String seccion, String texto) => find.descendant(
  of: find.byKey(Key('seccion-$seccion')),
  matching: find.text(texto),
);

Finder get _guardar => find.widgetWithText(FilledButton, 'Guardar cambios');

void main() {
  late InsumosFalsos insumos;

  setUp(() => insumos = InsumosFalsos());

  Future<void> abrirInsumos(WidgetTester tester) async {
    await abrirApp(
      tester,
      sesion: SesionFalsa(guardada: perfilDePrueba()),
      insumos: insumos,
      tamano: const Size(1080, 3000),
    );
    await tester.tap(find.text('Insumos'));
    await tester.pumpAndSettle();
  }

  group('dominio', () {
    test('sin el campo critico se considera "No crítico"', () {
      final i = InsumoRegistrado.desdeFirestore('arroz', {
        'nombre': 'Arroz',
        'activo': true,
      });
      expect(i.critico, isFalse);
      expect(
        InsumoRegistrado.desdeFirestore('x', {'critico': 'sí'}).critico,
        isFalse,
      );
    });

    test('CA6: separa críticos y otros, cada grupo por nombre', () {
      const lista = [
        InsumoRegistrado(
          id: 'p',
          nombre: 'Pollo',
          activo: true,
          critico: false,
        ),
        InsumoRegistrado(
          id: 'a',
          nombre: 'arroz',
          activo: true,
          critico: false,
        ),
        InsumoRegistrado(
          id: 't',
          nombre: 'Tomate',
          activo: true,
          critico: true,
        ),
        InsumoRegistrado(
          id: 'c',
          nombre: 'Cebolla',
          activo: false,
          critico: false,
        ),
      ];

      final grupos = separarPorCriticidad(lista, {'t', 'c'});

      expect(grupos.criticos.map((i) => i.id), ['c', 't']);
      expect(grupos.otros.map((i) => i.id), ['a', 'p']);
    });

    test('errores del servidor', () {
      expect(
        traducirErrorInsumos('permission-denied', 'x'),
        isA<ListaSinPermiso>(),
      );
      const msg = 'Uno de los insumos ya no existe. Vuelve a abrir la lista.';
      expect(
        (traducirErrorInsumos('failed-precondition', msg) as ListaRechazada)
            .mensaje,
        msg,
      );
      expect(
        (traducirErrorInsumos('unavailable', null) as ListaRechazada).mensaje,
        MensajesInsumos.sinConexion,
      );
    });
  });

  group('pantalla Insumos (HU-004)', () {
    testWidgets('CA1, CA4, CA6: lista todos los insumos en dos secciones', (
      tester,
    ) async {
      await abrirInsumos(tester);

      expect(find.text('Insumos críticos (1)'), findsOneWidget);
      expect(find.text('Otros insumos (3)'), findsOneWidget);
      expect(_en('criticos', 'Tomate'), findsOneWidget);
      expect(_en('criticos', 'Crítico'), findsOneWidget);
      for (final nombre in ['Arroz', 'Cebolla', 'Pollo']) {
        expect(_en('otros', nombre), findsOneWidget, reason: nombre);
      }
      expect(_en('otros', 'No crítico'), findsNWidgets(3));
      // El inactivo también aparece, con su etiqueta.
      expect(_en('otros', 'Inactivo'), findsOneWidget);
    });

    testWidgets('sin cambios, "Guardar cambios" está deshabilitado', (
      tester,
    ) async {
      await abrirInsumos(tester);

      expect(tester.widget<FilledButton>(_guardar).onPressed, isNull);
    });

    testWidgets(
      'CA2, CA3: al marcar y desmarcar, el insumo cambia de sección',
      (tester) async {
        await abrirInsumos(tester);

        await tester.tap(_interruptor('pollo'));
        await tester.pump();
        await tester.tap(_interruptor('tomate'));
        await tester.pump();

        expect(_en('criticos', 'Pollo'), findsOneWidget);
        expect(_en('otros', 'Tomate'), findsOneWidget);
        expect(find.text('Insumos críticos (1)'), findsOneWidget);
        expect(insumos.guardados, isEmpty, reason: 'aún no se guarda');
      },
    );

    testWidgets('CA5, CA7: "Guardar cambios" guarda la lista y lo confirma', (
      tester,
    ) async {
      await abrirInsumos(tester);
      await tester.tap(_interruptor('pollo'));
      await tester.tap(_interruptor('cebolla'));
      await tester.pump();

      await tester.tap(_guardar);
      await tester.pumpAndSettle();

      expect(insumos.guardados.single, {'tomate', 'pollo', 'cebolla'});
      expect(insumos.criticos, {'tomate', 'pollo', 'cebolla'});
      expect(find.text(MensajesInsumos.guardado), findsOneWidget);
      expect(find.text('Insumos críticos (3)'), findsOneWidget);
      expect(tester.widget<FilledButton>(_guardar).onPressed, isNull);
    });

    testWidgets('volver al estado guardado deshabilita "Guardar cambios"', (
      tester,
    ) async {
      await abrirInsumos(tester);
      await tester.tap(_interruptor('arroz'));
      await tester.pump();
      expect(tester.widget<FilledButton>(_guardar).onPressed, isNotNull);

      await tester.tap(_interruptor('arroz'));
      await tester.pump();
      expect(tester.widget<FilledButton>(_guardar).onPressed, isNull);
    });

    testWidgets('un error del servidor se muestra y conserva la selección', (
      tester,
    ) async {
      insumos.respuesta = const ListaRechazada(MensajesInsumos.sinConexion);
      await abrirInsumos(tester);
      await tester.tap(_interruptor('arroz'));
      await tester.pump();

      await tester.tap(_guardar);
      await tester.pumpAndSettle();

      expect(find.text(MensajesInsumos.sinConexion), findsOneWidget);
      expect(_en('criticos', 'Arroz'), findsOneWidget);
      expect(find.text(MensajesInsumos.guardado), findsNothing);
    });

    testWidgets('mientras guarda, se bloquean el botón y los interruptores', (
      tester,
    ) async {
      final pausa = Completer<void>();
      final lento = _InsumosLentos(pausa.future);
      await abrirApp(
        tester,
        sesion: SesionFalsa(guardada: perfilDePrueba()),
        insumos: lento,
        tamano: const Size(1080, 3000),
      );
      await tester.tap(find.text('Insumos'));
      await tester.pumpAndSettle();
      await tester.tap(_interruptor('arroz'));
      await tester.pump();

      await tester.tap(_guardar);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<Switch>(_interruptor('pollo')).onChanged, isNull);
      pausa.complete();
      await tester.pumpAndSettle();
      expect(find.text(MensajesInsumos.guardado), findsOneWidget);
    });

    testWidgets('salir con cambios sin guardar pide confirmación', (
      tester,
    ) async {
      await abrirInsumos(tester);
      await tester.tap(_interruptor('arroz'));
      await tester.pump();

      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.text(MensajesInsumos.cambiosSinGuardar), findsOneWidget);

      await tester.tap(find.text('Seguir editando'));
      await tester.pumpAndSettle();
      expect(find.text('Insumos críticos (2)'), findsOneWidget);

      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir sin guardar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Hola Camila,\n¿Qué quieres hacer hoy?'),
        findsOneWidget,
      );
      expect(insumos.guardados, isEmpty);
    });

    testWidgets('si el servidor dice que ya no es administrador, lo explica', (
      tester,
    ) async {
      insumos.respuesta = const ListaSinPermiso();
      await abrirInsumos(tester);
      await tester.tap(_interruptor('arroz'));
      await tester.pump();

      await tester.tap(_guardar);
      await tester.pumpAndSettle();

      expect(find.text(MensajesUsuarios.sinPermisoTitulo), findsOneWidget);
    });
  });

  group('solo el administrador', () {
    final daniela = perfilDePrueba(nombres: 'Daniela', rol: Rol.auxiliarCocina);

    testWidgets('el auxiliar no ve "Insumos"', (tester) async {
      await abrirApp(tester, sesion: SesionFalsa(guardada: daniela));
      expect(find.text('Insumos'), findsNothing);
    });

    testWidgets('el auxiliar que llega a la ruta ve "No tienes permisos"', (
      tester,
    ) async {
      await abrirApp(tester, sesion: SesionFalsa(guardada: daniela));

      GoRouter.of(
        tester.element(find.byType(InicioPantalla)),
      ).go(Rutas.insumos);
      await tester.pumpAndSettle();

      expect(find.text(MensajesUsuarios.sinPermisoTitulo), findsOneWidget);
      expect(find.text('Guardar cambios'), findsNothing);
    });
  });
}

/// Repositorio que tarda en guardar, para ver el estado "guardando".
class _InsumosLentos extends InsumosFalsos {
  _InsumosLentos(this._espera);

  final Future<void> _espera;

  @override
  Future<ResultadoGuardado> guardarCriticos(Set<String> criticos) async {
    await _espera;
    return super.guardarCriticos(criticos);
  }
}
