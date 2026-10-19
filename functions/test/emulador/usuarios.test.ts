import assert from "node:assert/strict";
import { after, before, beforeEach, describe, it } from "node:test";

import { deleteApp, initializeApp, type App } from "firebase-admin/app";
import { getAuth, type Auth } from "firebase-admin/auth";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { registrarUsuario } from "../../src/registro";
import {
  asignarRol,
  cambiarEstadoUsuario,
  MENSAJES_USUARIOS,
} from "../../src/usuarios";
import { exigirEmuladores, limpiarEmuladores, PROYECTO } from "./entorno";

let app: App;
let auth: Auth;
let db: Firestore;

/** uid de cada persona de prueba, creados en beforeEach. */
let camila: string; // administradora de Sabor Casero
let andres: string; // sin rol, Sabor Casero
let daniela: string; // auxiliar, Sabor Casero
let otroAdmin: string; // administrador de La Peña

async function registrar(nombres: string, restaurante: string): Promise<string> {
  const { uid } = await registrarUsuario(
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
  return uid;
}

async function perfil(uid: string) {
  return (await db.doc(`users/${uid}`).get()).data()!;
}

async function esperarError(
  promesa: Promise<unknown>,
  codigo: string,
  mensaje?: string,
): Promise<void> {
  await assert.rejects(promesa, (error) => {
    assert.ok(error instanceof HttpsError, `error inesperado: ${error}`);
    assert.equal(error.code, codigo);
    if (mensaje) assert.equal(error.message, mensaje);
    return true;
  });
}

describe("asignarRol y cambiarEstadoUsuario contra el emulador", () => {
  before(() => {
    exigirEmuladores();
    app = initializeApp({ projectId: PROYECTO }, "pruebas-usuarios");
    auth = getAuth(app);
    db = getFirestore(app);
  });

  beforeEach(async () => {
    await limpiarEmuladores();
    camila = await registrar("Camila", "Sabor Casero");
    andres = await registrar("Andres", "Sabor Casero");
    daniela = await registrar("Daniela", "Sabor Casero");
    otroAdmin = await registrar("Otro", "La Peña");
    await asignarRol({ uid: daniela, rol: "auxiliar_cocina" }, camila, db);
  });

  after(async () => {
    await limpiarEmuladores();
    await deleteApp(app);
  });

  describe("CA3: asignar o cambiar el rol", () => {
    it("el administrador asigna auxiliar a un usuario sin rol", async () => {
      const resultado = await asignarRol(
        { uid: andres, rol: "auxiliar_cocina" },
        camila,
        db,
      );

      assert.deepEqual(resultado, { uid: andres, rol: "auxiliar_cocina", activo: true });
      assert.equal((await perfil(andres)).rol, "auxiliar_cocina");
    });

    it("el administrador puede nombrar a otro administrador", async () => {
      await asignarRol({ uid: daniela, rol: "administrador" }, camila, db);
      assert.equal((await perfil(daniela)).rol, "administrador");
    });

    it("solo acepta Administrador o Auxiliar de cocina", async () => {
      for (const rol of [null, "", "sin_rol", "superadmin", 3]) {
        await esperarError(
          asignarRol({ uid: andres, rol }, camila, db),
          "invalid-argument",
          MENSAJES_USUARIOS.rolInvalido,
        );
      }
      assert.equal((await perfil(andres)).rol, null);
    });
  });

  describe("CA5: siempre queda al menos un administrador", () => {
    it("no deja quitarle el rol al único administrador, ni a sí mismo", async () => {
      await esperarError(
        asignarRol({ uid: camila, rol: "auxiliar_cocina" }, camila, db),
        "failed-precondition",
        MENSAJES_USUARIOS.ultimoAdministrador,
      );
      assert.equal((await perfil(camila)).rol, "administrador");
    });

    it("con otro administrador, sí se puede cambiar", async () => {
      await asignarRol({ uid: daniela, rol: "administrador" }, camila, db);

      await asignarRol({ uid: camila, rol: "auxiliar_cocina" }, daniela, db);

      assert.equal((await perfil(camila)).rol, "auxiliar_cocina");
    });

    it("un administrador desactivado no cuenta como el otro administrador", async () => {
      await asignarRol({ uid: daniela, rol: "administrador" }, camila, db);
      await cambiarEstadoUsuario({ uid: daniela, activo: false }, camila, db, auth);

      await esperarError(
        asignarRol({ uid: camila, rol: "auxiliar_cocina" }, camila, db),
        "failed-precondition",
        MENSAJES_USUARIOS.ultimoAdministrador,
      );
    });

    it("dos administradores quitándose el rol a la vez dejan uno", async () => {
      await asignarRol({ uid: daniela, rol: "administrador" }, camila, db);

      const intentos = await Promise.allSettled([
        asignarRol({ uid: daniela, rol: "auxiliar_cocina" }, camila, db),
        asignarRol({ uid: camila, rol: "auxiliar_cocina" }, daniela, db),
      ]);

      const roles = [(await perfil(camila)).rol, (await perfil(daniela)).rol];
      assert.equal(roles.filter((r) => r === "administrador").length, 1);
      assert.equal(intentos.filter((i) => i.status === "rejected").length, 1);
    });
  });

  describe("CA4: desactivar y reactivar", () => {
    it("el administrador desactiva a otro administrador si queda uno", async () => {
      await asignarRol({ uid: daniela, rol: "administrador" }, camila, db);

      await cambiarEstadoUsuario({ uid: daniela, activo: false }, camila, db, auth);

      assert.equal((await perfil(daniela)).activo, false);
    });

    it("desactiva en Firestore y deshabilita la cuenta en Authentication", async () => {
      const resultado = await cambiarEstadoUsuario(
        { uid: daniela, activo: false },
        camila,
        db,
        auth,
      );

      assert.deepEqual(resultado, { uid: daniela, rol: "auxiliar_cocina", activo: false });
      assert.equal((await perfil(daniela)).activo, false);
      assert.equal((await auth.getUser(daniela)).disabled, true);
    });

    it("reactivar devuelve el acceso", async () => {
      await cambiarEstadoUsuario({ uid: daniela, activo: false }, camila, db, auth);

      await cambiarEstadoUsuario({ uid: daniela, activo: true }, camila, db, auth);

      assert.equal((await perfil(daniela)).activo, true);
      assert.equal((await auth.getUser(daniela)).disabled, false);
    });

    it("CA5: el único administrador no se puede desactivar", async () => {
      await esperarError(
        cambiarEstadoUsuario({ uid: camila, activo: false }, camila, db, auth),
        "failed-precondition",
        MENSAJES_USUARIOS.ultimoAdministrador,
      );
      assert.equal((await perfil(camila)).activo, true);
      assert.equal((await auth.getUser(camila)).disabled, false);
    });

    it("con otro administrador, tampoco puede desactivar su propia cuenta", async () => {
      await asignarRol({ uid: daniela, rol: "administrador" }, camila, db);

      await esperarError(
        cambiarEstadoUsuario({ uid: camila, activo: false }, camila, db, auth),
        "failed-precondition",
        MENSAJES_USUARIOS.noPuedesDesactivarte,
      );
    });
  });

  describe("CA9: solo un administrador activo y de su restaurante", () => {
    it("un auxiliar no puede cambiar roles ni desactivar", async () => {
      await esperarError(
        asignarRol({ uid: andres, rol: "administrador" }, daniela, db),
        "permission-denied",
        MENSAJES_USUARIOS.sinPermiso,
      );
      await esperarError(
        cambiarEstadoUsuario({ uid: camila, activo: false }, daniela, db, auth),
        "permission-denied",
      );
      assert.equal((await perfil(andres)).rol, null);
      assert.equal((await perfil(camila)).activo, true);
    });

    it("un usuario sin rol no puede darse el rol de administrador", async () => {
      await esperarError(
        asignarRol({ uid: andres, rol: "administrador" }, andres, db),
        "permission-denied",
      );
    });

    it("un administrador desactivado ya no puede hacer cambios", async () => {
      await asignarRol({ uid: daniela, rol: "administrador" }, camila, db);
      await cambiarEstadoUsuario({ uid: camila, activo: false }, daniela, db, auth);

      await esperarError(
        asignarRol({ uid: andres, rol: "auxiliar_cocina" }, camila, db),
        "permission-denied",
      );
    });

    it("un administrador no ve ni cambia usuarios de otro restaurante", async () => {
      await esperarError(
        asignarRol({ uid: andres, rol: "administrador" }, otroAdmin, db),
        "not-found",
      );
      await esperarError(
        cambiarEstadoUsuario({ uid: camila, activo: false }, otroAdmin, db, auth),
        "not-found",
      );
    });

    it("sin sesión no hace nada", async () => {
      await esperarError(
        asignarRol({ uid: andres, rol: "auxiliar_cocina" }, undefined, db),
        "unauthenticated",
      );
    });
  });
});
