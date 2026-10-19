import '../../auth/domain/perfil_usuario.dart';

/// Mensajes de HU-003, tal como aparecen en el prototipo. Los de error son
/// los mismos que envía el servidor (functions/src/usuarios.ts).
abstract final class MensajesUsuarios {
  static const rolActualizado = 'Rol actualizado correctamente';
  static const usuarioDesactivado = 'Usuario desactivado correctamente';
  static const usuarioReactivado = 'Usuario reactivado correctamente';
  static const ultimoAdministrador =
      'Debe haber al menos un administrador en el restaurante.';
  static const noPuedesDesactivarte = 'No puedes desactivar tu propia cuenta.';
  static const sinPermisoTitulo =
      'No tienes permisos para realizar esta acción';
  static const sinPermisoDetalle =
      'Solo un administrador puede gestionar usuarios y roles.';
  static const sinConexion =
      'No hay conexión. Revisa tu internet e intenta de nuevo.';
  static const errorInterno = 'No se pudo guardar el cambio. Intenta de nuevo.';
  static const errorLista = 'No se pudo cargar la lista de usuarios.';
}

/// Roles que el administrador puede asignar (CA3): no se vuelve a "sin rol".
const rolesAsignables = [Rol.administrador, Rol.auxiliarCocina];

/// Consulta y cambia los usuarios del restaurante. La implementación real
/// lee Firestore y llama a las Cloud Functions de HU-003.
abstract interface class UsuariosRepositorio {
  /// CA1: usuarios del restaurante, ordenados por nombre. Se actualiza solo
  /// cuando alguien hace un cambio.
  Stream<List<PerfilUsuario>> usuariosDe(String restaurantId);

  /// CA3.
  Future<ResultadoCambio> asignarRol(String uid, Rol rol);

  /// CA4: `activo = false` desactiva; `true` reactiva.
  Future<ResultadoCambio> cambiarEstado(String uid, {required bool activo});
}

sealed class ResultadoCambio {
  const ResultadoCambio();
}

final class CambioGuardado extends ResultadoCambio {
  const CambioGuardado();
}

/// El servidor no aceptó el cambio; el mensaje explica por qué (CA5).
final class CambioRechazado extends ResultadoCambio {
  const CambioRechazado(this.mensaje);

  final String mensaje;
}

/// CA9: quien intentó el cambio ya no es administrador activo.
final class CambioSinPermiso extends ResultadoCambio {
  const CambioSinPermiso();
}

/// Orden de la lista: por nombres y luego apellidos, sin importar tildes
/// ni mayúsculas.
List<PerfilUsuario> ordenarUsuarios(Iterable<PerfilUsuario> usuarios) {
  String clave(PerfilUsuario u) => u.nombreCompleto.toLowerCase();
  return usuarios.toList()..sort((a, b) => clave(a).compareTo(clave(b)));
}
