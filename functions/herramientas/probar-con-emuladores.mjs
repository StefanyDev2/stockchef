// Corre todas las pruebas de las Cloud Functions con emuladores propios
// (proyecto demo-stockchef). Los emuladores de `npm run emuladores` deben
// estar apagados, porque usan los mismos puertos.
import { spawn } from "node:child_process";

import { entornoConJava21 } from "./entorno-java.mjs";

const pruebas = spawn(
  "firebase",
  [
    "emulators:exec",
    "--only",
    "auth,firestore",
    "--project",
    "demo-stockchef",
    '"npm test && npm run test:emulador"',
  ],
  { env: entornoConJava21(), stdio: "inherit", shell: true },
);
pruebas.on("exit", (codigo) => process.exit(codigo ?? 1));
