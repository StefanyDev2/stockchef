import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { after, before, beforeEach, describe, it } from "node:test";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setLogLevel,
  setDoc,
  updateDoc,
  where,
} from "firebase/firestore";

import { exigirEmuladores, PROYECTO } from "./entorno";

// Las denegaciones esperadas no se muestran como errores en la salida.
setLogLevel("silent");

// lib/test/emulador -> raíz del repositorio
const REGLAS = join(__dirname, "..", "..", "..", "..", "firestore.rules");

const SABOR = "restaurante-sabor";
const OTRO = "restaurante-otro";

let entorno: RulesTestEnvironment;

function perfil(restaurantId: string, rol: string | null, activo = true) {
  return {
    nombres: "Nombre",
    apellidos: "Apellido",
    correo: "persona@correo.com",
    restaurantId,
    rol,
    activo,
  };
}

/** Firestore como lo ve la app con la sesión de `uid` (o sin sesión). */
function como(uid?: string) {
  return (
    uid ? entorno.authenticatedContext(uid) : entorno.unauthenticatedContext()
  ).firestore();
}

describe("reglas de Firestore", () => {
  before(async () => {
    exigirEmuladores();
    const [host, puerto] = process.env.FIRESTORE_EMULATOR_HOST!.split(":");
    entorno = await initializeTestEnvironment({
      projectId: PROYECTO,
      firestore: { rules: readFileSync(REGLAS, "utf8"), host, port: Number(puerto) },
    });
  });

  beforeEach(async () => {
    await entorno.clearFirestore();
    await entorno.withSecurityRulesDisabled(async (contexto) => {
      const db = contexto.firestore();
      await setDoc(doc(db, "users/admin"), perfil(SABOR, "administrador"));
      await setDoc(doc(db, "users/auxiliar"), perfil(SABOR, "auxiliar_cocina"));
      await setDoc(doc(db, "users/sinRol"), perfil(SABOR, null));
      await setDoc(doc(db, "users/adminInactivo"), perfil(SABOR, "administrador", false));
      await setDoc(doc(db, "users/adminOtro"), perfil(OTRO, "administrador"));
      await setDoc(doc(db, `restaurants/${SABOR}`), { nombre: "Sabor Casero" });
      await setDoc(doc(db, "loginLockouts/camila@correo,com"), { intentosFallidos: 1 });
    });
  });

  after(async () => {
    await entorno.cleanup();
  });

  describe("users", () => {
    it("sin sesión no se lee nada", async () => {
      await assertFails(getDoc(doc(como(), "users/admin")));
    });

    it("cada usuario lee su propio perfil", async () => {
      await assertSucceeds(getDoc(doc(como("sinRol"), "users/sinRol")));
      await assertSucceeds(getDoc(doc(como("auxiliar"), "users/auxiliar")));
    });

    it("un usuario que no es administrador no lee perfiles ajenos", async () => {
      await assertFails(getDoc(doc(como("auxiliar"), "users/sinRol")));
      await assertFails(getDoc(doc(como("sinRol"), "users/admin")));
    });

    it("el administrador lee los perfiles de su restaurante", async () => {
      await assertSucceeds(getDoc(doc(como("admin"), "users/sinRol")));
    });

    it("el administrador no lee perfiles de otro restaurante", async () => {
      await assertFails(getDoc(doc(como("adminOtro"), "users/sinRol")));
    });

    it("un administrador desactivado no lee perfiles ajenos", async () => {
      await assertFails(getDoc(doc(como("adminInactivo"), "users/sinRol")));
    });

    it("nadie crea su perfil desde la app, ni como administrador", async () => {
      await assertFails(
        setDoc(doc(como("nuevo"), "users/nuevo"), perfil(SABOR, "administrador")),
      );
      await assertFails(setDoc(doc(como("nuevo"), "users/nuevo"), perfil(SABOR, null)));
    });

    it("nadie cambia su propio rol, activo ni restaurante", async () => {
      const db = como("sinRol");
      await assertFails(updateDoc(doc(db, "users/sinRol"), { rol: "administrador" }));
      await assertFails(updateDoc(doc(db, "users/sinRol"), { activo: false }));
      await assertFails(updateDoc(doc(db, "users/sinRol"), { restaurantId: OTRO }));
    });

    it("nadie borra perfiles desde la app", async () => {
      await assertFails(deleteDoc(doc(como("admin"), "users/sinRol")));
    });
  });

  describe("lista de usuarios del restaurante (HU-003)", () => {
    const usuariosDe = (uid: string | undefined, restaurantId: string) =>
      getDocs(
        query(
          collection(como(uid), "users"),
          where("restaurantId", "==", restaurantId),
        ),
      );

    it("CA1: el administrador consulta la lista de su restaurante", async () => {
      const lista = await assertSucceeds(usuariosDe("admin", SABOR));
      assert.equal(lista.size, 4);
    });

    it("CA9: un auxiliar o un usuario sin rol no pueden consultar la lista", async () => {
      await assertFails(usuariosDe("auxiliar", SABOR));
      await assertFails(usuariosDe("sinRol", SABOR));
    });

    it("CA9: un administrador desactivado tampoco", async () => {
      await assertFails(usuariosDe("adminInactivo", SABOR));
    });

    it("un administrador no consulta la lista de otro restaurante", async () => {
      await assertFails(usuariosDe("adminOtro", SABOR));
    });

    it("sin filtrar por restaurante no se puede leer toda la colección", async () => {
      await assertFails(getDocs(collection(como("admin"), "users")));
    });

    it("CA9: ni el administrador cambia roles desde la app (lo hace la función)", async () => {
      await assertFails(updateDoc(doc(como("admin"), "users/sinRol"), { rol: "auxiliar_cocina" }));
      await assertFails(updateDoc(doc(como("admin"), "users/auxiliar"), { activo: false }));
    });
  });

  describe("restaurants", () => {
    it("los usuarios del restaurante lo leen, incluso sin rol", async () => {
      await assertSucceeds(getDoc(doc(como("admin"), `restaurants/${SABOR}`)));
      await assertSucceeds(getDoc(doc(como("sinRol"), `restaurants/${SABOR}`)));
    });

    it("usuarios de otro restaurante o sin sesión no lo leen", async () => {
      await assertFails(getDoc(doc(como("adminOtro"), `restaurants/${SABOR}`)));
      await assertFails(getDoc(doc(como(), `restaurants/${SABOR}`)));
    });

    it("nadie crea ni modifica restaurantes desde la app", async () => {
      await assertFails(setDoc(doc(como("admin"), "restaurants/nuevo"), { nombre: "X" }));
      await assertFails(updateDoc(doc(como("admin"), `restaurants/${SABOR}`), { nombre: "X" }));
    });
  });

  describe("loginLockouts", () => {
    it("ni con sesión ni sin ella se lee o escribe desde la app", async () => {
      const ruta = "loginLockouts/camila@correo,com";
      await assertFails(getDoc(doc(como(), ruta)));
      await assertFails(setDoc(doc(como(), ruta), { intentosFallidos: 0 }));
      await assertFails(getDoc(doc(como("admin"), ruta)));
      await assertFails(setDoc(doc(como("admin"), ruta), { intentosFallidos: 0 }));
    });
  });

  it("otras colecciones están cerradas", async () => {
    await assertFails(getDoc(doc(como("admin"), "compras/x")));
    await assertFails(setDoc(doc(como("admin"), "compras/x"), { a: 1 }));
  });
});
