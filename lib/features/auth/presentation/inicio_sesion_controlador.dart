import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/inicio_sesion.dart';
import 'sesion_controlador.dart';

final inicioSesionControladorProvider =
    NotifierProvider.autoDispose<InicioSesionControlador, EstadoInicioSesion>(
      InicioSesionControlador.new,
    );

class EstadoInicioSesion {
  const EstadoInicioSesion({
    this.errores = const {},
    this.aviso,
    this.enviando = false,
    this.bloqueadoHasta,
  });

  final Map<CampoInicioSesion, String> errores;
  final String? aviso;
  final bool enviando;

  /// Mientras tenga valor, el formulario queda deshabilitado (pantalla E3).
  final DateTime? bloqueadoHasta;

  bool get bloqueado => bloqueadoHasta != null;
}

class InicioSesionControlador extends Notifier<EstadoInicioSesion> {
  Timer? _finBloqueo;

  @override
  EstadoInicioSesion build() {
    ref.onDispose(() => _finBloqueo?.cancel());
    return const EstadoInicioSesion();
  }

  /// Intenta entrar. Si se acepta, avisa a la sesión y las rutas llevan a
  /// la pantalla del rol (CA5, CA6, CA7).
  Future<void> iniciarSesion(DatosInicioSesion datos) async {
    if (state.enviando || state.bloqueado) return;

    final errores = datos.validar();
    if (errores.isNotEmpty) {
      state = EstadoInicioSesion(
        errores: errores,
        aviso: errores.length == CampoInicioSesion.values.length
            ? MensajesInicioSesion.completaAmbos
            : null,
      );
      return;
    }

    state = const EstadoInicioSesion(enviando: true);
    final cronometro = Stopwatch()..start();
    final resultado = await ref
        .read(sesionRepositorioProvider)
        .iniciarSesion(datos);
    if (kDebugMode) {
      debugPrint('Inicio de sesión: ${cronometro.elapsedMilliseconds} ms');
    }
    if (!ref.mounted) return;

    switch (resultado) {
      case SesionIniciada(:final perfil):
        state = const EstadoInicioSesion();
        ref.read(sesionProvider.notifier).iniciada(perfil);
      case SesionRechazada(:final mensaje):
        state = EstadoInicioSesion(aviso: mensaje);
      case SesionBloqueada(:final hasta, :final minutos):
        _bloquear(hasta, minutos);
    }
  }

  /// CA10, CA11: deshabilita el formulario hasta que venza el bloqueo, y
  /// entonces lo habilita de nuevo (CA12).
  void _bloquear(DateTime hasta, int minutos) {
    state = EstadoInicioSesion(
      aviso: MensajesInicioSesion.cuentaBloqueada(minutos),
      bloqueadoHasta: hasta,
    );
    _finBloqueo?.cancel();
    final restante = hasta.difference(DateTime.now());
    _finBloqueo = Timer(
      restante.isNegative ? Duration.zero : restante,
      () => state = const EstadoInicioSesion(),
    );
  }

  /// Al escribir de nuevo se quitan el error del campo y el aviso, para
  /// poder reintentar (CA9).
  void campoEditado(CampoInicioSesion campo) {
    if (state.bloqueado) return;
    if (!state.errores.containsKey(campo) && state.aviso == null) return;
    state = EstadoInicioSesion(errores: Map.of(state.errores)..remove(campo));
  }
}
