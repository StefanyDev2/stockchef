import assert from "node:assert/strict";
import { after, before, beforeEach, describe, it } from "node:test";

import { deleteApp, initializeApp, type App } from "firebase-admin/app";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import {
  idBloqueo,
  registrarIngreso,
  registrarIntentoFallido,
} from "../../src/bloqueo";
import { exigirEmuladores, limpiarEmuladores, PROYECTO } from "./entorno";

const CORREO = "camila@correo.com";
const MINUTOS = 120;
const INICIO = new Date("2026-10-08T12:00:00Z");

/** `minutos` después de INICIO. */
function mas(minutos: number): Date {
  return new Date(INICIO.getTime() + minutos * 60_000);
}

let app: App;
let db: Firestore;

function fallo(ahora: Date, correo = CORREO) {
  return registrarIntentoFallido({ correo }, db, ahora, MINUTOS);
}

function ingreso(ahora: Date, correo = CORREO) {
  return registrarIngreso(correo, db, ahora, MINUTOS);
}

async function documento(correo = CORREO) {
  return (await db.doc(`loginLockouts/${idBloqueo(correo)}`).get()).data();
}

describe("bloqueo por intentos fallidos contra el emulador", () => {
  before(() => {
    exigirEmuladores();
    app = initializeApp({ projectId: PROYECTO }, "pruebas-bloqueo");
    db = getFirestore(app);
  });

  beforeEach(limpiarEmuladores);

  after(async () => {
    await limpiarEmuladores();
    await deleteApp(app);
  });

  it("CA8, CA9: el primer y el segundo fallo no bloquean", async () => {
    assert.equal((await fallo(INICIO)).bloqueado, false);
    assert.equal((await fallo(mas(1))).bloqueado, false);
    assert.equal((await documento())?.intentosFallidos, 2);
  });

  it("CA10: el tercer fallo seguido bloquea durante 2 horas", async () => {
    await fallo(INICIO);
    await fallo(mas(1));
    const tercero = await fallo(mas(2));

    assert.deepEqual(tercero, {
      bloqueado: true,
      bloqueadoHasta: mas(2 + MINUTOS).toISOString(),
      minutosBloqueo: MINUTOS,
    });
  });

  it("CA11: bloqueado, la contraseña correcta tampoco deja entrar", async () => {
    for (const minuto of [0, 1, 2]) await fallo(mas(minuto));

    const correcto = await ingreso(mas(30));

    assert.equal(correcto.bloqueado, true);
    assert.equal(correcto.bloqueadoHasta, mas(2 + MINUTOS).toISOString());
  });

  it("CA11: fallar durante el bloqueo no lo alarga", async () => {
    for (const minuto of [0, 1, 2]) await fallo(mas(minuto));

    const durante = await fallo(mas(60));

    assert.equal(durante.bloqueadoHasta, mas(2 + MINUTOS).toISOString());
  });

  it("CA12: pasado el bloqueo deja entrar y el contador vuelve a cero", async () => {
    for (const minuto of [0, 1, 2]) await fallo(mas(minuto));

    const despues = await ingreso(mas(2 + MINUTOS));

    assert.equal(despues.bloqueado, false);
    assert.equal(await documento(), undefined);
  });

  it("CA12: pasado el bloqueo, un nuevo fallo cuenta desde uno", async () => {
    for (const minuto of [0, 1, 2]) await fallo(mas(minuto));

    const nuevo = await fallo(mas(3 + MINUTOS));

    assert.equal(nuevo.bloqueado, false);
    assert.equal((await documento())?.intentosFallidos, 1);
  });

  it("un ingreso correcto reinicia el contador (los fallos deben ser seguidos)", async () => {
    await fallo(INICIO);
    await fallo(mas(1));
    await ingreso(mas(2));

    assert.equal((await fallo(mas(3))).bloqueado, false);
    assert.equal((await documento())?.intentosFallidos, 1);
  });

  it("cada correo lleva su propio contador, sin importar mayúsculas", async () => {
    await fallo(INICIO, " CAMILA@Correo.com ");
    await fallo(mas(1), "camila@correo.com");
    await fallo(mas(2), "andres@correo.com");

    assert.equal((await documento())?.intentosFallidos, 2);
    assert.equal((await documento("andres@correo.com"))?.intentosFallidos, 1);
  });

  it("rechaza llamadas sin correo o sin sesión", async () => {
    for (const entrada of [{}, { correo: "  " }, null]) {
      await assert.rejects(
        registrarIntentoFallido(entrada, db, INICIO, MINUTOS),
        (error) => error instanceof HttpsError && error.code === "invalid-argument",
      );
    }
    await assert.rejects(
      registrarIngreso(undefined, db, INICIO, MINUTOS),
      (error) => error instanceof HttpsError && error.code === "unauthenticated",
    );
  });
});
