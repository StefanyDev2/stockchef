import { FieldValue, type Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { convertir, esUnidad, redondear, type Unidad } from "./unidades";
import { MENSAJES_USUARIOS } from "./usuarios";

/**
 * Mensajes de HU-006. Son los mismos de la app
 * (lib/features/compras/domain/compras.dart).
 */
export const MENSAJES_COMPRAS = {
  camposPendientes: "Debe completar todos los campos para guardar la compra",
  valoresInvalidos: "Ingrese valores válidos para la cantidad y el precio",
  insumoNoDisponible: "El insumo elegido no está disponible.",
  unidadIncompatible: (unidadInsumo: string) =>
    `Esa unidad no sirve para este insumo, que se mide en ${unidadInsumo}.`,
} as const;

export type CampoCompra = "insumo" | "cantidad" | "unidad" | "precio";
type TipoCompra = "planeada" | "emergencia";

export interface CompraRegistrada {
  compraId: string;
  insumoNombre: string;
  cantidad: number;
  unidad: Unidad;
  precioTotal: number;
  precioUnitario: number;
  cantidadDisponible: number;
  unidadInsumo: string;
  estado: string;
}

interface DatosCompra {
  insumoId: string;
  cantidad: number;
  unidad: Unidad;
  precioTotal: number;
  proveedor: string | null;
  tipo: TipoCompra;
}

function campo(entrada: unknown, nombre: string): unknown {
  return typeof entrada === "object" && entrada !== null
    ? (entrada as Record<string, unknown>)[nombre]
    : undefined;
}

function vacio(valor: unknown): boolean {
  return valor === undefined || valor === null || (typeof valor === "string" && valor.trim() === "");
}

/**
 * CA2, CA5 y CA6: revisa los datos. Primero los campos pendientes y luego
 * que cantidad y precio sean números mayores a cero.
 */
export function validarCompra(entrada: unknown): DatosCompra {
  const insumoId = campo(entrada, "insumoId");
  const cantidad = campo(entrada, "cantidad");
  const unidad = campo(entrada, "unidad");
  const precioTotal = campo(entrada, "precioTotal");

  const pendientes: CampoCompra[] = [];
  if (vacio(insumoId)) pendientes.push("insumo");
  if (vacio(cantidad)) pendientes.push("cantidad");
  if (vacio(unidad)) pendientes.push("unidad");
  if (vacio(precioTotal)) pendientes.push("precio");
  if (pendientes.length > 0) {
    throw new HttpsError("invalid-argument", MENSAJES_COMPRAS.camposPendientes, {
      pendientes,
    });
  }

  const positivo = (valor: unknown) =>
    typeof valor === "number" && Number.isFinite(valor) && valor > 0;
  if (!positivo(cantidad) || !positivo(precioTotal)) {
    throw new HttpsError("invalid-argument", MENSAJES_COMPRAS.valoresInvalidos);
  }
  if (typeof insumoId !== "string" || !esUnidad(unidad)) {
    throw new HttpsError("invalid-argument", MENSAJES_COMPRAS.camposPendientes);
  }

  const proveedor = campo(entrada, "proveedor");
  const tipo = campo(entrada, "tipo");
  return {
    insumoId,
    cantidad: cantidad as number,
    unidad,
    precioTotal: precioTotal as number,
    proveedor:
      typeof proveedor === "string" && proveedor.trim() !== ""
        ? proveedor.trim().replace(/\s+/g, " ")
        : null,
    tipo: tipo === "emergencia" ? "emergencia" : "planeada",
  };
}

/**
 * HU-006: registra una compra. En una sola transacción guarda la compra con
 * fecha, hora y usuario (CA7), suma la cantidad al insumo convirtiendo la
 * unidad si hace falta (CA8), calcula el precio por unidad (CA9) y, si el
 * insumo supera su nivel mínimo, lo deja "disponible" (CA10).
 */
export async function registrarCompra(
  entrada: unknown,
  quienLlama: string | undefined,
  db: Firestore,
): Promise<CompraRegistrada> {
  if (!quienLlama) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión");
  }
  const datos = validarCompra(entrada);

  return db.runTransaction(async (tx) => {
    // CA12: solo un administrador activo registra compras.
    const admin = (await tx.get(db.doc(`users/${quienLlama}`))).data();
    if (admin?.rol !== "administrador" || admin?.activo !== true) {
      throw new HttpsError("permission-denied", MENSAJES_USUARIOS.sinPermiso);
    }
    const restaurante = db.doc(`restaurants/${admin.restaurantId}`);
    const refInsumo = restaurante.collection("insumos").doc(datos.insumoId);
    const insumo = (await tx.get(refInsumo)).data();
    if (!insumo || insumo.activo !== true) {
      throw new HttpsError("failed-precondition", MENSAJES_COMPRAS.insumoNoDisponible);
    }

    const unidadInsumo = insumo.unidad as Unidad;
    const convertida = convertir(datos.cantidad, datos.unidad, unidadInsumo);
    if (convertida === null) {
      throw new HttpsError(
        "failed-precondition",
        MENSAJES_COMPRAS.unidadIncompatible(unidadInsumo),
      );
    }

    const anterior = Number(insumo.cantidadDisponible ?? 0);
    const cantidadDisponible = redondear(anterior + convertida);
    const estado =
      cantidadDisponible > Number(insumo.nivelMinimo ?? 0)
        ? "disponible"
        : (insumo.estado as string);
    const precioUnitario = redondear(datos.precioTotal / datos.cantidad, 2);

    const refCompra = restaurante.collection("compras").doc();
    tx.create(refCompra, {
      insumoId: datos.insumoId,
      insumoNombre: insumo.nombre,
      tipo: datos.tipo,
      cantidad: datos.cantidad,
      unidad: datos.unidad,
      cantidadConvertida: convertida,
      unidadInsumo,
      proveedor: datos.proveedor,
      precioTotal: datos.precioTotal,
      precioUnitario,
      cantidadDisponibleDespues: cantidadDisponible,
      registradoPor: quienLlama,
      registradoPorNombre: `${admin.nombres} ${admin.apellidos}`.trim(),
      fecha: FieldValue.serverTimestamp(),
    });
    tx.update(refInsumo, { cantidadDisponible, estado });

    return {
      compraId: refCompra.id,
      insumoNombre: insumo.nombre as string,
      cantidad: datos.cantidad,
      unidad: datos.unidad,
      precioTotal: datos.precioTotal,
      precioUnitario,
      cantidadDisponible,
      unidadInsumo,
      estado,
    };
  });
}
