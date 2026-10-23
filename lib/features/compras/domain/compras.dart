import 'unidades.dart';

/// Mensajes de HU-006. Los de validación son los de los criterios y los
/// mismos que envía el servidor (functions/src/compras.ts).
abstract final class MensajesCompras {
  static const camposPendientes =
      'Debe completar todos los campos para guardar la compra';
  static const valoresInvalidos =
      'Ingrese valores válidos para la cantidad y el precio';
  static const campoObligatorio = 'Campo obligatorio';
  static const mayorACero = 'Debe ser un número mayor a cero';
  static const compraGuardada = 'Compra guardada correctamente';
  static const sinInsumos =
      'No hay insumos activos. Primero hay que crear los insumos.';
  static const sinConexion =
      'No hay conexión. Revisa tu internet e intenta de nuevo.';
  static const errorInterno = 'No se pudo guardar la compra. Intenta de nuevo.';
  static const errorLista = 'No se pudo cargar la información.';
}

enum TipoCompra {
  planeada('Planeada'),
  emergencia('Emergencia');

  const TipoCompra(this.etiqueta);

  final String etiqueta;

  static TipoCompra desdeValor(Object? valor) =>
      valor == 'emergencia' ? emergencia : planeada;
}

/// Insumo del restaurante (colección `restaurants/{id}/insumos`).
class Insumo {
  const Insumo({
    required this.id,
    required this.nombre,
    required this.unidad,
    required this.cantidadDisponible,
  });

  factory Insumo.desdeFirestore(String id, Map<String, Object?> datos) =>
      Insumo(
        id: id,
        nombre: datos['nombre'] is String ? datos['nombre']! as String : id,
        unidad: UnidadMedida.desdeValor(datos['unidad']) ?? UnidadMedida.unidad,
        cantidadDisponible: (datos['cantidadDisponible'] as num?) ?? 0,
      );

  final String id;
  final String nombre;
  final UnidadMedida unidad;
  final num cantidadDisponible;
}

/// Campos obligatorios del formulario (CA2).
enum CampoCompra { insumo, cantidad, unidad, precio, tipo }

/// Lo que se escribió en el formulario de compra.
class DatosCompra {
  const DatosCompra({
    this.insumoId,
    this.cantidad = '',
    this.unidad,
    this.proveedor = '',
    this.precio = '',
    this.tipo,
  });

  final String? insumoId;
  final String cantidad;
  final UnidadMedida? unidad;
  final String proveedor;
  final String precio;

  /// HU-007, CA3: obligatorio; no viene marcado.
  final TipoCompra? tipo;

  /// CA5 y CA6: primero los campos pendientes; si no falta ninguno, que
  /// cantidad y precio sean números mayores a cero.
  ValidacionCompra validar() {
    final errores = <CampoCompra, String>{
      if (insumoId == null)
        CampoCompra.insumo: MensajesCompras.campoObligatorio,
      if (cantidad.trim().isEmpty)
        CampoCompra.cantidad: MensajesCompras.campoObligatorio,
      if (unidad == null) CampoCompra.unidad: MensajesCompras.campoObligatorio,
      if (precio.trim().isEmpty)
        CampoCompra.precio: MensajesCompras.campoObligatorio,
      if (tipo == null) CampoCompra.tipo: MensajesCompras.campoObligatorio,
    };
    if (errores.isNotEmpty) {
      return ValidacionCompra(errores, MensajesCompras.camposPendientes);
    }

    final invalidos = <CampoCompra, String>{
      if (!_positivo(leerCantidad(cantidad)))
        CampoCompra.cantidad: MensajesCompras.mayorACero,
      if (!_positivo(leerPrecio(precio)))
        CampoCompra.precio: MensajesCompras.mayorACero,
    };
    if (invalidos.isNotEmpty) {
      return ValidacionCompra(invalidos, MensajesCompras.valoresInvalidos);
    }
    return const ValidacionCompra({}, null);
  }

  /// Datos para la función `registrarCompra`. Solo se llama si son válidos.
  Map<String, Object?> aEnvio() => {
    'insumoId': insumoId,
    'cantidad': leerCantidad(cantidad),
    'unidad': unidad!.valor,
    'proveedor': proveedor.trim().isEmpty ? null : proveedor.trim(),
    'precioTotal': leerPrecio(precio),
    'tipo': tipo!.name,
  };
}

class ValidacionCompra {
  const ValidacionCompra(this.errores, this.aviso);

  final Map<CampoCompra, String> errores;

  /// Mensaje de arriba del formulario (CA5 o CA6).
  final String? aviso;

  bool get esValida => errores.isEmpty;
}

bool _positivo(double? valor) => valor != null && valor.isFinite && valor > 0;

/// Cantidad escrita con coma o punto decimal: "1,5" o "1.5".
double? leerCantidad(String texto) =>
    double.tryParse(texto.trim().replaceAll(' ', '').replaceAll(',', '.'));

/// Precio en pesos como se escribe en Colombia: "$50.000" o "50000". Los
/// puntos son de miles y la coma, si la hay, es decimal.
double? leerPrecio(String texto) {
  final limpio = texto
      .trim()
      .replaceAll(RegExp(r'[\s$]'), '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  return double.tryParse(limpio);
}

/// Compra guardada (colección `restaurants/{id}/compras`).
class Compra {
  const Compra({
    required this.id,
    required this.insumoNombre,
    required this.tipo,
    required this.cantidad,
    required this.unidad,
    required this.proveedor,
    required this.precioTotal,
    required this.precioUnitario,
    required this.cantidadDisponibleDespues,
    required this.unidadInsumo,
    this.fecha,
  });

  factory Compra.desdeMapa(String id, Map<Object?, Object?> datos) {
    num numero(String campo) => (datos[campo] as num?) ?? 0;
    final fecha = datos['fecha'];
    return Compra(
      id: id,
      insumoNombre: datos['insumoNombre'] as String? ?? '',
      tipo: TipoCompra.desdeValor(datos['tipo']),
      cantidad: numero('cantidad'),
      unidad: UnidadMedida.desdeValor(datos['unidad']) ?? UnidadMedida.unidad,
      proveedor: datos['proveedor'] as String?,
      precioTotal: numero('precioTotal'),
      precioUnitario: numero('precioUnitario'),
      cantidadDisponibleDespues: numero(
        datos.containsKey('cantidadDisponible')
            ? 'cantidadDisponible'
            : 'cantidadDisponibleDespues',
      ),
      unidadInsumo:
          UnidadMedida.desdeValor(datos['unidadInsumo']) ?? UnidadMedida.unidad,
      fecha: fecha is DateTime ? fecha : null,
    );
  }

  final String id;
  final String insumoNombre;
  final TipoCompra tipo;
  final num cantidad;
  final UnidadMedida unidad;
  final String? proveedor;
  final num precioTotal;
  final num precioUnitario;
  final num cantidadDisponibleDespues;
  final UnidadMedida unidadInsumo;
  final DateTime? fecha;
}

/// Insumos y compras del restaurante. La implementación real lee Firestore
/// y guarda con la Cloud Function `registrarCompra`.
abstract interface class ComprasRepositorio {
  /// CA3: insumos activos, ordenados por nombre.
  Stream<List<Insumo>> insumosActivos(String restaurantId);

  /// Compras más recientes primero.
  Stream<List<Compra>> compras(String restaurantId);

  Future<ResultadoCompra> registrar(DatosCompra datos);
}

sealed class ResultadoCompra {
  const ResultadoCompra();
}

/// CA11: la compra quedó guardada.
final class CompraGuardada extends ResultadoCompra {
  const CompraGuardada(this.compra);

  final Compra compra;
}

final class CompraRechazada extends ResultadoCompra {
  const CompraRechazada(this.mensaje, {this.pendientes = const {}});

  final String mensaje;
  final Set<CampoCompra> pendientes;
}

/// Quien intentó guardar ya no tiene un rol que pueda registrar compras.
final class CompraSinPermiso extends ResultadoCompra {
  const CompraSinPermiso();
}

/// HU-007, CA6: compras de un tipo, o todas si `tipo` es `null`.
List<Compra> filtrarCompras(List<Compra> compras, TipoCompra? tipo) =>
    tipo == null ? compras : [...compras.where((c) => c.tipo == tipo)];

/// Cuántas compras y cuánto dinero hay de un tipo.
class ResumenTipo {
  const ResumenTipo({required this.cantidad, required this.total});

  final int cantidad;
  final num total;
}

/// HU-007, CA6: resumen de planeadas y de emergencia.
Map<TipoCompra, ResumenTipo> resumirPorTipo(List<Compra> compras) => {
  for (final tipo in TipoCompra.values)
    tipo: ResumenTipo(
      cantidad: compras.where((c) => c.tipo == tipo).length,
      total: compras
          .where((c) => c.tipo == tipo)
          .fold<num>(0, (suma, c) => suma + c.precioTotal),
    ),
};
