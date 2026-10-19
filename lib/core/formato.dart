import 'package:intl/intl.dart';

/// Formatos de números y fechas en español de Colombia.
abstract final class Formato {
  // En es_CO, intl pone el símbolo después ("50.000 $"); en Colombia se
  // escribe antes, así que se arma a mano.
  static final _miles = NumberFormat('#,##0', 'es_CO');
  static final _numero = NumberFormat.decimalPattern('es_CO')
    ..maximumFractionDigits = 2;
  // Los datos de fechas en español los carga MaterialApp (locale 'es').
  static final _fecha = DateFormat('d MMM y, h:mm a', 'es');

  /// 50000 → "$50.000".
  static String pesos(num valor) => '\$${_miles.format(valor)}';

  /// 6.4072 → "6,41"; 10 → "10".
  static String numero(num valor) => _numero.format(valor);

  static String fecha(DateTime fecha) => _fecha.format(fecha.toLocal());
}
