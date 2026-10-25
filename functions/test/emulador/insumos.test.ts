import assert from "node:assert/strict";
import { after, before, beforeEach, describe, it } from "node:test";

import { deleteApp, initializeApp, type App } from "firebase-admin/app";
import { getAuth, type Auth } from "firebase-admin/auth";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { guardarInsumosCriticos, MENSAJES_INSUMOS } from "../../src/insumos";
import { registrarUsuario } from "../../src/registro";
import { asignarRol, cambiarEstadoUsuario } from "../../src/usuarios";
import { exigirEmuladores, limpiarEmuladores, PROYECTO } from "./entorno";

let app: App;
let auth: Auth;
let db: Firestore;

let camila: string; // administradora de Sabor Casero
let daniela: string; // auxiliar
let otro: string; // administrador de otro restaurante
let restaurantId: string;

async function registrar(nombres: string, restaurante = "Sabor Casero") {
  return registrarUsuario(
    {
      nombres,
      apellidos: "Prueba",
      correo: `${nombres.toLowerCase()}@correo.com`,
      restaurante,
      contrasena: "Cocina12",
    },
    auth,
    db,
  );
}

async function criticos(rid = restaurantId): Promise<string[]> {
  const docs = (await db.collection(`restaurants/${rid}/insumos`).get()).docs;
  return docs
    .filter((d) => d.data().critico === true)
    .map((d) => d.id)
    .sort();
}

async function esperarError(promesa: Promise<unknown>, codigo: string, mensaje?: string) {
  await assert.rejects(promesa, (error) => {
    assert.ok(error instanceof HttpsError, `error inesperado: ${error}`);
    assert.equal(error.code, codigo);
    if (mensaje) assert.equal(error.message, mensaje);
    return true;
  });
}

describe("guardarInsumosCriticos contra el emulador (HU-004)", () => {
  before(() => {
    exigirEmuladores();
    app = initializeApp({ projectId: PROYECTO }, "pruebas-insumos");
    auth = getAuth(app);
    db = getFirestore(app);
  });

  beforeEach(async () => {
    await limpiarEmuladores();
    const admin = await registrar("Camila");
    camila = admin.uid;
    restaurantId = admin.restaurantId;
    daniela = (await registrar("Daniela")).uid;
    await asignarRol({ uid: daniela, rol: "auxiliar_cocina" }, camila, db);
    otro = (await registrar("Otro", "La Peña")).uid;
    for (const [id, datos] of Object.entries({
      tomate: { critico: true },
      arroz: {},
      pollo: {},
      cebolla: { activo: false },
    })) {
      await db
        .doc(`restaurants/${restaurantId}/insumos/${id}`)
        .set({ nombre: id, activo: true, ...datos });
    }
  });

  after(async () => {
    await limpiarEmuladores();
    await deleteApp(app);
  });

  it("CA3, CA5: marca y quita críticos según la lista enviada", async () => {
    const r = await guardarInsumosCriticos({ criticos: ["arroz", "pollo"] }, camila, db);

    assert.deepEqual(r, { criticos: 2, total: 4 });
    assert.deepEqual(await criticos(), ["arroz", "pollo"]);
    const tomate = (await db.doc(`restaurants/${restaurantId}/insumos/tomate`).get()).data();
    assert.equal(tomate?.critico, false, "se le quitó la clasificación");
  });

  it("un insumo inactivo también se puede marcar", async () => {
    await guardarInsumosCriticos({ criticos: ["cebolla"] }, camila, db);
    assert.deepEqual(await criticos(), ["cebolla"]);
  });

  it("una lista vacía deja todos como no críticos", async () => {
    await guardarInsumosCriticos({ criticos: [] }, camila, db);
    assert.deepEqual(await criticos(), []);
  });

  it("no cambia los demás datos del insumo", async () => {
    await guardarInsumosCriticos({ criticos: ["arroz"] }, camila, db);
    const arroz = (await db.doc(`restaurants/${restaurantId}/insumos/arroz`).get()).data();
    assert.deepEqual(arroz, { nombre: "arroz", activo: true, critico: true });
  });

  it("rechaza una lista mal formada o con insumos que no existen", async () => {
    for (const entrada of [{}, { criticos: "tomate" }, { criticos: [3] }, null]) {
      await esperarError(
        guardarInsumosCriticos(entrada, camila, db),
        "invalid-argument",
        MENSAJES_INSUMOS.listaInvalida,
      );
    }
    await esperarError(
      guardarInsumosCriticos({ criticos: ["tomate", "no-existe"] }, camila, db),
      "failed-precondition",
      MENSAJES_INSUMOS.insumoDesconocido,
    );
    assert.deepEqual(await criticos(), ["tomate"], "no se cambió nada");
  });

  describe("solo el administrador activo de su restaurante", () => {
    it("el auxiliar de cocina no puede", async () => {
      await esperarError(
        guardarInsumosCriticos({ criticos: [] }, daniela, db),
        "permission-denied",
        MENSAJES_INSUMOS.sinPermiso,
      );
      assert.deepEqual(await criticos(), ["tomate"]);
    });

    it("un administrador desactivado tampoco", async () => {
      await asignarRol({ uid: daniela, rol: "administrador" }, camila, db);
      await cambiarEstadoUsuario({ uid: camila, activo: false }, daniela, db, auth);
      await esperarError(guardarInsumosCriticos({ criticos: [] }, camila, db), "permission-denied");
    });

    it("el administrador de otro restaurante no toca estos insumos", async () => {
      await esperarError(
        guardarInsumosCriticos({ criticos: ["tomate"] }, otro, db),
        "failed-precondition",
      );
      assert.deepEqual(await criticos(), ["tomate"]);
    });

    it("sin sesión no hace nada", async () => {
      await esperarError(guardarInsumosCriticos({ criticos: [] }, undefined, db), "unauthenticated");
    });
  });
});
