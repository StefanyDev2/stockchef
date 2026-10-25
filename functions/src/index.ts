import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { onCall } from "firebase-functions/v2/https";

import {
  registrarIngreso as ingreso,
  registrarIntentoFallido as intentoFallido,
} from "./bloqueo";
import { registrarCompra as compra } from "./compras";
import { guardarInsumosCriticos as guardarCriticos } from "./insumos";
import { registrarUsuario as registrar } from "./registro";
import {
  asignarRol as asignar,
  cambiarEstadoUsuario as cambiarEstado,
} from "./usuarios";

/** Misma región de la base de datos Firestore. La app usa este valor. */
export const REGION = "southamerica-east1";

initializeApp();
setGlobalOptions({ region: REGION, maxInstances: 10 });

/** HU-001: registro de usuario. No requiere sesión iniciada. */
export const registrarUsuario = onCall((request) =>
  registrar(request.data, getAuth(), getFirestore()),
);

/** HU-002: suma un intento fallido de inicio de sesión. Sin sesión. */
export const registrarIntentoFallido = onCall((request) =>
  intentoFallido(request.data, getFirestore()),
);

/** HU-002: confirma que la cuenta no está bloqueada y reinicia el contador. */
export const registrarIngreso = onCall((request) =>
  ingreso(request.auth?.token.email, getFirestore()),
);

/** HU-003: el administrador asigna o cambia el rol de un usuario. */
export const asignarRol = onCall((request) =>
  asignar(request.data, request.auth?.uid, getFirestore()),
);

/** HU-003: el administrador desactiva o reactiva a un usuario. */
export const cambiarEstadoUsuario = onCall((request) =>
  cambiarEstado(request.data, request.auth?.uid, getFirestore(), getAuth()),
);

/** HU-006 y HU-007: el administrador o el auxiliar registran una compra. */
export const registrarCompra = onCall((request) =>
  compra(request.data, request.auth?.uid, getFirestore()),
);

/** HU-004: el administrador guarda la lista de insumos críticos. */
export const guardarInsumosCriticos = onCall((request) =>
  guardarCriticos(request.data, request.auth?.uid, getFirestore()),
);
