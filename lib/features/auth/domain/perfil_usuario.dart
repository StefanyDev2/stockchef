/// Rol del usuario dentro de su restaurante (docs/modelo-datos.md).
enum Rol {
  administrador('Administrador'),
  auxiliarCocina('Auxiliar de cocina'),
  sinRol('Sin rol asignado');

  const Rol(this.etiqueta);

  final String etiqueta;

  /// Valor guardado en Firestore. Cualquier valor desconocido se trata como
  /// "sin rol", para no dar acceso de más.
  static Rol desdeFirestore(Object? valor) => switch (valor) {
    'administrador' => Rol.administrador,
    'auxiliar_cocina' => Rol.auxiliarCocina,
    _ => Rol.sinRol,
  };
}

/// Datos del usuario que inició sesión, leídos de `users/{uid}`.
class PerfilUsuario {
  const PerfilUsuario({
    required this.uid,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.rol,
    required this.activo,
  });

  /// Construye el perfil desde el documento de Firestore. Si falta `activo`
  /// se considera desactivado, para no dejar entrar por un dato incompleto.
  factory PerfilUsuario.desdeFirestore(String uid, Map<String, Object?> datos) {
    String texto(String campo) =>
        datos[campo] is String ? datos[campo]! as String : '';
    return PerfilUsuario(
      uid: uid,
      nombres: texto('nombres'),
      apellidos: texto('apellidos'),
      correo: texto('correo'),
      rol: Rol.desdeFirestore(datos['rol']),
      activo: datos['activo'] == true,
    );
  }

  final String uid;
  final String nombres;
  final String apellidos;
  final String correo;
  final Rol rol;
  final bool activo;

  String get nombreCompleto => '$nombres $apellidos'.trim();

  /// Primer nombre, para el saludo y la barra superior.
  String get primerNombre => nombres.trim().split(' ').first;
}
