import '../../auth/domain/perfil_usuario.dart';

/// Una opción de la pantalla principal. Sin `ruta`, todavía no está
/// construida y muestra "próximamente".
class FuncionDelRol {
  const FuncionDelRol(this.nombre, {this.ruta});

  final String nombre;
  final String? ruta;
}

/// Ruta de la pantalla de usuarios (HU-003). Es la misma de `Rutas.usuarios`;
/// se repite aquí para que el dominio no dependa de las rutas.
const rutaUsuarios = '/inicio/usuarios';

/// Funciones que ve cada rol en su pantalla principal (HU-002, CA6 y CA7).
/// "Usuarios" solo la ve el administrador (HU-003, CA8).
List<FuncionDelRol> funcionesDe(Rol rol) => switch (rol) {
  Rol.administrador => const [
    FuncionDelRol('Compras'),
    FuncionDelRol('Insumos'),
    FuncionDelRol('Menú'),
    FuncionDelRol('Reportes'),
    FuncionDelRol('Usuarios', ruta: rutaUsuarios),
  ],
  Rol.auxiliarCocina => const [
    FuncionDelRol('Consumo del día'),
    FuncionDelRol('Pérdidas'),
    FuncionDelRol('Platos vendidos'),
    FuncionDelRol('Menú del día'),
  ],
  Rol.sinRol => const [],
};
