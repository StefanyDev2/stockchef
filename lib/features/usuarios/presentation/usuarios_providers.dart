import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/configuracion_firebase.dart';
import '../../auth/domain/perfil_usuario.dart';
import '../data/usuarios_repositorio_firebase.dart';
import '../domain/usuarios.dart';

final usuariosRepositorioProvider = Provider<UsuariosRepositorio>(
  (ref) => UsuariosRepositorioFirebase(
    FirebaseFirestore.instance,
    ref.watch(funcionesProvider),
  ),
);

/// Usuarios del restaurante, actualizados en vivo (CA1).
final usuariosProvider = StreamProvider.autoDispose
    .family<List<PerfilUsuario>, String>(
      (ref, restaurantId) =>
          ref.watch(usuariosRepositorioProvider).usuariosDe(restaurantId),
    );
