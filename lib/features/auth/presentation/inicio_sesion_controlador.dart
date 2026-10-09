import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sesion_repositorio_firebase.dart';
import '../domain/inicio_sesion.dart';

final sesionRepositorioProvider = Provider<SesionRepositorio>(
  (ref) => SesionRepositorioFirebase(FirebaseAuth.instance),
);

final inicioSesionControladorProvider =
    NotifierProvider.autoDispose<InicioSesionControlador, EstadoInicioSesion>(
      InicioSesionControlador.new,
    );

class EstadoInicioSesion {
  const EstadoInicioSesion({
    this.errores = const {},
    this.aviso,
    this.enviando = false,
  });

  final Map<CampoInicioSesion, String> errores;
  final String? aviso;
  final bool enviando;
}

class InicioSesionControlador extends Notifier<EstadoInicioSesion> {
  @override
  EstadoInicioSesion build() => const EstadoInicioSesion();

  /// Devuelve el nombre del usuario si pudo entrar, o `null` si no.
  Future<String?> iniciarSesion(DatosInicioSesion datos) async {
    if (state.enviando) return null;

    final errores = datos.validar();
    if (errores.isNotEmpty) {
      state = EstadoInicioSesion(
        errores: errores,
        aviso: errores.length == CampoInicioSesion.values.length
            ? MensajesInicioSesion.completaAmbos
            : null,
      );
      return null;
    }

    state = const EstadoInicioSesion(enviando: true);
    final resultado = await ref
        .read(sesionRepositorioProvider)
        .iniciarSesion(datos);
    if (!ref.mounted) return null;

    switch (resultado) {
      case SesionIniciada(:final nombre):
        state = const EstadoInicioSesion();
        return nombre;
      case SesionRechazada(:final mensaje):
        state = EstadoInicioSesion(aviso: mensaje);
        return null;
    }
  }

  /// Al escribir de nuevo se quitan el error del campo y el aviso, para
  /// poder reintentar (HU-002, CA9).
  void campoEditado(CampoInicioSesion campo) {
    if (!state.errores.containsKey(campo) && state.aviso == null) return;
    state = EstadoInicioSesion(errores: Map.of(state.errores)..remove(campo));
  }
}
