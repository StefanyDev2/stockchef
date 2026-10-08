import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/features/auth/data/registro_repositorio_firebase.dart';
import 'package:stockchef/features/auth/domain/datos_registro.dart';
import 'package:stockchef/features/auth/domain/mensajes_validacion.dart';
import 'package:stockchef/features/auth/domain/registro_repositorio.dart';

void main() {
  test('CA5: correo ya registrado queda como error del campo correo', () {
    final resultado = traducirErrorRegistro('already-exists', {
      'errores': {'correo': MensajesValidacion.correoRegistrado},
    });

    expect(resultado, isA<RegistroRechazado>());
    expect((resultado as RegistroRechazado).errores, {
      CampoRegistro.correo: MensajesValidacion.correoRegistrado,
    });
  });

  test(
    'datos no válidos se reparten por campo e ignora campos desconocidos',
    () {
      final resultado = traducirErrorRegistro('invalid-argument', {
        'errores': {
          'nombres': MensajesValidacion.campoObligatorio,
          'contrasena': MensajesValidacion.contrasenaDebil,
          'otroCampo': 'x',
          'apellidos': 3,
        },
      });

      expect((resultado as RegistroRechazado).errores, {
        CampoRegistro.nombres: MensajesValidacion.campoObligatorio,
        CampoRegistro.contrasena: MensajesValidacion.contrasenaDebil,
      });
    },
  );

  test('un rechazo sin errores por campo se muestra como error general', () {
    for (final detalles in [
      null,
      'texto',
      {},
      {'errores': 'x'},
    ]) {
      final resultado = traducirErrorRegistro('invalid-argument', detalles);
      expect(
        (resultado as RegistroFallido).mensaje,
        MensajesValidacion.errorInterno,
        reason: '$detalles',
      );
    }
  });

  test('sin conexión o tiempo agotado pide revisar internet', () {
    for (final codigo in ['unavailable', 'deadline-exceeded']) {
      final resultado = traducirErrorRegistro(codigo, null);
      expect(
        (resultado as RegistroFallido).mensaje,
        MensajesValidacion.sinConexion,
      );
    }
  });

  test('cualquier otro error es un error general', () {
    final resultado = traducirErrorRegistro('internal', null);
    expect(
      (resultado as RegistroFallido).mensaje,
      MensajesValidacion.errorInterno,
    );
  });
}
