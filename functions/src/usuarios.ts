import type { Auth } from "firebase-admin/auth";
import type { DocumentData, Firestore, Transaction } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

/**
 * Mensajes de HU-003. Son los mismos de la app
 * (lib/features/usuarios/domain/mensajes_usuarios.dart).
 */
export const MENSAJES_USUARIOS = {
  sinPermiso: "Solo un administrador puede gestionar usuarios y roles.",
  usuarioNoEncontrado: "No se encontró el usuario.",
  rolInvalido: "Elige Administrador o Auxiliar de cocina.",
  ultimoAdministrador: "Debe haber al menos un administrador en el restaurante.",
  noPuedesDesactivarte: "No puedes desactivar tu propia cuenta.",
} as const;

/** Roles que el administrador puede asignar (CA3). No se vuelve a "sin rol". */
export type RolAsignable = "administrador" | "auxiliar_cocina";
const ROLES: readonly RolAsignable[] = ["administrador", "auxiliar_cocina"];

export interface UsuarioActualizado {
  uid: string;
  rol: string | null;
  activo: boolean;
}

function texto(entrada: unknown, campo: string): string | undefined {
  if (typeof entrada !== "object" || entrada === null) return undefined;
  const valor = (entrada as Record<string, unknown>)[campo];
  return typeof valor === "string" && valor.trim() !== "" ? valor : undefined;
}

function esAdministradorActivo(datos: DocumentData | undefined): boolean {
  return datos?.rol === "administrador" && datos?.activo === true;
}

/**
 * Revisa que quien llama sea un administrador activo y que el usuario a
 * cambiar sea de su mismo restaurante (CA9). Lee todo dentro de la
 * transacción para que nadie cambie roles a la vez sin que se note.
 */
async function leerAmbos(
  tx: Transaction,
  db: Firestore,
  quienLlama: string | undefined,
  uidObjetivo: string,
) {
  if (!quienLlama) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión");
  }
  const [admin, objetivo] = await Promise.all([
    tx.get(db.doc(`users/${quienLlama}`)),
    tx.get(db.doc(`users/${uidObjetivo}`)),
  ]);
  const datosAdmin = admin.data();
  if (!esAdministradorActivo(datosAdmin)) {
    throw new HttpsError("permission-denied", MENSAJES_USUARIOS.sinPermiso);
  }
  const datosObjetivo = objetivo.data();
  // Un usuario de otro restaurante se trata como inexistente, para no
  // revelar quién está registrado en otros restaurantes.
  if (!datosObjetivo || datosObjetivo.restaurantId !== datosAdmin!.restaurantId) {
    throw new HttpsError("not-found", MENSAJES_USUARIOS.usuarioNoEncontrado);
  }
  return { restaurantId: datosAdmin!.restaurantId as string, objetivo: datosObjetivo };
}

/**
 * CA5: si el cambio deja al usuario sin ser administrador activo, debe
 * quedar al menos otro administrador activo en el restaurante.
 */
async function exigirOtroAdministrador(
  tx: Transaction,
  db: Firestore,
  restaurantId: string,
  uidObjetivo: string,
): Promise<void> {
  const admins = await tx.get(
    db
      .collection("users")
      .where("restaurantId", "==", restaurantId)
      .where("rol", "==", "administrador")
      .where("activo", "==", true),
  );
  const otros = admins.docs.filter((doc) => doc.id !== uidObjetivo);
  if (otros.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      MENSAJES_USUARIOS.ultimoAdministrador,
    );
  }
}

/** HU-003, CA3: asigna o cambia el rol de un usuario del restaurante. */
export async function asignarRol(
  entrada: unknown,
  quienLlama: string | undefined,
  db: Firestore,
): Promise<UsuarioActualizado> {
  const uid = texto(entrada, "uid");
  const rol = texto(entrada, "rol") as RolAsignable | undefined;
  if (!uid) {
    throw new HttpsError("invalid-argument", MENSAJES_USUARIOS.usuarioNoEncontrado);
  }
  if (!rol || !ROLES.includes(rol)) {
    throw new HttpsError("invalid-argument", MENSAJES_USUARIOS.rolInvalido);
  }

  return db.runTransaction(async (tx) => {
    const { restaurantId, objetivo } = await leerAmbos(tx, db, quienLlama, uid);
    if (esAdministradorActivo(objetivo) && rol !== "administrador") {
      await exigirOtroAdministrador(tx, db, restaurantId, uid);
    }
    tx.update(db.doc(`users/${uid}`), { rol });
    return { uid, rol, activo: objetivo.activo === true };
  });
}

/**
 * HU-003, CA4: desactiva (o reactiva) a un usuario. Además de marcarlo en
 * Firestore, deshabilita la cuenta en Authentication y cierra sus sesiones,
 * así no entra aunque tenga la app abierta.
 */
export async function cambiarEstadoUsuario(
  entrada: unknown,
  quienLlama: string | undefined,
  db: Firestore,
  auth: Auth,
): Promise<UsuarioActualizado> {
  const uid = texto(entrada, "uid");
  const activo =
    typeof entrada === "object" && entrada !== null
      ? (entrada as Record<string, unknown>).activo
      : undefined;
  if (!uid || typeof activo !== "boolean") {
    throw new HttpsError("invalid-argument", MENSAJES_USUARIOS.usuarioNoEncontrado);
  }

  const resultado = await db.runTransaction(async (tx) => {
    const { restaurantId, objetivo } = await leerAmbos(tx, db, quienLlama, uid);
    if (!activo && esAdministradorActivo(objetivo)) {
      // Primero CA5, para que el único administrador vea ese mensaje.
      await exigirOtroAdministrador(tx, db, restaurantId, uid);
    }
    if (!activo && uid === quienLlama) {
      throw new HttpsError(
        "failed-precondition",
        MENSAJES_USUARIOS.noPuedesDesactivarte,
      );
    }
    tx.update(db.doc(`users/${uid}`), { activo });
    return { uid, rol: (objetivo.rol as string | null) ?? null, activo };
  });

  await auth.updateUser(uid, { disabled: !activo });
  if (!activo) await auth.revokeRefreshTokens(uid);
  return resultado;
}
