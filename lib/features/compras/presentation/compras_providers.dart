import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/configuracion_firebase.dart';
import '../data/compras_repositorio_firebase.dart';
import '../domain/compras.dart';

final comprasRepositorioProvider = Provider<ComprasRepositorio>(
  (ref) => ComprasRepositorioFirebase(
    FirebaseFirestore.instance,
    ref.watch(funcionesProvider),
  ),
);

/// CA3: insumos activos del restaurante.
final insumosActivosProvider = StreamProvider.autoDispose
    .family<List<Insumo>, String>(
      (ref, restaurantId) =>
          ref.watch(comprasRepositorioProvider).insumosActivos(restaurantId),
    );

/// Historial de compras del restaurante.
final comprasProvider = StreamProvider.autoDispose.family<List<Compra>, String>(
  (ref, restaurantId) =>
      ref.watch(comprasRepositorioProvider).compras(restaurantId),
);
