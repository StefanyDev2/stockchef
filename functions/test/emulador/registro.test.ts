import assert from "node:assert/strict";
import { after, before, beforeEach, describe, it } from "node:test";

import { deleteApp, initializeApp, type App } from "firebase-admin/app";
import { getAuth, type Auth } from "firebase-admin/auth";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { MENSAJES } from "../../src/mensajes";
import { registrarUsuario } from "../../src/registro";
import { exigirEmuladores, limpiarEmuladores, PROYECTO } from "./entorno";

const CAMILA = {
  nombres: "Camila",
  apellidos: "Ruiz",
  correo: "camila@correo.com",
  restaurante: "Sabor Casero",
  contrasena: "Cocina12",
};
const ANDRES = { ...CAMILA, nombres: "Andrés", correo: "andres@correo.com" };

let app: App;
let auth: Auth;
let db: Firestore;

async function esperarError(promesa: Promise<unknown>): Promise<HttpsError> {
  try {
    await promesa;
  } catch (error) {
    assert.ok(error instanceof HttpsError, `error inesperado: ${error}`);
    return error;
  }
  assert.fail("se esperaba un error");
}

async function contar(coleccion: string): Promise<number> {
  return (await db.collection(coleccion).count().get()).data().count;
}

describe("registrarUsuario contra el emulador", () => {
  before(() => {
    exigirEmuladores();
    app = initializeApp({ projectId: PROYECTO }, "pruebas-registro");
    auth = getAuth(app);
    db = getFirestore(app);
  });

  beforeEach(limpiarEmuladores);

  after(async () => {
    await limpiarEmuladores();
    await deleteApp(app);
  });

  it("CA9, CA10: el primero crea cuenta y restaurante, y queda administrador", async () => {
    const resultado = await registrarUsuario(CAMILA, auth, db);

    assert.equal(resultado.rol, "administrador");

    const cuenta = await auth.getUser(resultado.uid);
    assert.equal(cuenta.email, "camila@correo.com");
    assert.equal(cuenta.displayName, "Camila Ruiz");

    const usuario = (await db.doc(`users/${resultado.uid}`).get()).data();
    assert.ok(usuario?.creadoEn, "creadoEn debe existir");
    const { creadoEn: _, ...resto } = usuario;
    assert.deepEqual(resto, {
      nombres: "Camila",
      apellidos: "Ruiz",
      correo: "camila@correo.com",
      restaurantId: resultado.restaurantId,
      rol: "administrador",
      activo: true,
    });

    const restaurante = (
      await db.doc(`restaurants/${resultado.restaurantId}`).get()
    ).data();
    assert.equal(restaurante?.nombre, "Sabor Casero");
    assert.equal(restaurante?.nombreNormalizado, "sabor casero");
    assert.equal(restaurante?.creadoPor, resultado.uid);
  });

  it("CA10: el segundo del mismo restaurante (escrito distinto) queda sin rol", async () => {
    const primero = await registrarUsuario(CAMILA, auth, db);
    const segundo = await registrarUsuario(
      { ...ANDRES, restaurante: "  sábor  CASERO " },
      auth,
      db,
    );

    assert.equal(segundo.rol, null);
    assert.equal(segundo.restaurantId, primero.restaurantId);
    assert.equal(await contar("restaurants"), 1);

    const restaurante = (
      await db.doc(`restaurants/${primero.restaurantId}`).get()
    ).data();
    assert.equal(restaurante?.nombre, "Sabor Casero", "conserva el nombre del primero");
    assert.equal(restaurante?.creadoPor, primero.uid);
  });

  it("CA10: registros simultáneos del mismo restaurante dejan un solo administrador", async () => {
    const personas = Array.from({ length: 5 }, (_, i) => ({
      ...CAMILA,
      correo: `persona${i}@correo.com`,
    }));

    const resultados = await Promise.all(
      personas.map((p) => registrarUsuario(p, auth, db)),
    );

    assert.equal(resultados.filter((r) => r.rol === "administrador").length, 1);
    assert.equal(resultados.filter((r) => r.rol === null).length, 4);
    assert.equal(await contar("restaurants"), 1);
  });

  it("un restaurante distinto crea otro restaurante con su propio administrador", async () => {
    await registrarUsuario(CAMILA, auth, db);
    const otro = await registrarUsuario(
      { ...ANDRES, restaurante: "La Peña" },
      auth,
      db,
    );

    assert.equal(otro.rol, "administrador");
    assert.equal(await contar("restaurants"), 2);
  });

  it("CA5: un correo ya registrado (sin importar mayúsculas) se rechaza", async () => {
    await registrarUsuario(CAMILA, auth, db);

    const error = await esperarError(
      registrarUsuario({ ...ANDRES, correo: " CAMILA@correo.com " }, auth, db),
    );

    assert.equal(error.code, "already-exists");
    assert.deepEqual(error.details, {
      errores: { correo: MENSAJES.correoRegistrado },
    });
    assert.equal(await contar("users"), 1);
  });

  it("CA2, CA6: datos no válidos no crean nada y devuelven errores por campo", async () => {
    const error = await esperarError(
      registrarUsuario({ ...CAMILA, nombres: "", contrasena: "cocina" }, auth, db),
    );

    assert.equal(error.code, "invalid-argument");
    assert.deepEqual(error.details, {
      errores: {
        nombres: MENSAJES.campoObligatorio,
        contrasena: MENSAJES.contrasenaDebil,
      },
    });
    assert.equal((await auth.listUsers()).users.length, 0);
    assert.equal(await contar("users"), 0);
    assert.equal(await contar("restaurants"), 0);
  });
});
