import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/features/auth/domain/mensajes_validacion.dart';
import 'package:stockchef/features/auth/domain/validaciones.dart';

void main() {
  group('Campo obligatorio (CA2, CA3)', () {
    test('rechaza vacío, nulo y solo espacios', () {
      for (final valor in [null, '', '   ', '\t\n']) {
        expect(
          Validaciones.obligatorio(valor),
          MensajesValidacion.campoObligatorio,
          reason: 'valor: "$valor"',
        );
      }
    });

    test('acepta texto con contenido', () {
      expect(Validaciones.obligatorio('Camila'), isNull);
      expect(Validaciones.obligatorio('  Ruiz  '), isNull);
    });
  });

  group('Formato de correo (CA4)', () {
    test('vacío pide el campo obligatorio, no el formato', () {
      expect(Validaciones.correo(''), MensajesValidacion.campoObligatorio);
      expect(Validaciones.correo('  '), MensajesValidacion.campoObligatorio);
    });

    test('acepta correos válidos', () {
      for (final correo in [
        'camila@correo.com',
        'Camila.Ruiz@Correo.com',
        'camila+stock@correo.com.co',
        'c_ruiz-1@mi-restaurante.co',
        '  camila@correo.com  ',
      ]) {
        expect(Validaciones.correo(correo), isNull, reason: correo);
      }
    });

    test('rechaza correos con formato no válido', () {
      for (final correo in [
        'camila',
        'camila@',
        '@correo.com',
        'camila@correo',
        'camila@correo.c',
        'camila@@correo.com',
        'cami la@correo.com',
        '.camila@correo.com',
        'camila.@correo.com',
        'cami..la@correo.com',
        'camila@-correo.com',
        'camila@correo..com',
      ]) {
        expect(
          Validaciones.correo(correo),
          MensajesValidacion.correoInvalido,
          reason: correo,
        );
      }
    });
  });

  group('Contraseña segura (CA6)', () {
    test('vacía pide el campo obligatorio', () {
      expect(Validaciones.contrasena(''), MensajesValidacion.campoObligatorio);
      expect(
        Validaciones.contrasena(null),
        MensajesValidacion.campoObligatorio,
      );
    });

    test('acepta 8 caracteres o más con mayúscula, minúscula y número', () {
      for (final clave in [
        'Cocina12',
        'SaborCasero2026',
        'Ñandú2024',
        'A1b2c3d4',
      ]) {
        expect(Validaciones.contrasena(clave), isNull, reason: clave);
      }
    });

    test('rechaza la que no cumple alguna de las reglas', () {
      final casos = {
        'Cocina1': 'solo 7 caracteres',
        'cocina123': 'sin mayúscula',
        'COCINA123': 'sin minúscula',
        'CocinaRica': 'sin número',
        '12345678': 'solo números',
      };
      casos.forEach((clave, motivo) {
        expect(
          Validaciones.contrasena(clave),
          MensajesValidacion.contrasenaDebil,
          reason: motivo,
        );
      });
    });
  });

  group('Confirmación de contraseña (CA7)', () {
    test('vacía pide el campo obligatorio', () {
      expect(
        Validaciones.confirmacion('Cocina12', ''),
        MensajesValidacion.campoObligatorio,
      );
    });

    test('acepta cuando coincide exactamente', () {
      expect(Validaciones.confirmacion('Cocina12', 'Cocina12'), isNull);
    });

    test('rechaza cuando no coincide, incluso por mayúsculas o espacios', () {
      for (final confirmacion in ['Cocina13', 'cocina12', 'Cocina12 ']) {
        expect(
          Validaciones.confirmacion('Cocina12', confirmacion),
          MensajesValidacion.contrasenasNoCoinciden,
          reason: '"$confirmacion"',
        );
      }
    });
  });
}
