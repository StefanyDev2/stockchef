import type { Auth } from "firebase-admin/auth";
import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { MENSAJES } from "./mensajes";
import { idRestaurante } from "./normalizacion";
import { validarRegistro } from "./validaciones";

export type Rol = "administrador" | "auxiliar_cocina" | null;

export interface ResultadoRegistro {
  uid: string;
  restaurantId: string;
  rol: Rol;
}

/**
 * Registra un usuario (HU-001).
 *
 * 1. Valida los datos (CA2, CA4, CA6). Si algo falla responde
 *    `invalid-argument` con `details.errores` por campo.
 * 2. Crea la cuenta en Firebase Authentication. Si el correo ya existe
 *    responde `already-exists` (CA5).
 * 3. En una transacción crea el restaurante si no existe y el documento del
 *    usuario: administrador si creó el restaurante, sin rol si se unió a uno
 *    existente (CA10).
 * 4. Si la transacción falla, borra la cuenta recién creada para no dejar
 *    usuarios a medias.
 */
export async function registrarUsuario(
  entrada: unknown,
  auth: Auth,
  db: Firestore,
): Promise<ResultadoRegistro> {
  const validacion = validarRegistro(entrada);
  if (!validacion.ok) {
    throw new HttpsError("invalid-argument", "Datos de registro no válidos", {
      errores: validacion.errores,
    });
  }
  const datos = validacion.datos;

  let uid: string;
  try {
    const usuario = await auth.createUser({
      email: datos.correo,
      password: datos.contrasena,
      displayName: `${datos.nombres} ${datos.apellidos}`,
    });
    uid = usuario.uid;
  } catch (error) {
    if (codigoDe(error) === "auth/email-already-exists") {
      throw new HttpsError("already-exists", MENSAJES.correoRegistrado, {
        errores: { correo: MENSAJES.correoRegistrado },
      });
    }
    if (codigoDe(error) === "auth/invalid-email") {
      throw new HttpsError("invalid-argument", MENSAJES.correoInvalido, {
        errores: { correo: MENSAJES.correoInvalido },
      });
    }
    throw new HttpsError("internal", MENSAJES.errorInterno);
  }

  const restaurantId = idRestaurante(datos.restauranteNormalizado);
  try {
    const rol = await db.runTransaction(async (tx) => {
      const restauranteRef = db.collection("restaurants").doc(restaurantId);
      const restaurante = await tx.get(restauranteRef);
      const esNuevo = !restaurante.exists;

      if (esNuevo) {
        tx.create(restauranteRef, {
          nombre: datos.restaurante,
          nombreNormalizado: datos.restauranteNormalizado,
          creadoPor: uid,
          creadoEn: FieldValue.serverTimestamp(),
        });
      }

      const rolAsignado: Rol = esNuevo ? "administrador" : null;
      tx.create(db.collection("users").doc(uid), {
        nombres: datos.nombres,
        apellidos: datos.apellidos,
        correo: datos.correo,
        restaurantId,
        rol: rolAsignado,
        activo: true,
        creadoEn: FieldValue.serverTimestamp(),
      });
      return rolAsignado;
    });
    return { uid, restaurantId, rol };
  } catch {
    await auth.deleteUser(uid).catch(() => undefined);
    throw new HttpsError("internal", MENSAJES.errorInterno);
  }
}

function codigoDe(error: unknown): string | undefined {
  if (typeof error === "object" && error !== null && "code" in error) {
    const codigo = (error as { code: unknown }).code;
    return typeof codigo === "string" ? codigo : undefined;
  }
  return undefined;
}
