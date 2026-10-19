import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../auth/domain/perfil_usuario.dart';
import '../domain/usuarios.dart';

/// Lista de usuarios desde Firestore (las reglas solo la dejan leer al
/// administrador activo) y cambios con las Cloud Functions de HU-003.
class UsuariosRepositorioFirebase implements UsuariosRepositorio {
  UsuariosRepositorioFirebase(this._db, this._funciones);

  final FirebaseFirestore _db;
  final FirebaseFunctions _funciones;

  static const _tiempoMaximo = Duration(seconds: 15);

  @override
  Stream<List<PerfilUsuario>> usuariosDe(String restaurantId) => _db
      .collection('users')
      .where('restaurantId', isEqualTo: restaurantId)
      .snapshots()
      .map(
        (consulta) => ordenarUsuarios(
          consulta.docs.map(
            (doc) => PerfilUsuario.desdeFirestore(doc.id, doc.data()),
          ),
        ),
      );

  @override
  Future<ResultadoCambio> asignarRol(String uid, Rol rol) =>
      _llamar('asignarRol', {'uid': uid, 'rol': rolAFirestore(rol)});

  @override
  Future<ResultadoCambio> cambiarEstado(String uid, {required bool activo}) =>
      _llamar('cambiarEstadoUsuario', {'uid': uid, 'activo': activo});

  Future<ResultadoCambio> _llamar(
    String funcion,
    Map<String, Object?> datos,
  ) async {
    try {
      await _funciones
          .httpsCallable(
            funcion,
            options: HttpsCallableOptions(timeout: _tiempoMaximo),
          )
          .call<Object?>(datos);
      return const CambioGuardado();
    } on FirebaseFunctionsException catch (error) {
      return traducirErrorCambio(error.code, error.message);
    } catch (_) {
      return const CambioRechazado(MensajesUsuarios.errorInterno);
    }
  }
}

/// Valor que se guarda en Firestore para cada rol asignable.
String rolAFirestore(Rol rol) => switch (rol) {
  Rol.administrador => 'administrador',
  Rol.auxiliarCocina => 'auxiliar_cocina',
  Rol.sinRol => throw ArgumentError('"Sin rol" no se puede asignar'),
};

/// Convierte el error de la función en lo que muestra la pantalla.
ResultadoCambio traducirErrorCambio(String codigo, String? mensaje) =>
    switch (codigo) {
      'permission-denied' || 'unauthenticated' => const CambioSinPermiso(),
      'failed-precondition' => CambioRechazado(
        mensaje ?? MensajesUsuarios.errorInterno,
      ),
      'unavailable' || 'deadline-exceeded' => const CambioRechazado(
        MensajesUsuarios.sinConexion,
      ),
      _ => const CambioRechazado(MensajesUsuarios.errorInterno),
    };
