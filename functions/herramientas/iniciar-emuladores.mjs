// Enciende los emuladores de Firebase (Auth, Firestore y Functions) y guarda
// sus datos en .emulador-datos/ cada 2 minutos y al cerrarlos con Ctrl+C.
// La próxima vez los vuelve a cargar, así los datos de prueba no se pierden.
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { join, resolve } from "node:path";

import { entornoConJava21 } from "./entorno-java.mjs";

const raiz = resolve(import.meta.dirname, "..", "..");
const datos = join(raiz, ".emulador-datos");

const args = ["emulators:start", "--only", "auth,firestore,functions"];
if (existsSync(join(datos, "firebase-export-metadata.json"))) {
  args.push("--import", datos);
}
args.push("--export-on-exit", datos);

const entorno = entornoConJava21();

const firebase = spawn("firebase", args, {
  cwd: raiz,
  env: entorno,
  stdio: "inherit",
  shell: true,
});

// Guarda también cada 2 minutos, por si el computador se apaga o el
// emulador se cierra sin Ctrl+C. Si falla (por ejemplo, mientras arranca),
// se intenta en la siguiente vuelta.
const guardado = setInterval(() => {
  spawn("firebase", ["emulators:export", datos, "--force"], {
    cwd: raiz,
    env: entorno,
    stdio: "ignore",
    shell: true,
  }).on("error", () => {});
}, 2 * 60_000);

firebase.on("exit", (codigo) => {
  clearInterval(guardado);
  process.exit(codigo ?? 0);
});
