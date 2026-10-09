import 'normalizacion.dart';

/// Mensajes del inicio de sesión, tal como aparecen en el prototipo de HU-002.
abstract final class MensajesInicioSesion {
  static const ingresaCorreo = 'Ingresa tu correo electrónico';
  static const ingresaContrasena = 'Ingresa tu contraseña';
  static const completaAmbos = 'Completa ambos campos';

  /// Siempre el mismo mensaje, sin decir si falló el correo o la contraseña.
  static const credencialesInvalidas = 'Las credenciales no son válidas';
  static const sinConexion =
      'No hay conexión. Revisa tu internet e intenta de nuevo.';
  static const errorInterno = 'No se pudo iniciar sesión. Intenta de nuevo.';
}

enum CampoInicioSesion { correo, contrasena }

/// Lo que la persona escribió en el formulario de inicio de sesión.
class DatosInicioSesion {
  const DatosInicioSesion({this.correo = '', this.contrasena = ''});

  final String correo;
  final String contrasena;

  /// Correo normalizado, igual que al registrarse.
  String get correoNormalizado => normalizarCorreo(correo);

  /// Ambos campos son obligatorios. El formato del correo no se valida aquí:
  /// un correo mal escrito simplemente no corresponde a ninguna cuenta.
  Map<CampoInicioSesion, String> validar() => {
    if (correo.trim().isEmpty)
      CampoInicioSesion.correo: MensajesInicioSesion.ingresaCorreo,
    if (contrasena.isEmpty)
      CampoInicioSesion.contrasena: MensajesInicioSesion.ingresaContrasena,
  };
}

/// Inicia y cierra sesión. La implementación real usa Firebase Authentication.
abstract interface class SesionRepositorio {
  Future<ResultadoInicioSesion> iniciarSesion(DatosInicioSesion datos);

  Future<void> cerrarSesion();
}

sealed class ResultadoInicioSesion {
  const ResultadoInicioSesion();
}

final class SesionIniciada extends ResultadoInicioSesion {
  const SesionIniciada({required this.nombre});

  /// Nombre para saludar; el que se guardó al registrarse.
  final String nombre;
}

final class SesionRechazada extends ResultadoInicioSesion {
  const SesionRechazada(this.mensaje);

  final String mensaje;
}
