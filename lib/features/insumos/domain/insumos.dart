/// Mensajes de HU-004. Los de error son los mismos que envía el servidor
/// (functions/src/insumos.ts).
abstract final class MensajesInsumos {
  static const guardado = 'Lista de insumos críticos guardada correctamente';
  static const sinInsumos = 'Todavía no hay insumos registrados.';
  static const sinCriticos = 'Ningún insumo está marcado como crítico.';
  static const sinOtros = 'Todos los insumos son críticos.';
  static const cambiosSinGuardar =
      'Tienes cambios sin guardar. ¿Quieres salir sin guardarlos?';
  static const sinConexion =
      'No hay conexión. Revisa tu internet e intenta de nuevo.';
  static const errorInterno = 'No se pudo guardar la lista. Intenta de nuevo.';
  static const errorLista = 'No se pudo cargar la lista de insumos.';
}

/// Insumo registrado en el restaurante, con su clasificación (HU-004).
class InsumoRegistrado {
  const InsumoRegistrado({
    required this.id,
    required this.nombre,
    required this.activo,
    required this.critico,
  });

  /// Si falta `critico` se considera "No crítico".
  factory InsumoRegistrado.desdeFirestore(
    String id,
    Map<String, Object?> datos,
  ) => InsumoRegistrado(
    id: id,
    nombre: datos['nombre'] is String ? datos['nombre']! as String : id,
    activo: datos['activo'] == true,
    critico: datos['critico'] == true,
  );

  final String id;
  final String nombre;
  final bool activo;
  final bool critico;
}

/// Consulta los insumos y guarda la lista de críticos. La implementación
/// real lee Firestore y llama a la Cloud Function `guardarInsumosCriticos`.
abstract interface class InsumosRepositorio {
  /// CA1: todos los insumos registrados, ordenados por nombre.
  Stream<List<InsumoRegistrado>> insumosDe(String restaurantId);

  /// CA5: guarda cuáles son críticos; los demás quedan como no críticos.
  Future<ResultadoGuardado> guardarCriticos(Set<String> criticos);
}

sealed class ResultadoGuardado {
  const ResultadoGuardado();
}

final class ListaGuardada extends ResultadoGuardado {
  const ListaGuardada();
}

final class ListaRechazada extends ResultadoGuardado {
  const ListaRechazada(this.mensaje);

  final String mensaje;
}

/// Quien intentó guardar ya no es administrador activo.
final class ListaSinPermiso extends ResultadoGuardado {
  const ListaSinPermiso();
}

/// CA6: separa los insumos en críticos y otros, según la selección actual,
/// cada grupo ordenado por nombre.
({List<InsumoRegistrado> criticos, List<InsumoRegistrado> otros})
separarPorCriticidad(Iterable<InsumoRegistrado> insumos, Set<String> criticos) {
  final ordenados = insumos.toList()
    ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  return (
    criticos: [...ordenados.where((i) => criticos.contains(i.id))],
    otros: [...ordenados.where((i) => !criticos.contains(i.id))],
  );
}
