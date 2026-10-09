import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/configuracion_firebase.dart';
import '../data/registro_repositorio_firebase.dart';
import '../domain/datos_registro.dart';
import '../domain/mensajes_validacion.dart';
import '../domain/registro_repositorio.dart';

final registroRepositorioProvider = Provider<RegistroRepositorio>(
  (ref) => RegistroRepositorioFirebase(ref.watch(funcionesProvider)),
);

final registroControladorProvider =
    NotifierProvider.autoDispose<RegistroControlador, EstadoRegistro>(
      RegistroControlador.new,
    );

/// Lo que la pantalla de registro necesita mostrar. Los valores escritos no
/// viven aquí sino en los campos de texto, por eso nunca se borran (CA8).
class EstadoRegistro {
  const EstadoRegistro({
    this.errores = const {},
    this.aviso,
    this.enviando = false,
  });

  /// Error bajo cada campo (CA3 a CA7).
  final Map<CampoRegistro, String> errores;

  /// Aviso rojo de la parte superior (pantallas E1 y E2).
  final String? aviso;

  final bool enviando;

  EstadoRegistro copiarCon({
    Map<CampoRegistro, String>? errores,
    String? Function()? aviso,
    bool? enviando,
  }) => EstadoRegistro(
    errores: errores ?? this.errores,
    aviso: aviso != null ? aviso() : this.aviso,
    enviando: enviando ?? this.enviando,
  );
}

class RegistroControlador extends Notifier<EstadoRegistro> {
  @override
  EstadoRegistro build() => const EstadoRegistro();

  /// Valida y, si todo está bien, crea la cuenta. Devuelve `true` cuando la
  /// cuenta quedó creada para que la pantalla muestre el mensaje de éxito.
  Future<bool> registrar(DatosRegistro datos) async {
    if (state.enviando) return false;

    final validacion = datos.validar();
    if (!validacion.esValido) {
      state = EstadoRegistro(
        errores: validacion.errores,
        aviso: validacion.aviso,
      );
      return false;
    }

    state = const EstadoRegistro(enviando: true);
    final resultado = await ref
        .read(registroRepositorioProvider)
        .registrar(datos);
    if (!ref.mounted) return false;

    switch (resultado) {
      case RegistroExitoso():
        state = const EstadoRegistro();
        return true;
      case RegistroRechazado(:final errores):
        state = EstadoRegistro(
          errores: errores,
          aviso: MensajesValidacion.corrigeCampos,
        );
        return false;
      case RegistroFallido(:final mensaje):
        state = EstadoRegistro(aviso: mensaje);
        return false;
    }
  }

  /// Al corregir un campo se quita su error; los demás datos se conservan.
  void campoEditado(CampoRegistro campo) {
    if (!state.errores.containsKey(campo)) return;
    final errores = Map.of(state.errores)..remove(campo);
    state = state.copiarCon(
      errores: errores,
      aviso: errores.isEmpty ? () => null : null,
    );
  }
}
