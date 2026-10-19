import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/core/formato.dart';
import 'package:stockchef/features/compras/data/compras_repositorio_firebase.dart';
import 'package:stockchef/features/compras/domain/compras.dart';
import 'package:stockchef/features/compras/domain/unidades.dart';

void main() {
  const valida = DatosCompra(
    insumoId: 'tomate',
    cantidad: '10',
    unidad: UnidadMedida.kilogramo,
    proveedor: '  Distrialimentos ',
    precio: r'$50.000',
  );

  group('validar (CA2, CA5, CA6)', () {
    test('con todo diligenciado es válida', () {
      final v = valida.validar();
      expect(v.esValida, isTrue);
      expect(v.aviso, isNull);
    });

    test('CA2: el proveedor es opcional', () {
      const sinProveedor = DatosCompra(
        insumoId: 'tomate',
        cantidad: '10',
        unidad: UnidadMedida.kilogramo,
        precio: '50000',
      );
      expect(sinProveedor.validar().esValida, isTrue);
      expect(sinProveedor.aEnvio()['proveedor'], isNull);
    });

    test('CA5: marca cada campo obligatorio pendiente con el mensaje', () {
      final v = const DatosCompra(proveedor: 'X', cantidad: '  ').validar();

      expect(v.aviso, MensajesCompras.camposPendientes);
      expect(v.errores.keys, CampoCompra.values);
    });

    test('CA6: cantidad y precio deben ser números mayores a cero', () {
      for (final (cantidad, precio) in [
        ('0', '50000'),
        ('-2', '50000'),
        ('diez', '50000'),
        ('10', '0'),
        ('10', r'$'),
        ('10', 'gratis'),
      ]) {
        final v = DatosCompra(
          insumoId: 'tomate',
          cantidad: cantidad,
          unidad: UnidadMedida.kilogramo,
          precio: precio,
        ).validar();
        expect(
          v.aviso,
          MensajesCompras.valoresInvalidos,
          reason: '$cantidad / $precio',
        );
      }
    });

    test('si faltan campos, prima el aviso de campos pendientes', () {
      final v = const DatosCompra(cantidad: '0', precio: '-1').validar();
      expect(v.aviso, MensajesCompras.camposPendientes);
    });
  });

  group('lectura de números', () {
    test('la cantidad acepta coma o punto decimal', () {
      expect(leerCantidad('1,5'), 1.5);
      expect(leerCantidad('1.5'), 1.5);
      expect(leerCantidad(' 10 '), 10);
      expect(leerCantidad('abc'), isNull);
    });

    test('el precio acepta el formato colombiano', () {
      expect(leerPrecio(r'$50.000'), 50000);
      expect(leerPrecio('50000'), 50000);
      expect(leerPrecio(r'$ 1.250.500'), 1250500);
      expect(leerPrecio('3.500,50'), 3500.5);
    });

    test('se envía todo listo para la función', () {
      expect(valida.aEnvio(), {
        'insumoId': 'tomate',
        'cantidad': 10.0,
        'unidad': 'kilogramo',
        'proveedor': 'Distrialimentos',
        'precioTotal': 50000.0,
        'tipo': 'planeada',
      });
    });
  });

  test('CA4: las seis unidades de la lista y cuáles se pueden convertir', () {
    expect(UnidadMedida.values.map((u) => u.etiqueta), [
      'Kilogramo',
      'Gramo',
      'Libra',
      'Litro',
      'Mililitro',
      'Unidad',
    ]);
    expect(UnidadMedida.libra.esCompatibleCon(UnidadMedida.kilogramo), isTrue);
    expect(UnidadMedida.mililitro.esCompatibleCon(UnidadMedida.litro), isTrue);
    expect(UnidadMedida.litro.esCompatibleCon(UnidadMedida.kilogramo), isFalse);
  });

  test('formato colombiano de pesos y cantidades', () {
    expect(Formato.pesos(50000), r'$50.000');
    expect(Formato.pesos(1250500), r'$1.250.500');
    expect(Formato.numero(6.4072), '6,41');
    expect(Formato.numero(10), '10');
  });

  group('errores del servidor', () {
    test('CA5: marca los campos pendientes que dice el servidor', () {
      final r = traducirErrorCompra(
        'invalid-argument',
        MensajesCompras.camposPendientes,
        {
          'pendientes': ['insumo', 'precio', 'otro'],
        },
      );
      expect((r as CompraRechazada).mensaje, MensajesCompras.camposPendientes);
      expect(r.pendientes, {CampoCompra.insumo, CampoCompra.precio});
    });

    test('unidad incompatible e insumo no disponible se muestran tal cual', () {
      const mensaje =
          'Esa unidad no sirve para este insumo, que se mide en litro.';
      final r = traducirErrorCompra('failed-precondition', mensaje, null);
      expect((r as CompraRechazada).mensaje, mensaje);
    });

    test('CA12: permiso denegado es "sin permiso"', () {
      expect(
        traducirErrorCompra('permission-denied', null, null),
        isA<CompraSinPermiso>(),
      );
    });

    test('sin conexión y errores inesperados', () {
      expect(
        (traducirErrorCompra('unavailable', null, null) as CompraRechazada)
            .mensaje,
        MensajesCompras.sinConexion,
      );
      expect(
        (traducirErrorCompra('internal', 'x', null) as CompraRechazada).mensaje,
        MensajesCompras.errorInterno,
      );
    });
  });
}
