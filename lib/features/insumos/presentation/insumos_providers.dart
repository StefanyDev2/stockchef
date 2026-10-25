import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/configuracion_firebase.dart';
import '../data/insumos_repositorio_firebase.dart';
import '../domain/insumos.dart';

final insumosRepositorioProvider = Provider<InsumosRepositorio>(
  (ref) => InsumosRepositorioFirebase(
    FirebaseFirestore.instance,
    ref.watch(funcionesProvider),
  ),
);

/// CA1: todos los insumos del restaurante, actualizados en vivo.
final insumosRegistradosProvider = StreamProvider.autoDispose
    .family<List<InsumoRegistrado>, String>(
      (ref, restaurantId) =>
          ref.watch(insumosRepositorioProvider).insumosDe(restaurantId),
    );
