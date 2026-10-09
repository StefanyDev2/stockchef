/**
 * Crea los usuarios de prueba de HU-001 y HU-002 en el EMULADOR de Firebase.
 * Nunca toca el proyecto real: se niega a correr si no apunta a 127.0.0.1.
 *
 * Uso, con los emuladores encendidos (`npm run emuladores`):
 *   npm run sembrar
 *
 * Todos usan la contraseña Cocina12 y el restaurante "Sabor Casero".
 */
import { readFileSync } from "node:fs";
import { join } from "node:path";

import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

import { registrarUsuario } from "../src/registro";

process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";
for (const host of [
  process.env.FIRESTORE_EMULATOR_HOST,
  process.env.FIREBASE_AUTH_EMULATOR_HOST,
]) {
  if (!/^(127\.0\.0\.1|localhost):\d+$/.test(host)) {
    throw new Error(`Solo se siembra el emulador local, no ${host}`);
  }
}

// lib/herramientas -> raíz del repositorio
const raiz = join(__dirname, "..", "..", "..");
const proyecto = JSON.parse(readFileSync(join(raiz, ".firebaserc"), "utf8"))
  .projects.default as string;

const CONTRASENA = "Cocina12";
const RESTAURANTE = "Sabor Casero";

interface Prueba {
  nombres: string;
  apellidos: string;
  correo: string;
  rol: "administrador" | "auxiliar_cocina" | null;
  activo: boolean;
}

// Camila va primero: al crear el restaurante queda como administradora.
const USUARIOS: Prueba[] = [
  { nombres: "Camila", apellidos: "Ruiz", correo: "camila@correo.com", rol: "administrador", activo: true },
  { nombres: "Daniela", apellidos: "Torres", correo: "daniela@correo.com", rol: "auxiliar_cocina", activo: true },
  { nombres: "Andrés", apellidos: "Gómez", correo: "andres@correo.com", rol: null, activo: true },
  { nombres: "Pedro", apellidos: "Díaz", correo: "pedro@correo.com", rol: "auxiliar_cocina", activo: false },
];

async function main(): Promise<void> {
  initializeApp({ projectId: proyecto });
  const auth = getAuth();
  const db = getFirestore();

  for (const usuario of USUARIOS) {
    let uid: string;
    try {
      uid = (await auth.getUserByEmail(usuario.correo)).uid;
    } catch {
      uid = (
        await registrarUsuario(
          { ...usuario, restaurante: RESTAURANTE, contrasena: CONTRASENA },
          auth,
          db,
        )
      ).uid;
    }
    // El rol de auxiliar y la desactivación los hará HU-003; aquí se fijan
    // directamente para tener un usuario de cada caso.
    await db.doc(`users/${uid}`).update({ rol: usuario.rol, activo: usuario.activo });
    const estado = usuario.activo ? (usuario.rol ?? "sin rol") : "desactivado";
    console.log(`✔ ${usuario.correo.padEnd(20)} ${estado}`);
  }
  console.log(`\nContraseña de todos: ${CONTRASENA}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
