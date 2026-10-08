/// Normalizaciones compartidas por el registro y el inicio de sesión.
///
/// La Cloud Function de registro aplica las mismas reglas; si se cambian
/// aquí, hay que cambiarlas también en `functions/src/normalizacion.ts`.
library;

const _sinTilde = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', //
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e', //
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i', //
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', //
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', //
};

final _espacios = RegExp(r'\s+');

/// Correo sin espacios alrededor y en minúsculas.
String normalizarCorreo(String correo) => correo.trim().toLowerCase();

/// Nombre del restaurante en minúsculas, sin tildes y con los espacios
/// recortados y reducidos a uno solo. Sirve para saber si el restaurante ya
/// existe: "  Sabor  Casero " y "sabor cásero" dan "sabor casero".
///
/// La "ñ" se conserva para no confundir, por ejemplo, "La Peña" con "La Pena".
String normalizarNombreRestaurante(String nombre) {
  final minusculas = nombre.trim().toLowerCase().replaceAll(_espacios, ' ');
  return minusculas.split('').map((c) => _sinTilde[c] ?? c).join();
}

/// Nombre tal como se guarda para mostrar: solo recorta y une espacios.
String limpiarTexto(String texto) => texto.trim().replaceAll(_espacios, ' ');
