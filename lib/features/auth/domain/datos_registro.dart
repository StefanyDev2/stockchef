import 'mensajes_validacion.dart';
import 'normalizacion.dart';
import 'validaciones.dart';

/// Campos del formulario de registro (CA1), en el orden del prototipo.
enum CampoRegistro {
  nombres('Nombres'),
  apellidos('Apellidos'),
  correo('Correo electrónico'),
  restaurante('Nombre del restaurante'),
  contrasena('Contraseña'),
  confirmacion('Confirmar contraseña');

  const CampoRegistro(this.etiqueta);

  final String etiqueta;
}

/// Lo que la persona escribió en el formulario de registro.
class DatosRegistro {
  const DatosRegistro({
    this.nombres = '',
    this.apellidos = '',
    this.correo = '',
    this.restaurante = '',
    this.contrasena = '',
    this.confirmacion = '',
  });

  final String nombres;
  final String apellidos;
  final String correo;
  final String restaurante;
  final String contrasena;
  final String confirmacion;

  /// Valida todos los campos a la vez (CA2 a CA8).
  ResultadoValidacion validar() {
    final errores = <CampoRegistro, String>{};
    void revisar(CampoRegistro campo, String? error) {
      if (error != null) errores[campo] = error;
    }

    revisar(CampoRegistro.nombres, Validaciones.obligatorio(nombres));
    revisar(CampoRegistro.apellidos, Validaciones.obligatorio(apellidos));
    revisar(CampoRegistro.correo, Validaciones.correo(correo));
    revisar(CampoRegistro.restaurante, Validaciones.obligatorio(restaurante));
    revisar(CampoRegistro.contrasena, Validaciones.contrasena(contrasena));
    revisar(
      CampoRegistro.confirmacion,
      Validaciones.confirmacion(contrasena, confirmacion),
    );
    return ResultadoValidacion(errores);
  }

  /// Datos listos para enviar: textos limpios y correo normalizado.
  /// La contraseña se envía tal cual; nunca se recorta ni se modifica.
  Map<String, String> aEnvio() => {
    'nombres': limpiarTexto(nombres),
    'apellidos': limpiarTexto(apellidos),
    'correo': normalizarCorreo(correo),
    'restaurante': limpiarTexto(restaurante),
    'contrasena': contrasena,
  };
}

/// Errores por campo y aviso superior del formulario.
class ResultadoValidacion {
  const ResultadoValidacion(this.errores);

  final Map<CampoRegistro, String> errores;

  bool get esValido => errores.isEmpty;

  String? errorDe(CampoRegistro campo) => errores[campo];

  /// Aviso de la parte superior: E1 si falta algún campo obligatorio,
  /// E2 si todos están diligenciados pero alguno no es válido.
  String? get aviso {
    if (esValido) return null;
    final faltanCampos = errores.values.contains(
      MensajesValidacion.campoObligatorio,
    );
    return faltanCampos
        ? MensajesValidacion.completaCampos
        : MensajesValidacion.corrigeCampos;
  }
}
