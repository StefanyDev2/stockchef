import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/features/auth/domain/perfil_usuario.dart';

import '../../ayudantes.dart';

const _funcionesAdministrador = [
  'Compras',
  'Insumos',
  'Menú',
  'Reportes',
  'Usuarios',
];
const _funcionesAuxiliar = [
  'Consumo del día',
  'Pérdidas',
  'Platos vendidos',
  'Menú del día',
];

Finder get _botonIngresar =>
    find.widgetWithText(FilledButton, 'INICIAR SESIÓN');

void main() {
  testWidgets('CA6 (3A): el administrador ve sus 5 funciones', (tester) async {
    await abrirApp(tester, sesion: SesionFalsa(guardada: perfilDePrueba()));

    expect(find.text('Camila'), findsOneWidget);
    expect(find.text('Hola Camila,\n¿Qué quieres hacer hoy?'), findsOneWidget);
    for (final funcion in _funcionesAdministrador) {
      expect(find.text(funcion), findsOneWidget, reason: funcion);
    }
    for (final funcion in _funcionesAuxiliar) {
      expect(find.text(funcion), findsNothing, reason: funcion);
    }
  });

  testWidgets('CA6 (3B): el auxiliar de cocina ve sus 4 funciones', (
    tester,
  ) async {
    await abrirApp(
      tester,
      sesion: SesionFalsa(
        guardada: perfilDePrueba(nombres: 'Daniela', rol: Rol.auxiliarCocina),
      ),
    );

    expect(find.text('Hola Daniela,\n¿Qué quieres hacer hoy?'), findsOneWidget);
    for (final funcion in _funcionesAuxiliar) {
      expect(find.text(funcion), findsOneWidget, reason: funcion);
    }
    for (final funcion in _funcionesAdministrador) {
      expect(find.text(funcion), findsNothing, reason: funcion);
    }
  });

  testWidgets('CA7 (3C): sin rol ve el aviso y ninguna función', (
    tester,
  ) async {
    final sesion = SesionFalsa(
      guardada: perfilDePrueba(nombres: 'Andrés', rol: Rol.sinRol),
    );
    await abrirApp(tester, sesion: sesion);

    expect(
      find.text('Tu cuenta está pendiente de asignación de rol'),
      findsOneWidget,
    );
    for (final funcion in [..._funcionesAdministrador, ..._funcionesAuxiliar]) {
      expect(find.text(funcion), findsNothing, reason: funcion);
    }
    expect(find.byTooltip('Mi cuenta'), findsNothing);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(sesion.sesionesCerradas, 1);
    expect(_botonIngresar, findsOneWidget);
  });

  testWidgets('las funciones aún no están construidas: avisa "próximamente"', (
    tester,
  ) async {
    await abrirApp(tester, sesion: SesionFalsa(guardada: perfilDePrueba()));

    await tester.tap(find.text('Compras'));
    await tester.pump();

    expect(find.text('Compras: próximamente'), findsOneWidget);
  });

  testWidgets(
    'CA13: abre directo en la pantalla del rol si la sesión quedó abierta',
    (tester) async {
      await abrirApp(tester, sesion: SesionFalsa(guardada: perfilDePrueba()));

      expect(_botonIngresar, findsNothing);
      expect(find.text('Compras'), findsOneWidget);
    },
  );

  testWidgets(
    'CA13: el menú ☰ muestra la cuenta y "Cerrar sesión" la termina',
    (tester) async {
      final sesion = SesionFalsa(guardada: perfilDePrueba());
      await abrirApp(tester, sesion: sesion);

      await tester.tap(find.byTooltip('Mi cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Mi cuenta'), findsOneWidget);
      expect(find.text('Camila Ruiz'), findsOneWidget);
      expect(find.text('Administrador'), findsOneWidget);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(sesion.sesionesCerradas, 1);
      expect(_botonIngresar, findsOneWidget);
    },
  );

  testWidgets('la flecha de Mi cuenta vuelve a la pantalla principal', (
    tester,
  ) async {
    await abrirApp(tester, sesion: SesionFalsa(guardada: perfilDePrueba()));
    await tester.tap(find.byTooltip('Mi cuenta'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(find.text('Compras'), findsOneWidget);
  });
}
