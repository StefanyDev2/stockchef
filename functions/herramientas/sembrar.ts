/**
 * Crea los usuarios de prueba de HU-001 y HU-002 en el EMULADOR de Firebase.
 * Nunca toca el proyecto real: se niega a correr si no apunta a 127.0.0.1.
 *
 * Uso, con los emuladores encendidos (`npm run emuladores`):
 *   npm run sembrar
 *
 * Todos usan la contraseña Cocina12 y el restaurante "Sabor Casero". También
 * crea insumos de prueba (HU-006). Lo que ya existe no se toca.
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
  { nombres: "Laura", apellidos: "Pérez", correo: "laura@correo.com", rol: "auxiliar_cocina", activo: true },
  { nombres: "Pedro", apellidos: "Díaz", correo: "pedro@correo.com", rol: "auxiliar_cocina", activo: false },
];

/** Insumos de prueba de "Sabor Casero" (HU-006). */
const INSUMOS = [
  { id: "tomate", nombre: "Tomate", unidad: "kilogramo", cantidadDisponible: 5, nivelMinimo: 10, estado: "bajo", activo: true },
  { id: "arroz", nombre: "Arroz", unidad: "kilogramo", cantidadDisponible: 25, nivelMinimo: 10, estado: "disponible", activo: true },
  { id: "pollo", nombre: "Pollo", unidad: "kilogramo", cantidadDisponible: 0, nivelMinimo: 5, estado: "agotado", activo: true },
  { id: "aceite", nombre: "Aceite", unidad: "litro", cantidadDisponible: 3, nivelMinimo: 2, estado: "disponible", activo: true },
  { id: "huevos", nombre: "Huevos", unidad: "unidad", cantidadDisponible: 30, nivelMinimo: 60, estado: "bajo", activo: true },
  { id: "cebolla", nombre: "Cebolla", unidad: "kilogramo", cantidadDisponible: 0, nivelMinimo: 3, estado: "agotado", activo: false },
];

async function main(): Promise<void> {
  initializeApp({ projectId: proyecto });
  const auth = getAuth();
  const db = getFirestore();

  let restaurantId = "";
  for (const usuario of USUARIOS) {
    const existente = await auth
      .getUserByEmail(usuario.correo)
      .catch(() => undefined);
    if (existente) {
      // Ya existe: no se toca, para no deshacer los cambios hechos en la app.
      restaurantId ||= (await db.doc(`users/${existente.uid}`).get()).data()
        ?.restaurantId;
      console.log(`· ${usuario.correo.padEnd(20)} ya existía`);
      continue;
    }
    const nuevo = await registrarUsuario(
      { ...usuario, restaurante: RESTAURANTE, contrasena: CONTRASENA },
      auth,
      db,
    );
    restaurantId ||= nuevo.restaurantId;
    // El rol de auxiliar y la desactivación se hacen en la app (HU-003);
    // aquí se fijan directamente para tener un usuario de cada caso.
    await db
      .doc(`users/${nuevo.uid}`)
      .update({ rol: usuario.rol, activo: usuario.activo });
    if (!usuario.activo) await auth.updateUser(nuevo.uid, { disabled: true });
    const estado = usuario.activo ? (usuario.rol ?? "sin rol") : "desactivado";
    console.log(`✔ ${usuario.correo.padEnd(20)} ${estado}`);
  }
  console.log(`\nContraseña de todos: ${CONTRASENA}\n`);

  // HU-006: insumos de prueba mientras no exista la historia de insumos.
  for (const insumo of INSUMOS) {
    const ref = db.doc(`restaurants/${restaurantId}/insumos/${insumo.id}`);
    if ((await ref.get()).exists) {
      console.log(`· insumo ${insumo.nombre.padEnd(12)} ya existía`);
      continue;
    }
    const { id: _, ...datos } = insumo;
    await ref.set(datos);
    console.log(
      `✔ insumo ${insumo.nombre.padEnd(12)} ${insumo.cantidadDisponible} ${insumo.unidad} (${insumo.activo ? insumo.estado : "inactivo"})`,
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
