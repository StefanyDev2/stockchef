import { Timestamp, type Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { normalizarCorreo } from "./normalizacion";

/** Intentos fallidos consecutivos que bloquean la cuenta (HU-002, CA10). */
export const MAXIMO_INTENTOS = 3;

/**
 * Duración del bloqueo en minutos: 120 (2 horas) por defecto. Para probar
 * sin esperar, en el emulador se puede poner `BLOQUEO_MINUTOS=1` en
 * `functions/.env.local`.
 */
export function minutosBloqueo(): number {
  const valor = Number(process.env.BLOQUEO_MINUTOS);
  return Number.isInteger(valor) && valor > 0 ? valor : 120;
}

/** Lo que la app necesita saber después de cada intento. */
export interface EstadoBloqueo {
  bloqueado: boolean;
  /** Fecha ISO hasta la que dura el bloqueo, o null. */
  bloqueadoHasta: string | null;
  minutosBloqueo: number;
}

/**
 * Id del documento en `loginLockouts`: el correo normalizado, codificado
 * para que no tenga "/" (no se permite en los ids de Firestore).
 */
export function idBloqueo(correo: string): string {
  return encodeURIComponent(normalizarCorreo(correo));
}

function coleccion(db: Firestore) {
  return db.collection("loginLockouts");
}

function estado(hasta: Date | null, minutos: number): EstadoBloqueo {
  return {
    bloqueado: hasta !== null,
    bloqueadoHasta: hasta?.toISOString() ?? null,
    minutosBloqueo: minutos,
  };
}

/**
 * La app la llama cuando Firebase Authentication rechaza el correo o la
 * contraseña (CA8). Suma un intento y, al tercero seguido, bloquea la
 * cuenta (CA10). Si un bloqueo anterior ya venció, empieza de cero (CA12).
 *
 * Responde igual exista o no el correo, para no revelar qué cuentas existen.
 */
export async function registrarIntentoFallido(
  entrada: unknown,
  db: Firestore,
  ahora = new Date(),
  minutos = minutosBloqueo(),
): Promise<EstadoBloqueo> {
  const correo =
    typeof entrada === "object" && entrada !== null
      ? (entrada as Record<string, unknown>).correo
      : undefined;
  if (typeof correo !== "string" || normalizarCorreo(correo) === "") {
    throw new HttpsError("invalid-argument", "Falta el correo");
  }

  const ref = coleccion(db).doc(idBloqueo(correo));
  return db.runTransaction(async (tx) => {
    const datos = (await tx.get(ref)).data();
    const hastaActual = (datos?.bloqueadoHasta as Timestamp | null)?.toDate();

    // Mientras dure el bloqueo no se suman intentos (CA11).
    if (hastaActual && hastaActual > ahora) {
      return estado(hastaActual, minutos);
    }

    const anteriores = hastaActual ? 0 : Number(datos?.intentosFallidos ?? 0);
    const intentos = anteriores + 1;
    const hasta =
      intentos >= MAXIMO_INTENTOS
        ? new Date(ahora.getTime() + minutos * 60_000)
        : null;

    tx.set(ref, {
      intentosFallidos: intentos,
      bloqueadoHasta: hasta ? Timestamp.fromDate(hasta) : null,
    });
    return estado(hasta, minutos);
  });
}

/**
 * La app la llama después de que Firebase Authentication aceptó la
 * contraseña. Si la cuenta está bloqueada responde `bloqueado` y la app
 * cierra la sesión (CA11). Si no, reinicia el contador (CA12).
 */
export async function registrarIngreso(
  correo: string | undefined,
  db: Firestore,
  ahora = new Date(),
  minutos = minutosBloqueo(),
): Promise<EstadoBloqueo> {
  if (!correo) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión");
  }

  const ref = coleccion(db).doc(idBloqueo(correo));
  return db.runTransaction(async (tx) => {
    const datos = (await tx.get(ref)).data();
    const hasta = (datos?.bloqueadoHasta as Timestamp | null)?.toDate();
    if (hasta && hasta > ahora) {
      return estado(hasta, minutos);
    }
    if (datos) tx.delete(ref);
    return estado(null, minutos);
  });
}
