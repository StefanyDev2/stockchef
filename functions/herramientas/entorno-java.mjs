// Entorno para los emuladores de Firebase, que necesitan Java 21 o más.
// En Windows se usa el que trae Android Studio, solo para el proceso que se
// lanza: no cambia el JAVA_HOME del sistema, que otros proyectos pueden
// necesitar (por ejemplo, Java 8).
import { existsSync } from "node:fs";
import { join } from "node:path";

export function entornoConJava21() {
  const entorno = { ...process.env };
  const jbr = join("C:", "Program Files", "Android", "Android Studio", "jbr");
  if (process.platform === "win32" && existsSync(jbr)) {
    entorno.JAVA_HOME = jbr;
    // En Windows la variable puede llamarse Path o PATH; se usa la que exista.
    const clave =
      Object.keys(entorno).find((k) => k.toUpperCase() === "PATH") ?? "Path";
    entorno[clave] = `${join(jbr, "bin")};${entorno[clave] ?? ""}`;
  }
  return entorno;
}
