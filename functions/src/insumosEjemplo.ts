import type { DocumentReference, Transaction } from "firebase-admin/firestore";

/**
 * Insumos de ejemplo con los que empieza cada restaurante nuevo, para poder
 * registrar compras (HU-006) y marcar críticos (HU-004) mientras no exista la
 * historia de crear insumos. Cuando exista, se puede quitar.
 *
 * Tomate y Pollo vienen como críticos; Cebolla viene inactiva, para ver que
 * no aparece en la lista de compras.
 */
export const INSUMOS_EJEMPLO = [
  { id: "tomate", nombre: "Tomate", unidad: "kilogramo", cantidadDisponible: 5, nivelMinimo: 10, estado: "bajo", activo: true, critico: true },
  { id: "arroz", nombre: "Arroz", unidad: "kilogramo", cantidadDisponible: 25, nivelMinimo: 10, estado: "disponible", activo: true, critico: false },
  { id: "pollo", nombre: "Pollo", unidad: "kilogramo", cantidadDisponible: 0, nivelMinimo: 5, estado: "agotado", activo: true, critico: true },
  { id: "aceite", nombre: "Aceite", unidad: "litro", cantidadDisponible: 3, nivelMinimo: 2, estado: "disponible", activo: true, critico: false },
  { id: "huevos", nombre: "Huevos", unidad: "unidad", cantidadDisponible: 30, nivelMinimo: 60, estado: "bajo", activo: true, critico: false },
  { id: "cebolla", nombre: "Cebolla", unidad: "kilogramo", cantidadDisponible: 0, nivelMinimo: 3, estado: "agotado", activo: false, critico: false },
] as const;

/** Crea los insumos de ejemplo dentro de una transacción. */
export function crearInsumosEjemplo(
  tx: Transaction,
  restaurante: DocumentReference,
): void {
  for (const { id, ...datos } of INSUMOS_EJEMPLO) {
    tx.create(restaurante.collection("insumos").doc(id), datos);
  }
}
