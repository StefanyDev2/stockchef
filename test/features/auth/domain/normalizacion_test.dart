import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/features/auth/domain/normalizacion.dart';

void main() {
  group('normalizarNombreRestaurante (unirse por nombre, CA10)', () {
    test(
      'mismo restaurante escrito de distintas formas da el mismo nombre',
      () {
        const variantes = [
          'Sabor Casero',
          'sabor casero',
          '  SABOR   CASERO  ',
          'Sábor Caséro',
          'sabor\tcasero',
        ];
        for (final variante in variantes) {
          expect(
            normalizarNombreRestaurante(variante),
            'sabor casero',
            reason: '"$variante"',
          );
        }
      },
    );

    test('quita tildes y diéresis de todas las vocales', () {
      expect(normalizarNombreRestaurante('ÁÉÍÓÚ áéíóú Ü'), 'aeiou aeiou u');
    });

    test('conserva la ñ', () {
      expect(normalizarNombreRestaurante('La Peña'), 'la peña');
      expect(
        normalizarNombreRestaurante('La Peña'),
        isNot(normalizarNombreRestaurante('La Pena')),
      );
    });
  });

  test('normalizarCorreo recorta y pasa a minúsculas', () {
    expect(
      normalizarCorreo('  Camila.Ruiz@Correo.COM '),
      'camila.ruiz@correo.com',
    );
  });

  test('limpiarTexto recorta y une espacios, sin cambiar mayúsculas', () {
    expect(limpiarTexto('  Sabor   Casero '), 'Sabor Casero');
  });
}
