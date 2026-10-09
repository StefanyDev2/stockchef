import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/inicio_sesion.dart';
import '../domain/perfil_usuario.dart';

/// Inicio de sesión con Firebase Authentication, el perfil de Firestore y el
/// contador de intentos de las Cloud Functions (functions/src/bloqueo.ts).
class SesionRepositorioFirebase implements SesionRepositorio {
  SesionRepositorioFirebase(this._auth, this._db, this._funciones);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _funciones;

  static const _tiempoMaximo = Duration(seconds: 15);

  @override
  Future<ResultadoInicioSesion> iniciarSesion(DatosInicioSesion datos) async {
    final UserCredential credencial;
    try {
      credencial = await _auth.signInWithEmailAndPassword(
        email: datos.correoNormalizado,
        password: datos.contrasena,
      );
    } on FirebaseAuthException catch (error) {
      if (!esCredencialInvalida(error.code)) {
        return SesionRechazada(mensajeErrorInicioSesion(error.code));
      }
      return _registrarFallo(datos.correoNormalizado);
    } catch (_) {
      return const SesionRechazada(MensajesInicioSesion.errorInterno);
    }

    // La contraseña es correcta. Falta saber si la cuenta está bloqueada
    // (CA11) y leer el rol; se consultan a la vez para responder rápido (CA14).
    final uid = credencial.user!.uid;
    try {
      final (bloqueo, perfil) = await (
        _llamar('registrarIngreso', null),
        _leerPerfil(uid),
      ).wait;

      final hasta = _bloqueadoHasta(bloqueo);
      if (hasta != null) {
        await _auth.signOut();
        return SesionBloqueada(hasta: hasta, minutos: _minutos(bloqueo));
      }
      if (perfil == null) {
        await _auth.signOut();
        return const SesionRechazada(MensajesInicioSesion.errorInterno);
      }
      if (!perfil.activo) {
        await _auth.signOut();
        return const SesionRechazada(MensajesInicioSesion.cuentaDesactivada);
      }
      return SesionIniciada(perfil);
    } catch (_) {
      // Si no se pudo confirmar el bloqueo, no se deja entrar.
      await _auth.signOut();
      return const SesionRechazada(MensajesInicioSesion.errorInterno);
    }
  }

  /// Suma el intento fallido. Si el contador no responde, igual se muestra
  /// el mensaje de credenciales no válidas.
  Future<ResultadoInicioSesion> _registrarFallo(String correo) async {
    try {
      final bloqueo = await _llamar('registrarIntentoFallido', {
        'correo': correo,
      });
      final hasta = _bloqueadoHasta(bloqueo);
      if (hasta != null) {
        return SesionBloqueada(hasta: hasta, minutos: _minutos(bloqueo));
      }
    } catch (_) {
      // Se informa el fallo de credenciales de todas formas.
    }
    return const SesionRechazada(MensajesInicioSesion.credencialesInvalidas);
  }

  @override
  Future<PerfilUsuario?> sesionGuardada() async {
    final usuario = await _auth.authStateChanges().first;
    if (usuario == null) return null;
    try {
      final perfil = await _leerPerfil(usuario.uid);
      if (perfil == null || !perfil.activo) {
        await _auth.signOut();
        return null;
      }
      return perfil;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cerrarSesion() => _auth.signOut();

  Future<PerfilUsuario?> _leerPerfil(String uid) async {
    final documento = await _db.doc('users/$uid').get();
    final datos = documento.data();
    return datos == null ? null : PerfilUsuario.desdeFirestore(uid, datos);
  }

  Future<Map<Object?, Object?>> _llamar(String funcion, Object? datos) async {
    final respuesta = await _funciones
        .httpsCallable(
          funcion,
          options: HttpsCallableOptions(timeout: _tiempoMaximo),
        )
        .call<Object?>(datos);
    final cuerpo = respuesta.data;
    return cuerpo is Map ? cuerpo : const {};
  }
}

DateTime? _bloqueadoHasta(Map<Object?, Object?> estado) {
  final hasta = estado['bloqueadoHasta'];
  if (estado['bloqueado'] != true || hasta is! String) return null;
  return DateTime.tryParse(hasta);
}

int _minutos(Map<Object?, Object?> estado) {
  final minutos = estado['minutosBloqueo'];
  return minutos is int && minutos > 0 ? minutos : 120;
}

/// Códigos de Firebase que significan correo o contraseña equivocados.
bool esCredencialInvalida(String codigo) => const {
  'invalid-credential',
  'wrong-password',
  'user-not-found',
  'invalid-email',
}.contains(codigo);

/// Mensaje para los demás errores de Firebase Authentication.
String mensajeErrorInicioSesion(String codigo) => switch (codigo) {
  _ when esCredencialInvalida(codigo) =>
    MensajesInicioSesion.credencialesInvalidas,
  'user-disabled' => MensajesInicioSesion.cuentaDesactivada,
  'network-request-failed' => MensajesInicioSesion.sinConexion,
  _ => MensajesInicioSesion.errorInterno,
};
