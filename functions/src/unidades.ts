/**
 * Unidades de medida de HU-006 (CA4). Mismas reglas que
 * lib/features/compras/domain/unidades.dart.
 */
export const UNIDADES = [
  "kilogramo",
  "gramo",
  "libra",
  "litro",
  "mililitro",
  "unidad",
] as const;

export type Unidad = (typeof UNIDADES)[number];

/** Tipo de medida y cuánto vale cada unidad en la unidad base del tipo. */
const FACTORES: Record<Unidad, { tipo: "masa" | "volumen" | "conteo"; base: number }> = {
  kilogramo: { tipo: "masa", base: 1000 },
  gramo: { tipo: "masa", base: 1 },
  libra: { tipo: "masa", base: 453.592 },
  litro: { tipo: "volumen", base: 1000 },
  mililitro: { tipo: "volumen", base: 1 },
  unidad: { tipo: "conteo", base: 1 },
};

export function esUnidad(valor: unknown): valor is Unidad {
  return typeof valor === "string" && (UNIDADES as readonly string[]).includes(valor);
}

/**
 * Convierte `cantidad` de la unidad `desde` a la unidad `hacia`. Devuelve
 * `null` si no se puede (por ejemplo, kilogramos a litros). El resultado se
 * redondea a 4 decimales para no acumular errores de punto flotante.
 */
export function convertir(cantidad: number, desde: Unidad, hacia: Unidad): number | null {
  const origen = FACTORES[desde];
  const destino = FACTORES[hacia];
  if (origen.tipo !== destino.tipo) return null;
  return redondear((cantidad * origen.base) / destino.base);
}

export function redondear(valor: number, decimales = 4): number {
  const factor = 10 ** decimales;
  return Math.round(valor * factor) / factor;
}
