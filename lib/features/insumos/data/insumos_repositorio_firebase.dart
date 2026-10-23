import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/insumos.dart';

/// Insumos desde Firestore y la lista de críticos con la Cloud Function
/// `guardarInsumosCriticos` (functions/src/insumos.ts).
class InsumosRepositorioFirebase implements InsumosRepositorio {
  InsumosRepositorioFirebase(this._db, this._funciones);

  final FirebaseFirestore _db;
  final FirebaseFunctions _funciones;

  static const _tiempoMaximo = Duration(seconds: 15);

  @override
  Stream<List<InsumoRegistrado>> insumosDe(String restaurantId) => _db
      .collection('restaurants/$restaurantId/insumos')
      .snapshots()
      .map(
        (consulta) => [
          for (final doc in consulta.docs)
            InsumoRegistrado.desdeFirestore(doc.id, doc.data()),
        ],
      );

  @override
  Future<ResultadoGuardado> guardarCriticos(Set<String> criticos) async {
    try {
      await _funciones
          .httpsCallable(
            'guardarInsumosCriticos',
            options: HttpsCallableOptions(timeout: _tiempoMaximo),
          )
          .call<Object?>({'criticos': criticos.toList()..sort()});
      return const ListaGuardada();
    } on FirebaseFunctionsException catch (error) {
      return traducirErrorInsumos(error.code, error.message);
    } catch (_) {
      return const ListaRechazada(MensajesInsumos.errorInterno);
    }
  }
}

/// Convierte el error de la función en lo que muestra la pantalla.
ResultadoGuardado traducirErrorInsumos(String codigo, String? mensaje) =>
    switch (codigo) {
      'permission-denied' || 'unauthenticated' => const ListaSinPermiso(),
      'failed-precondition' || 'invalid-argument' => ListaRechazada(
        mensaje ?? MensajesInsumos.errorInterno,
      ),
      'unavailable' ||
      'deadline-exceeded' => const ListaRechazada(MensajesInsumos.sinConexion),
      _ => const ListaRechazada(MensajesInsumos.errorInterno),
    };
