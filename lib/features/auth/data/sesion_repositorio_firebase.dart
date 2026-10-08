import 'package:firebase_auth/firebase_auth.dart';

import '../domain/inicio_sesion.dart';

/// Inicio de sesión con correo y contraseña en Firebase Authentication.
class SesionRepositorioFirebase implements SesionRepositorio {
  SesionRepositorioFirebase(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<ResultadoInicioSesion> iniciarSesion(DatosInicioSesion datos) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: datos.correoNormalizado,
        password: datos.contrasena,
      );
      final usuario = credencial.user;
      return SesionIniciada(
        nombre: usuario?.displayName ?? usuario?.email ?? '',
      );
    } on FirebaseAuthException catch (error) {
      return SesionRechazada(mensajeErrorInicioSesion(error.code));
    } catch (_) {
      return const SesionRechazada(MensajesInicioSesion.errorInterno);
    }
  }

  @override
  Future<void> cerrarSesion() => _auth.signOut();
}

/// Traduce el código de Firebase al mensaje de la pantalla. Correo
/// desconocido y contraseña errada dan el mismo mensaje (HU-002, CA8).
String mensajeErrorInicioSesion(String codigo) => switch (codigo) {
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' ||
  'invalid-email' => MensajesInicioSesion.credencialesInvalidas,
  'network-request-failed' => MensajesInicioSesion.sinConexion,
  _ => MensajesInicioSesion.errorInterno,
};
