import assert from "node:assert/strict";
import { after, before, beforeEach, describe, it } from "node:test";

import { deleteApp, initializeApp, type App } from "firebase-admin/app";
import { getAuth, type Auth } from "firebase-admin/auth";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { MENSAJES_COMPRAS, registrarCompra } from "../../src/compras";
import { registrarUsuario } from "../../src/registro";
import { asignarRol, cambiarEstadoUsuario } from "../../src/usuarios";
import { exigirEmuladores, limpiarEmuladores, PROYECTO } from "./entorno";

let app: App;
let auth: Auth;
let db: Firestore;

let camila: string; // administradora
let daniela: string; // auxiliar
let andres: string; // sin rol
let restaurantId: string;

async function registrar(nombres: string): Promise<{ uid: string; restaurantId: string }> {
  return registrarUsuario(
    {
      nombres,
      apellidos: "Ruiz",
      correo: `${nombres.toLowerCase()}@correo.com`,
      restaurante: "Sabor Casero",
      contrasena: "Cocina12",
    },
    auth,
    db,
  );
}

function insumo(id: string) {
  return db.doc(`restaurants/${restaurantId}/insumos/${id}`);
}

async function crearInsumo(id: string, datos: Record<string, unknown>) {
  await insumo(id).set({
    nombre: id,
    unidad: "kilogramo",
    cantidadDisponible: 5,
    nivelMinimo: 10,
    estado: "bajo",
    activo: true,
    ...datos,
  });
}

const TOMATE = {
  insumoId: "tomate",
  cantidad: 10,
  unidad: "kilogramo",
  proveedor: "Distrialimentos",
  precioTotal: 50000,
  tipo: "planeada",
};

async function esperarError(
  promesa: Promise<unknown>,
  codigo: string,
  mensaje?: string,
): Promise<HttpsError> {
  let capturado: HttpsError | undefined;
  await assert.rejects(promesa, (error) => {
    assert.ok(error instanceof HttpsError, `error inesperado: ${error}`);
    assert.equal(error.code, codigo);
    if (mensaje) assert.equal(error.message, mensaje);
    capturado = error;
    return true;
  });
  return capturado!;
}

async function compras() {
  return (await db.collection(`restaurants/${restaurantId}/compras`).get()).docs;
}

describe("registrarCompra contra el emulador", () => {
  before(() => {
    exigirEmuladores();
    app = initializeApp({ projectId: PROYECTO }, "pruebas-compras");
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
    andres = (await registrar("Andres")).uid;
    await crearInsumo("tomate", {});
  });

  after(async () => {
    await limpiarEmuladores();
    await deleteApp(app);
  });

  it("CA7, CA8, CA9, CA11: guarda la compra y suma al insumo", async () => {
    const resultado = await registrarCompra(TOMATE, camila, db);

    assert.deepEqual(
      { ...resultado, compraId: undefined },
      {
        compraId: undefined,
        insumoNombre: "tomate",
        cantidad: 10,
        unidad: "kilogramo",
        precioTotal: 50000,
        precioUnitario: 5000,
        cantidadDisponible: 15,
        unidadInsumo: "kilogramo",
        estado: "disponible",
      },
    );

    const [compra] = await compras();
    const datos = compra.data();
    assert.equal(datos.registradoPor, camila);
    assert.equal(datos.registradoPorNombre, "Camila Ruiz");
    assert.ok(datos.fecha, "fecha y hora del servidor");
    assert.equal(datos.proveedor, "Distrialimentos");
    assert.equal(datos.tipo, "planeada");
    assert.equal(datos.precioUnitario, 5000);
    assert.equal(datos.cantidadDisponibleDespues, 15);

    const actualizado = (await insumo("tomate").get()).data()!;
    assert.equal(actualizado.cantidadDisponible, 15);
  });

  it("CA10: pasa a disponible solo si supera el nivel mínimo", async () => {
    const poco = await registrarCompra({ ...TOMATE, cantidad: 2 }, camila, db);
    assert.equal(poco.cantidadDisponible, 7);
    assert.equal(poco.estado, "bajo", "7 kg no supera el mínimo de 10");

    const justo = await registrarCompra({ ...TOMATE, cantidad: 3 }, camila, db);
    assert.equal(justo.cantidadDisponible, 10);
    assert.equal(justo.estado, "bajo", "igualar el mínimo no lo supera");

    const supera = await registrarCompra({ ...TOMATE, cantidad: 0.5 }, camila, db);
    assert.equal(supera.estado, "disponible");
  });

  it("el proveedor es opcional y la compra puede ser de emergencia", async () => {
    await registrarCompra(
      { ...TOMATE, proveedor: "   ", tipo: "emergencia" },
      camila,
      db,
    );
    const datos = (await compras())[0].data();
    assert.equal(datos.proveedor, null);
    assert.equal(datos.tipo, "emergencia");
  });

  describe("conversión de unidades", () => {
    it("gramos y libras se convierten a kilogramos", async () => {
      await registrarCompra({ ...TOMATE, cantidad: 500, unidad: "gramo" }, camila, db);
      const libras = await registrarCompra(
        { ...TOMATE, cantidad: 2, unidad: "libra", precioTotal: 9000 },
        camila,
        db,
      );
      // 5 + 0,5 + 0,907184
      assert.equal(libras.cantidadDisponible, 6.4072);
      assert.equal(libras.precioUnitario, 4500, "precio por libra, como se compró");
    });

    it("mililitros a litros", async () => {
      await crearInsumo("aceite", { unidad: "litro", cantidadDisponible: 1, nivelMinimo: 2 });
      const r = await registrarCompra(
        { ...TOMATE, insumoId: "aceite", cantidad: 1500, unidad: "mililitro" },
        camila,
        db,
      );
      assert.equal(r.cantidadDisponible, 2.5);
      assert.equal(r.estado, "disponible");
    });

    it("no deja sumar kilogramos a un insumo en litros", async () => {
      await crearInsumo("aceite", { unidad: "litro" });
      await esperarError(
        registrarCompra({ ...TOMATE, insumoId: "aceite" }, camila, db),
        "failed-precondition",
        MENSAJES_COMPRAS.unidadIncompatible("litro"),
      );
      assert.equal((await compras()).length, 0);
    });
  });

  describe("validaciones (CA2, CA5, CA6)", () => {
    it("CA5: dice cuáles campos obligatorios faltan", async () => {
      const error = await esperarError(
        registrarCompra({ proveedor: "X" }, camila, db),
        "invalid-argument",
        MENSAJES_COMPRAS.camposPendientes,
      );
      assert.deepEqual(error.details, {
        pendientes: ["insumo", "cantidad", "unidad", "precio", "tipo"],
      });
    });

    it("CA6: cantidad y precio deben ser números mayores a cero", async () => {
      for (const malo of [
        { cantidad: 0 },
        { cantidad: -1 },
        { precioTotal: 0 },
        { precioTotal: "50000" },
        { cantidad: Number.NaN },
      ]) {
        await esperarError(
          registrarCompra({ ...TOMATE, ...malo }, camila, db),
          "invalid-argument",
          MENSAJES_COMPRAS.valoresInvalidos,
        );
      }
      assert.equal((await compras()).length, 0);
    });

    it("CA3: un insumo inactivo o inexistente no se puede comprar", async () => {
      await crearInsumo("cebolla", { activo: false });
      for (const insumoId of ["cebolla", "no-existe"]) {
        await esperarError(
          registrarCompra({ ...TOMATE, insumoId }, camila, db),
          "failed-precondition",
          MENSAJES_COMPRAS.insumoNoDisponible,
        );
      }
    });

    it("una unidad que no está en la lista se rechaza", async () => {
      await esperarError(
        registrarCompra({ ...TOMATE, unidad: "bulto" }, camila, db),
        "invalid-argument",
      );
    });
  });

  describe("HU-007, CA3: el tipo de compra es obligatorio", () => {
    it("sin tipo o con un tipo desconocido no se guarda", async () => {
      for (const tipo of [undefined, "", "urgente"]) {
        const error = await esperarError(
          registrarCompra({ ...TOMATE, tipo }, camila, db),
          "invalid-argument",
          MENSAJES_COMPRAS.camposPendientes,
        );
        assert.deepEqual(error.details, { pendientes: ["tipo"] });
      }
      assert.equal((await compras()).length, 0);
    });
  });

  describe("quién registra compras (HU-006 y HU-007)", () => {
    it("HU-007, CA1: el auxiliar de cocina registra compras", async () => {
      const r = await registrarCompra({ ...TOMATE, tipo: "emergencia" }, daniela, db);
      assert.equal(r.cantidadDisponible, 15);
      const datos = (await compras())[0].data();
      assert.equal(datos.registradoPor, daniela);
      assert.equal(datos.tipo, "emergencia");
    });

    it("un usuario sin rol no puede registrar compras", async () => {
      await esperarError(
        registrarCompra(TOMATE, andres, db),
        "permission-denied",
        MENSAJES_COMPRAS.sinPermiso,
      );
      assert.equal((await compras()).length, 0);
      assert.equal((await insumo("tomate").get()).data()!.cantidadDisponible, 5);
    });

    it("un auxiliar desactivado tampoco", async () => {
      await cambiarEstadoUsuario({ uid: daniela, activo: false }, camila, db, auth);
      await esperarError(registrarCompra(TOMATE, daniela, db), "permission-denied");
    });

    it("un administrador desactivado tampoco", async () => {
      await asignarRol({ uid: daniela, rol: "administrador" }, camila, db);
      await cambiarEstadoUsuario({ uid: camila, activo: false }, daniela, db, auth);
      await esperarError(registrarCompra(TOMATE, camila, db), "permission-denied");
    });

    it("sin sesión no hace nada", async () => {
      await esperarError(registrarCompra(TOMATE, undefined, db), "unauthenticated");
    });
  });

  it("compras simultáneas del mismo insumo suman todas", async () => {
    await Promise.all(
      Array.from({ length: 5 }, () =>
        registrarCompra({ ...TOMATE, cantidad: 1 }, camila, db),
      ),
    );
    assert.equal((await insumo("tomate").get()).data()!.cantidadDisponible, 10);
    assert.equal((await compras()).length, 5);
  });
});
