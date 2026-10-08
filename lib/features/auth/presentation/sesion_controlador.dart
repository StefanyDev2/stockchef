import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/configuracion_firebase.dart';
import '../data/sesion_repositorio_firebase.dart';
import '../domain/inicio_sesion.dart';
import '../domain/perfil_usuario.dart';

final sesionRepositorioProvider = Provider<SesionRepositorio>(
  (ref) => SesionRepositorioFirebase(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    ref.watch(funcionesProvider),
  ),
);

final sesionProvider = NotifierProvider<SesionControlador, EstadoSesion>(
  SesionControlador.new,
);

/// Si hay alguien con la sesión iniciada. Las rutas se deciden con esto.
sealed class EstadoSesion {
  const EstadoSesion();
}

/// Al abrir la app, mientras se revisa si quedó una sesión guardada.
final class SesionCargando extends EstadoSesion {
  const SesionCargando();
}

final class SinSesion extends EstadoSesion {
  const SinSesion();
}

final class ConSesion extends EstadoSesion {
  const ConSesion(this.perfil);

  final PerfilUsuario perfil;
}

class SesionControlador extends Notifier<EstadoSesion> {
  @override
  EstadoSesion build() {
    _recuperar();
    return const SesionCargando();
  }

  /// CA13: si la app se cerró con la sesión abierta, se entra directo.
  Future<void> _recuperar() async {
    final perfil = await ref.read(sesionRepositorioProvider).sesionGuardada();
    if (state is SesionCargando) {
      state = perfil == null ? const SinSesion() : ConSesion(perfil);
    }
  }

  /// Lo llama el inicio de sesión cuando el ingreso fue aceptado.
  void iniciada(PerfilUsuario perfil) => state = ConSesion(perfil);

  /// CA13: "Cerrar sesión".
  Future<void> cerrar() async {
    await ref.read(sesionRepositorioProvider).cerrarSesion();
    state = const SinSesion();
  }
}
