import type { Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

/**
 * Mensajes de HU-004. Son los mismos de la app
 * (lib/features/insumos/domain/insumos.dart).
 */
export const MENSAJES_INSUMOS = {
  sinPermiso: "Solo el administrador define los insumos críticos.",
  listaInvalida: "La lista de insumos críticos no es válida.",
  insumoDesconocido: "Uno de los insumos ya no existe. Vuelve a abrir la lista.",
} as const;

export interface CriticosGuardados {
  criticos: number;
  total: number;
}

/**
 * HU-004: guarda la lista de insumos críticos del restaurante (CA5).
 * Recibe los ids de todos los insumos que deben quedar como críticos; los
 * demás quedan como no críticos. Solo un administrador activo puede hacerlo,
 * y todo se actualiza en una sola transacción.
 */
export async function guardarInsumosCriticos(
  entrada: unknown,
  quienLlama: string | undefined,
  db: Firestore,
): Promise<CriticosGuardados> {
  if (!quienLlama) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión");
  }
  const lista =
    typeof entrada === "object" && entrada !== null
      ? (entrada as Record<string, unknown>).criticos
      : undefined;
  if (!Array.isArray(lista) || !lista.every((id) => typeof id === "string")) {
    throw new HttpsError("invalid-argument", MENSAJES_INSUMOS.listaInvalida);
  }
  const criticos = new Set(lista as string[]);

  return db.runTransaction(async (tx) => {
    const usuario = (await tx.get(db.doc(`users/${quienLlama}`))).data();
    if (usuario?.rol !== "administrador" || usuario?.activo !== true) {
      throw new HttpsError("permission-denied", MENSAJES_INSUMOS.sinPermiso);
    }

    const insumos = await tx.get(
      db.collection(`restaurants/${usuario.restaurantId}/insumos`),
    );
    const existentes = new Set(insumos.docs.map((doc) => doc.id));
    if ([...criticos].some((id) => !existentes.has(id))) {
      throw new HttpsError("failed-precondition", MENSAJES_INSUMOS.insumoDesconocido);
    }

    for (const doc of insumos.docs) {
      const critico = criticos.has(doc.id);
      if (doc.data().critico !== critico) tx.update(doc.ref, { critico });
    }
    return { criticos: criticos.size, total: insumos.size };
  });
}
