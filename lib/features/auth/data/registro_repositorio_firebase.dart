import 'package:cloud_functions/cloud_functions.dart';

import '../domain/datos_registro.dart';
import '../domain/mensajes_validacion.dart';
import '../domain/registro_repositorio.dart';

/// Registra usuarios con la Cloud Function `registrarUsuario`
/// (functions/src/registro.ts).
class RegistroRepositorioFirebase implements RegistroRepositorio {
  RegistroRepositorioFirebase(this._funciones);

  final FirebaseFunctions _funciones;

  static const _tiempoMaximo = Duration(seconds: 20);

  @override
  Future<ResultadoRegistro> registrar(DatosRegistro datos) async {
    try {
      final respuesta = await _funciones
          .httpsCallable(
            'registrarUsuario',
            options: HttpsCallableOptions(timeout: _tiempoMaximo),
          )
          .call<Object?>(datos.aEnvio());
      final cuerpo = respuesta.data;
      return RegistroExitoso(
        rol: cuerpo is Map ? cuerpo['rol'] as String? : null,
      );
    } on FirebaseFunctionsException catch (error) {
      return traducirErrorRegistro(error.code, error.details);
    } catch (_) {
      return const RegistroFallido(MensajesValidacion.errorInterno);
    }
  }
}

/// Convierte el error de la función en un resultado para la pantalla.
/// La función envía los errores por campo en `details.errores`.
ResultadoRegistro traducirErrorRegistro(String codigo, Object? detalles) {
  switch (codigo) {
    case 'invalid-argument':
    case 'already-exists':
      final errores = _erroresPorCampo(detalles);
      return errores.isEmpty
          ? const RegistroFallido(MensajesValidacion.errorInterno)
          : RegistroRechazado(errores);
    case 'unavailable':
    case 'deadline-exceeded':
      return const RegistroFallido(MensajesValidacion.sinConexion);
    default:
      return const RegistroFallido(MensajesValidacion.errorInterno);
  }
}

Map<CampoRegistro, String> _erroresPorCampo(Object? detalles) {
  if (detalles is! Map) return const {};
  final errores = detalles['errores'];
  if (errores is! Map) return const {};

  final campos = CampoRegistro.values.asNameMap();
  return {
    for (final MapEntry(:key, :value) in errores.entries)
      if (campos[key] != null && value is String) campos[key]!: value,
  };
}
