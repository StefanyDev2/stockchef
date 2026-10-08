import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/features/auth/domain/datos_registro.dart';
import 'package:stockchef/features/auth/domain/mensajes_validacion.dart';

void main() {
  const validos = DatosRegistro(
    nombres: 'Camila',
    apellidos: 'Ruiz',
    correo: 'Camila@Correo.com',
    restaurante: '  Sabor   Casero ',
    contrasena: 'Cocina12',
    confirmacion: 'Cocina12',
  );

  test('CA1: el formulario tiene los 6 campos en el orden del prototipo', () {
    expect(CampoRegistro.values.map((c) => c.etiqueta), [
      'Nombres',
      'Apellidos',
      'Correo electrónico',
      'Nombre del restaurante',
      'Contraseña',
      'Confirmar contraseña',
    ]);
  });

  test('con todos los datos válidos no hay errores ni aviso', () {
    final resultado = validos.validar();

    expect(resultado.esValido, isTrue);
    expect(resultado.aviso, isNull);
  });

  test(
    'CA2, CA3: formulario vacío marca los 6 campos y muestra el aviso E1',
    () {
      final resultado = const DatosRegistro().validar();

      expect(resultado.errores.keys, CampoRegistro.values);
      expect(
        resultado.errores.values,
        everyElement(MensajesValidacion.campoObligatorio),
      );
      expect(resultado.aviso, MensajesValidacion.completaCampos);
    },
  );

  test('CA3: indica solo los campos que faltan', () {
    const datos = DatosRegistro(
      nombres: 'Camila',
      correo: 'camila@correo.com',
      contrasena: 'Cocina12',
      confirmacion: 'Cocina12',
    );

    expect(datos.validar().errores.keys, [
      CampoRegistro.apellidos,
      CampoRegistro.restaurante,
    ]);
  });

  test('CA4 a CA8: datos no válidos muestran su error y el aviso E2', () {
    const datos = DatosRegistro(
      nombres: 'Camila',
      apellidos: 'Ruiz',
      correo: 'camila@correo',
      restaurante: 'Sabor Casero',
      contrasena: 'cocina',
      confirmacion: 'cocin',
    );

    final resultado = datos.validar();

    expect(resultado.errores, {
      CampoRegistro.correo: MensajesValidacion.correoInvalido,
      CampoRegistro.contrasena: MensajesValidacion.contrasenaDebil,
      CampoRegistro.confirmacion: MensajesValidacion.contrasenasNoCoinciden,
    });
    expect(resultado.errorDe(CampoRegistro.nombres), isNull);
    expect(resultado.aviso, MensajesValidacion.corrigeCampos);
  });

  test('si falta un campo y otro no es válido, prima el aviso E1', () {
    const datos = DatosRegistro(
      nombres: 'Camila',
      apellidos: 'Ruiz',
      correo: 'camila@correo',
      restaurante: 'Sabor Casero',
      contrasena: 'Cocina12',
    );

    expect(datos.validar().aviso, MensajesValidacion.completaCampos);
  });

  test(
    'aEnvio limpia textos y normaliza el correo, sin tocar la contraseña',
    () {
      const conEspacios = DatosRegistro(
        nombres: '  Camila  ',
        apellidos: 'Ruiz   Gómez',
        correo: ' Camila@Correo.com ',
        restaurante: '  Sabor   Casero ',
        contrasena: ' Cocina12 ',
        confirmacion: ' Cocina12 ',
      );

      expect(conEspacios.aEnvio(), {
        'nombres': 'Camila',
        'apellidos': 'Ruiz Gómez',
        'correo': 'camila@correo.com',
        'restaurante': 'Sabor Casero',
        'contrasena': ' Cocina12 ',
      });
    },
  );
}
