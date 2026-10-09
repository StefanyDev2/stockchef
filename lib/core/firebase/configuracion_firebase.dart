import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Región de las Cloud Functions; debe coincidir con functions/src/index.ts.
const regionFunciones = 'southamerica-east1';

/// Con `flutter run --dart-define=USAR_EMULADOR=true` la app usa el emulador
/// de Firebase del computador en lugar del proyecto real.
const usarEmulador = bool.fromEnvironment('USAR_EMULADOR');

/// Desde el emulador de Android, el computador se ve como 10.0.2.2.
/// En un celular real conectado por USB se usa la IP del computador:
/// `--dart-define=HOST_EMULADOR=192.168.x.x`.
const hostEmulador = String.fromEnvironment(
  'HOST_EMULADOR',
  defaultValue: '10.0.2.2',
);

final funcionesProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: regionFunciones),
);

/// Apunta Auth, Firestore y Functions al emulador. Se llama una sola vez,
/// después de `Firebase.initializeApp` y antes de usar cualquier servicio.
Future<void> conectarEmuladorSiCorresponde() async {
  if (!usarEmulador) return;
  await FirebaseAuth.instance.useAuthEmulator(hostEmulador, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(hostEmulador, 8080);
  FirebaseFunctions.instanceFor(
    region: regionFunciones,
  ).useFunctionsEmulator(hostEmulador, 5001);
}
