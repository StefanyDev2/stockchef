import '../../auth/domain/perfil_usuario.dart';

/// Funciones que ve cada rol en su pantalla principal (HU-002, CA6 y CA7).
/// En el Sprint 1 solo se muestran; cada una se construye en su historia.
List<String> funcionesDe(Rol rol) => switch (rol) {
  Rol.administrador => const [
    'Compras',
    'Insumos',
    'Menú',
    'Reportes',
    'Usuarios',
  ],
  Rol.auxiliarCocina => const [
    'Consumo del día',
    'Pérdidas',
    'Platos vendidos',
    'Menú del día',
  ],
  Rol.sinRol => const [],
};
