import 'normalizacion.dart';
import 'perfil_usuario.dart';

/// Mensajes del inicio de sesión, tal como aparecen en el prototipo de HU-002.
abstract final class MensajesInicioSesion {
  static const ingresaCorreo = 'Ingresa tu correo electrónico';
  static const ingresaContrasena = 'Ingresa tu contraseña';
  static const completaAmbos = 'Completa ambos campos';

  /// Siempre el mismo mensaje, sin decir si falló el correo o la contraseña.
  static const credencialesInvalidas = 'Las credenciales no son válidas';
  static const cuentaDesactivada =
      'Tu cuenta está desactivada. Comunícate con un administrador.';
  static const notaBloqueo =
      'Mientras la cuenta esté bloqueada no podrás ingresar, aunque tus '
      'credenciales sean correctas.';
  static const sinConexion =
      'No hay conexión. Revisa tu internet e intenta de nuevo.';
  static const errorInterno = 'No se pudo iniciar sesión. Intenta de nuevo.';

  /// Aviso de la pantalla E3 (CA10).
  static String cuentaBloqueada(int minutos) =>
      '🔒 Alcanzaste el número máximo de intentos. Tu cuenta está bloqueada '
      'por ${duracion(minutos)}.';

  /// "2 horas", "1 hora", "90 minutos", "1 minuto".
  static String duracion(int minutos) {
    if (minutos % 60 == 0) {
      final horas = minutos ~/ 60;
      return horas == 1 ? '1 hora' : '$horas horas';
    }
    return minutos == 1 ? '1 minuto' : '$minutos minutos';
  }
}

enum CampoInicioSesion { correo, contrasena }

/// Lo que la persona escribió en el formulario de inicio de sesión.
class DatosInicioSesion {
  const DatosInicioSesion({this.correo = '', this.contrasena = ''});

  final String correo;
  final String contrasena;

  /// Correo normalizado, igual que al registrarse.
  String get correoNormalizado => normalizarCorreo(correo);

  /// Ambos campos son obligatorios (CA3). El formato del correo no se valida
  /// aquí: un correo mal escrito simplemente no corresponde a ninguna cuenta.
  Map<CampoInicioSesion, String> validar() => {
    if (correo.trim().isEmpty)
      CampoInicioSesion.correo: MensajesInicioSesion.ingresaCorreo,
    if (contrasena.isEmpty)
      CampoInicioSesion.contrasena: MensajesInicioSesion.ingresaContrasena,
  };
}

/// Inicia, recupera y cierra la sesión.
abstract interface class SesionRepositorio {
  Future<ResultadoInicioSesion> iniciarSesion(DatosInicioSesion datos);

  /// Perfil de la sesión que quedó abierta al cerrar la app (CA13), o `null`
  /// si no hay sesión o la cuenta ya no puede entrar.
  Future<PerfilUsuario?> sesionGuardada();

  Future<void> cerrarSesion();
}

sealed class ResultadoInicioSesion {
  const ResultadoInicioSesion();
}

/// CA5: entró. El perfil dice qué pantalla ver (CA6, CA7).
final class SesionIniciada extends ResultadoInicioSesion {
  const SesionIniciada(this.perfil);

  final PerfilUsuario perfil;
}

/// No entró: credenciales no válidas, cuenta desactivada o sin conexión.
final class SesionRechazada extends ResultadoInicioSesion {
  const SesionRechazada(this.mensaje);

  final String mensaje;
}

/// CA10, CA11: la cuenta está bloqueada hasta `hasta`.
final class SesionBloqueada extends ResultadoInicioSesion {
  const SesionBloqueada({required this.hasta, required this.minutos});

  final DateTime hasta;

  /// Duración total del bloqueo, para el aviso.
  final int minutos;
}
