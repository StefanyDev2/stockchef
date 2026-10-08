import 'mensajes_validacion.dart';

/// Validaciones de campo en Dart puro. Cada función devuelve el mensaje de
/// error que se muestra bajo el campo, o `null` si el valor es válido.
abstract final class Validaciones {
  /// Correo con usuario, "@", dominio y una extensión de 2 letras o más.
  /// No admite espacios, puntos al inicio o al final del usuario, ni puntos
  /// seguidos.
  static final _correo = RegExp(
    r'^[A-Za-z0-9_%+\-]+(\.[A-Za-z0-9_%+\-]+)*'
    r'@[A-Za-z0-9](?:[A-Za-z0-9\-]*[A-Za-z0-9])?'
    r'(\.[A-Za-z0-9](?:[A-Za-z0-9\-]*[A-Za-z0-9])?)*'
    r'\.[A-Za-z]{2,}$',
  );
  static final _mayuscula = RegExp(r'\p{Lu}', unicode: true);
  static final _minuscula = RegExp(r'\p{Ll}', unicode: true);
  static final _numero = RegExp(r'\d');

  static const longitudMinimaContrasena = 8;

  /// CA2, CA3: el campo no puede quedar vacío ni con solo espacios.
  static String? obligatorio(String? valor) =>
      (valor == null || valor.trim().isEmpty)
      ? MensajesValidacion.campoObligatorio
      : null;

  /// CA4: formato de correo electrónico.
  static String? correo(String? valor) {
    final vacio = obligatorio(valor);
    if (vacio != null) return vacio;
    return _correo.hasMatch(valor!.trim())
        ? null
        : MensajesValidacion.correoInvalido;
  }

  /// CA6: mínimo 8 caracteres, una mayúscula, una minúscula y un número.
  static String? contrasena(String? valor) {
    if (valor == null || valor.isEmpty) {
      return MensajesValidacion.campoObligatorio;
    }
    final cumple =
        valor.runes.length >= longitudMinimaContrasena &&
        _mayuscula.hasMatch(valor) &&
        _minuscula.hasMatch(valor) &&
        _numero.hasMatch(valor);
    return cumple ? null : MensajesValidacion.contrasenaDebil;
  }

  /// CA7: la confirmación debe ser igual a la contraseña.
  static String? confirmacion(String? contrasena, String? confirmacion) {
    if (confirmacion == null || confirmacion.isEmpty) {
      return MensajesValidacion.campoObligatorio;
    }
    return contrasena == confirmacion
        ? null
        : MensajesValidacion.contrasenasNoCoinciden;
  }
}
