import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stockchef/core/router/app_router.dart';
import 'package:stockchef/features/auth/domain/perfil_usuario.dart';
import 'package:stockchef/features/inicio/presentation/inicio_pantalla.dart';
import 'package:stockchef/features/usuarios/data/usuarios_repositorio_firebase.dart';
import 'package:stockchef/features/usuarios/domain/usuarios.dart';

import '../../ayudantes.dart';

final _camila = perfilDePrueba(uid: 'camila');
final _daniela = perfilDePrueba(
  uid: 'daniela',
  nombres: 'Daniela',
  apellidos: 'Vargas',
  rol: Rol.auxiliarCocina,
);
final _andres = perfilDePrueba(
  uid: 'andres',
  nombres: 'Andrés',
  apellidos: 'Mora',
  rol: Rol.sinRol,
);
final _laura = perfilDePrueba(
  uid: 'laura',
  nombres: 'Laura',
  apellidos: 'Pérez',
  rol: Rol.auxiliarCocina,
  activo: false,
);

Finder get _guardar => find.widgetWithText(FilledButton, 'Guardar cambios');

void main() {
  late UsuariosFalsos usuarios;

  setUp(() => usuarios = UsuariosFalsos([_camila, _daniela, _andres, _laura]));

  /// Entra como Camila (administradora) y abre "Usuarios".
  Future<void> abrirUsuarios(WidgetTester tester) async {
    await abrirApp(
      tester,
      sesion: SesionFalsa(guardada: _camila),
      usuarios: usuarios,
    );
    await tester.tap(find.text('Usuarios'));
    await tester.pumpAndSettle();
  }

  Future<void> abrirDetalle(WidgetTester tester, String nombre) async {
    await abrirUsuarios(tester);
    await tester.tap(find.text(nombre));
    await tester.pumpAndSettle();
  }

  group('lista de usuarios', () {
    testWidgets(
      'CA1, CA2: muestra nombres, apellidos, correo y rol de cada uno',
      (tester) async {
        await abrirUsuarios(tester);

        for (final u in [_camila, _daniela, _andres, _laura]) {
          expect(find.text(u.nombreCompleto), findsOneWidget);
          expect(find.text(u.correo), findsOneWidget);
        }
        expect(find.text('Administrador'), findsOneWidget);
        expect(find.text('Auxiliar de cocina'), findsOneWidget);
        expect(find.text('Sin rol'), findsOneWidget);
        expect(find.text('Desactivado'), findsOneWidget);
      },
    );
  });

  group('asignar rol', () {
    testWidgets('el detalle muestra el usuario, su rol y las dos opciones', (
      tester,
    ) async {
      await abrirDetalle(tester, 'Andrés Mora');

      expect(find.text('Detalle de usuario'), findsOneWidget);
      expect(find.text('andrés@correo.com'), findsOneWidget);
      expect(find.text('Rol actual: Sin rol'), findsOneWidget);
      expect(find.text('Administrador'), findsOneWidget);
      expect(find.text('Auxiliar de cocina'), findsOneWidget);
      expect(find.text('Sin rol'), findsNothing, reason: 'no es una opción');
      expect(tester.widget<FilledButton>(_guardar).onPressed, isNull);
    });

    testWidgets('CA3, CA6: elige un rol, guarda y la lista lo confirma', (
      tester,
    ) async {
      await abrirDetalle(tester, 'Andrés Mora');

      await tester.tap(find.text('Auxiliar de cocina'));
      await tester.pump();
      await tester.tap(_guardar);
      await tester.pumpAndSettle();

      expect(usuarios.llamadas, ['asignarRol andres auxiliarCocina']);
      expect(find.text('Usuarios'), findsOneWidget);
      expect(find.text(MensajesUsuarios.rolActualizado), findsOneWidget);
      expect(find.text('Sin rol'), findsNothing);
      expect(find.text('Auxiliar de cocina'), findsNWidgets(2));
    });

    testWidgets('elegir el mismo rol que ya tiene no habilita Guardar', (
      tester,
    ) async {
      await abrirDetalle(tester, 'Daniela Vargas');

      await tester.tap(find.text('Auxiliar de cocina').last);
      await tester.pump();

      expect(tester.widget<FilledButton>(_guardar).onPressed, isNull);
    });

    testWidgets(
      'CA5 (E1): el servidor rechaza quitar al último administrador',
      (tester) async {
        usuarios.respuesta = const CambioRechazado(
          MensajesUsuarios.ultimoAdministrador,
        );
        await abrirDetalle(tester, 'Camila Ruiz');

        await tester.tap(find.text('Auxiliar de cocina'));
        await tester.pump();
        await tester.tap(_guardar);
        await tester.pumpAndSettle();

        expect(find.text(MensajesUsuarios.ultimoAdministrador), findsOneWidget);
        expect(find.text('Detalle de usuario'), findsOneWidget);
        expect(usuarios.usuario('camila').rol, Rol.administrador);
      },
    );

    testWidgets(
      'CA9: si el servidor dice que ya no es administrador, lo explica',
      (tester) async {
        usuarios.respuesta = const CambioSinPermiso();
        await abrirDetalle(tester, 'Andrés Mora');

        await tester.tap(find.text('Administrador'));
        await tester.pump();
        await tester.tap(_guardar);
        await tester.pumpAndSettle();

        expect(find.text(MensajesUsuarios.sinPermisoTitulo), findsOneWidget);
      },
    );
  });

  group('desactivar y reactivar', () {
    testWidgets('CA4 (D1): pide confirmación y desactiva', (tester) async {
      await abrirDetalle(tester, 'Daniela Vargas');

      await tester.tap(find.text('Desactivar usuario'));
      await tester.pumpAndSettle();
      expect(find.text('¿Desactivar a Daniela Vargas?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Desactivar'));
      await tester.pumpAndSettle();

      expect(usuarios.llamadas, ['cambiarEstado daniela false']);
      expect(find.text(MensajesUsuarios.usuarioDesactivado), findsOneWidget);
      expect(find.text('Desactivado'), findsNWidgets(2));
    });

    testWidgets('al cancelar la confirmación no cambia nada', (tester) async {
      await abrirDetalle(tester, 'Daniela Vargas');

      await tester.tap(find.text('Desactivar usuario'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(usuarios.llamadas, isEmpty);
      expect(find.text('Detalle de usuario'), findsOneWidget);
    });

    testWidgets('un usuario desactivado se puede reactivar', (tester) async {
      await abrirDetalle(tester, 'Laura Pérez');

      await tester.tap(find.text('Reactivar usuario'));
      await tester.pumpAndSettle();

      expect(usuarios.llamadas, ['cambiarEstado laura true']);
      expect(find.text(MensajesUsuarios.usuarioReactivado), findsOneWidget);
      expect(find.text('Desactivado'), findsNothing);
    });
  });

  group('CA8, CA9: solo el administrador', () {
    testWidgets('el auxiliar no ve la opción "Usuarios"', (tester) async {
      await abrirApp(tester, sesion: SesionFalsa(guardada: _daniela));

      expect(find.text('Usuarios'), findsNothing);
    });

    for (final ruta in [Rutas.usuarios, Rutas.detalleUsuario('camila')]) {
      testWidgets('el auxiliar que llega a $ruta ve "No tienes permisos"', (
        tester,
      ) async {
        await abrirApp(
          tester,
          sesion: SesionFalsa(guardada: _daniela),
          usuarios: usuarios,
        );

        GoRouter.of(tester.element(find.byType(InicioPantalla))).go(ruta);
        await tester.pumpAndSettle();

        expect(find.text(MensajesUsuarios.sinPermisoTitulo), findsOneWidget);
        expect(find.text(MensajesUsuarios.sinPermisoDetalle), findsOneWidget);
        expect(find.text('Camila Ruiz'), findsNothing);

        await tester.tap(find.text('Volver'));
        await tester.pumpAndSettle();
        expect(
          find.text('Hola Daniela,\n¿Qué quieres hacer hoy?'),
          findsOneWidget,
        );
      });
    }
  });

  group('traducción de errores del servidor', () {
    test('permiso denegado o sin sesión es "sin permiso"', () {
      expect(
        traducirErrorCambio('permission-denied', 'x'),
        isA<CambioSinPermiso>(),
      );
      expect(
        traducirErrorCambio('unauthenticated', null),
        isA<CambioSinPermiso>(),
      );
    });

    test('CA5: el mensaje del servidor se muestra tal cual', () {
      final r = traducirErrorCambio(
        'failed-precondition',
        MensajesUsuarios.ultimoAdministrador,
      );
      expect(
        (r as CambioRechazado).mensaje,
        MensajesUsuarios.ultimoAdministrador,
      );
    });

    test('sin conexión y errores inesperados', () {
      expect(
        (traducirErrorCambio('unavailable', null) as CambioRechazado).mensaje,
        MensajesUsuarios.sinConexion,
      );
      expect(
        (traducirErrorCambio('internal', 'detalle técnico') as CambioRechazado)
            .mensaje,
        MensajesUsuarios.errorInterno,
      );
    });

    test('solo se envían los roles asignables', () {
      expect(rolAFirestore(Rol.administrador), 'administrador');
      expect(rolAFirestore(Rol.auxiliarCocina), 'auxiliar_cocina');
      expect(() => rolAFirestore(Rol.sinRol), throwsArgumentError);
    });
  });
}
