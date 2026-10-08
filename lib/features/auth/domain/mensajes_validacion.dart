/// Mensajes de validación de HU-001, tal como aparecen en el prototipo.
abstract final class MensajesValidacion {
  static const campoObligatorio = 'Campo obligatorio';
  static const correoInvalido = 'Ingresa un correo válido';
  static const correoRegistrado = 'Este correo ya está registrado';
  static const contrasenaDebil =
      'Mínimo 8 caracteres, con mayúscula, minúscula y número';
  static const contrasenasNoCoinciden = 'Las contraseñas no coinciden';

  /// Ayuda que se muestra bajo el campo de contraseña antes de validar.
  static const ayudaContrasena =
      'Mín. 8 caracteres, 1 mayúscula, 1 minúscula y 1 número';

  /// Aviso superior cuando faltan campos (pantalla E1).
  static const completaCampos = 'Completa los campos obligatorios';

  /// Aviso superior cuando hay datos no válidos (pantalla E2).
  static const corrigeCampos = 'Corrige los campos marcados';
}
