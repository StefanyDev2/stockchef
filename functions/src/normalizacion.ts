/**
 * Mismas reglas que lib/features/auth/domain/normalizacion.dart.
 * Si se cambian aquí, hay que cambiarlas también allá.
 */
import { createHash } from "node:crypto";

const SIN_TILDE: Record<string, string> = {
  á: "a", à: "a", ä: "a", â: "a",
  é: "e", è: "e", ë: "e", ê: "e",
  í: "i", ì: "i", ï: "i", î: "i",
  ó: "o", ò: "o", ö: "o", ô: "o",
  ú: "u", ù: "u", ü: "u", û: "u",
};

const ESPACIOS = /\s+/g;

export function normalizarCorreo(correo: string): string {
  return correo.trim().toLowerCase();
}

/** Minúsculas, sin tildes y espacios unificados. Conserva la ñ. */
export function normalizarNombreRestaurante(nombre: string): string {
  const minusculas = nombre.trim().toLowerCase().replace(ESPACIOS, " ");
  return Array.from(minusculas, (c) => SIN_TILDE[c] ?? c).join("");
}

export function limpiarTexto(texto: string): string {
  return texto.trim().replace(ESPACIOS, " ");
}

/**
 * Id del documento del restaurante, derivado del nombre normalizado.
 * Al ser determinista, dos registros simultáneos con el mismo nombre
 * apuntan al mismo documento y la transacción decide quién es el primero.
 */
export function idRestaurante(nombreNormalizado: string): string {
  return createHash("sha256").update(nombreNormalizado, "utf8").digest("hex");
}
