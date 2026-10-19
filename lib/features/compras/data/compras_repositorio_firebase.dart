import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/compras.dart';

/// Insumos y compras desde Firestore (las reglas solo dejan leerlos al
/// administrador) y registro con la Cloud Function `registrarCompra`.
class ComprasRepositorioFirebase implements ComprasRepositorio {
  ComprasRepositorioFirebase(this._db, this._funciones);

  final FirebaseFirestore _db;
  final FirebaseFunctions _funciones;

  static const _tiempoMaximo = Duration(seconds: 15);

  /// Últimas compras que se muestran en el historial.
  static const _limiteHistorial = 30;

  @override
  Stream<List<Insumo>> insumosActivos(String restaurantId) => _db
      .collection('restaurants/$restaurantId/insumos')
      .where('activo', isEqualTo: true)
      .snapshots()
      .map(
        (consulta) =>
            consulta.docs
                .map((doc) => Insumo.desdeFirestore(doc.id, doc.data()))
                .toList()
              ..sort(
                (a, b) =>
                    a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
              ),
      );

  @override
  Stream<List<Compra>> compras(String restaurantId) => _db
      .collection('restaurants/$restaurantId/compras')
      .orderBy('fecha', descending: true)
      .limit(_limiteHistorial)
      .snapshots()
      .map(
        (consulta) => [
          for (final doc in consulta.docs)
            Compra.desdeMapa(doc.id, {
              ...doc.data(),
              'fecha': (doc.data()['fecha'] as Timestamp?)?.toDate(),
            }),
        ],
      );

  @override
  Future<ResultadoCompra> registrar(DatosCompra datos) async {
    try {
      final respuesta = await _funciones
          .httpsCallable(
            'registrarCompra',
            options: HttpsCallableOptions(timeout: _tiempoMaximo),
          )
          .call<Object?>(datos.aEnvio());
      final cuerpo = respuesta.data;
      if (cuerpo is! Map) {
        return const CompraRechazada(MensajesCompras.errorInterno);
      }
      return CompraGuardada(
        Compra.desdeMapa(cuerpo['compraId'] as String? ?? '', {
          ...cuerpo,
          'tipo': datos.tipo.name,
          'proveedor': datos.aEnvio()['proveedor'],
          'fecha': DateTime.now(),
        }),
      );
    } on FirebaseFunctionsException catch (error) {
      return traducirErrorCompra(error.code, error.message, error.details);
    } catch (_) {
      return const CompraRechazada(MensajesCompras.errorInterno);
    }
  }
}

/// Convierte el error de la función en lo que muestra el formulario.
ResultadoCompra traducirErrorCompra(
  String codigo,
  String? mensaje,
  Object? detalles,
) {
  switch (codigo) {
    case 'permission-denied' || 'unauthenticated':
      return const CompraSinPermiso();
    case 'invalid-argument' || 'failed-precondition':
      final pendientes = detalles is Map && detalles['pendientes'] is List
          ? {
              for (final nombre in detalles['pendientes'] as List)
                ?CampoCompra.values.asNameMap()[nombre],
            }
          : <CampoCompra>{};
      return CompraRechazada(
        mensaje ?? MensajesCompras.errorInterno,
        pendientes: pendientes,
      );
    case 'unavailable' || 'deadline-exceeded':
      return const CompraRechazada(MensajesCompras.sinConexion);
    default:
      return const CompraRechazada(MensajesCompras.errorInterno);
  }
}
