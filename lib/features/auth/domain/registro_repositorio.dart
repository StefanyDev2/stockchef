import 'datos_registro.dart';

/// Crea cuentas de usuario. La implementación real llama a la Cloud Function
/// `registrarUsuario`; en las pruebas se reemplaza por una falsa.
abstract interface class RegistroRepositorio {
  Future<ResultadoRegistro> registrar(DatosRegistro datos);
}

sealed class ResultadoRegistro {
  const ResultadoRegistro();
}

/// La cuenta se creó (CA9). `rol` es "administrador" o `null` (CA10).
final class RegistroExitoso extends ResultadoRegistro {
  const RegistroExitoso({this.rol});

  final String? rol;
}

/// El servidor rechazó algún dato, por ejemplo un correo ya registrado (CA5).
final class RegistroRechazado extends ResultadoRegistro {
  const RegistroRechazado(this.errores);

  final Map<CampoRegistro, String> errores;
}

/// No se pudo completar: sin conexión o error inesperado.
final class RegistroFallido extends ResultadoRegistro {
  const RegistroFallido(this.mensaje);

  final String mensaje;
}
