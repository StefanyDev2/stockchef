import '../../auth/domain/perfil_usuario.dart';

/// Una opción de la pantalla principal. Sin `ruta`, todavía no está
/// construida y muestra "próximamente".
class FuncionDelRol {
  const FuncionDelRol(this.nombre, {this.ruta});

  final String nombre;
  final String? ruta;
}

// Rutas de las funciones ya construidas. Son las mismas de `Rutas`; se
// repiten aquí para que el dominio no dependa de las rutas.

/// Pantalla de usuarios (HU-003).
const rutaUsuarios = '/inicio/usuarios';

/// Registro de compras (HU-006 y HU-007).
const rutaCompras = '/inicio/compras';

/// Insumos críticos (HU-004).
const rutaInsumos = '/inicio/insumos';

/// Funciones que ve cada rol en su pantalla principal (HU-002, CA6 y CA7).
/// "Usuarios" (HU-003) e "Insumos" (HU-004) solo las ve el administrador; el
/// auxiliar registra compras desde "Registrar compra" (HU-007).
List<FuncionDelRol> funcionesDe(Rol rol) => switch (rol) {
  Rol.administrador => const [
    FuncionDelRol('Compras', ruta: rutaCompras),
    FuncionDelRol('Insumos', ruta: rutaInsumos),
    FuncionDelRol('Menú'),
    FuncionDelRol('Reportes'),
    FuncionDelRol('Usuarios', ruta: rutaUsuarios),
  ],
  Rol.auxiliarCocina => const [
    FuncionDelRol('Registrar compra', ruta: rutaCompras),
    FuncionDelRol('Consumo del día'),
    FuncionDelRol('Pérdidas'),
    FuncionDelRol('Platos vendidos'),
    FuncionDelRol('Menú del día'),
  ],
  Rol.sinRol => const [],
};
