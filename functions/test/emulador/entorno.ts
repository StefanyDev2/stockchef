/**
 * Utilidades para las pruebas contra el emulador de Firebase. Se ejecutan con
 * `npm run test:todo`, que levanta los emuladores de Auth y Firestore.
 */
export const PROYECTO = "demo-stockchef";

export function exigirEmuladores(): void {
  for (const variable of [
    "FIRESTORE_EMULATOR_HOST",
    "FIREBASE_AUTH_EMULATOR_HOST",
  ]) {
    if (!process.env[variable]) {
      throw new Error(
        `Falta ${variable}. Ejecuta las pruebas con "npm run test:todo".`,
      );
    }
  }
}

/** Borra todos los usuarios y documentos de los emuladores. */
export async function limpiarEmuladores(): Promise<void> {
  const firestore = process.env.FIRESTORE_EMULATOR_HOST;
  const auth = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  await fetch(
    `http://${firestore}/emulator/v1/projects/${PROYECTO}/databases/(default)/documents`,
    { method: "DELETE" },
  );
  await fetch(`http://${auth}/emulator/v1/projects/${PROYECTO}/accounts`, {
    method: "DELETE",
  });
}
