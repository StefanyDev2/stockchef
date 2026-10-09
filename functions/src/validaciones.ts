/**
 * Validación en el servidor de los datos de registro. Repite las reglas de
 * la app (lib/features/auth/domain/validaciones.dart) porque nunca se
 * confía en lo que envía el cliente.
 */
import { MENSAJES } from "./mensajes";
import {
  limpiarTexto,
  normalizarCorreo,
  normalizarNombreRestaurante,
} from "./normalizacion";

const CORREO =
  /^[A-Za-z0-9_%+-]+(\.[A-Za-z0-9_%+-]+)*@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*\.[A-Za-z]{2,}$/;
const MAYUSCULA = /\p{Lu}/u;
const MINUSCULA = /\p{Ll}/u;
const NUMERO = /\d/;
const LONGITUD_MINIMA_CONTRASENA = 8;

export type Campo =
  | "nombres"
  | "apellidos"
  | "correo"
  | "restaurante"
  | "contrasena";

export interface DatosRegistroValidos {
  nombres: string;
  apellidos: string;
  correo: string;
  restaurante: string;
  restauranteNormalizado: string;
  contrasena: string;
}

export type ResultadoValidacion =
  | { ok: true; datos: DatosRegistroValidos }
  | { ok: false; errores: Partial<Record<Campo, string>> };

function texto(entrada: Record<string, unknown>, campo: Campo): string {
  const valor = entrada[campo];
  return typeof valor === "string" ? valor : "";
}

export function contrasenaSegura(contrasena: string): boolean {
  return (
    Array.from(contrasena).length >= LONGITUD_MINIMA_CONTRASENA &&
    MAYUSCULA.test(contrasena) &&
    MINUSCULA.test(contrasena) &&
    NUMERO.test(contrasena)
  );
}

export function validarRegistro(entrada: unknown): ResultadoValidacion {
  const datos =
    typeof entrada === "object" && entrada !== null
      ? (entrada as Record<string, unknown>)
      : {};
  const errores: Partial<Record<Campo, string>> = {};

  for (const campo of ["nombres", "apellidos", "restaurante"] as const) {
    if (texto(datos, campo).trim() === "") {
      errores[campo] = MENSAJES.campoObligatorio;
    }
  }

  const correo = normalizarCorreo(texto(datos, "correo"));
  if (correo === "") {
    errores.correo = MENSAJES.campoObligatorio;
  } else if (!CORREO.test(correo)) {
    errores.correo = MENSAJES.correoInvalido;
  }

  const contrasena = texto(datos, "contrasena");
  if (contrasena === "") {
    errores.contrasena = MENSAJES.campoObligatorio;
  } else if (!contrasenaSegura(contrasena)) {
    errores.contrasena = MENSAJES.contrasenaDebil;
  }

  if (Object.keys(errores).length > 0) return { ok: false, errores };

  const restaurante = limpiarTexto(texto(datos, "restaurante"));
  return {
    ok: true,
    datos: {
      nombres: limpiarTexto(texto(datos, "nombres")),
      apellidos: limpiarTexto(texto(datos, "apellidos")),
      correo,
      restaurante,
      restauranteNormalizado: normalizarNombreRestaurante(restaurante),
      contrasena,
    },
  };
}
