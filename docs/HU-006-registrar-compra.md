# HU-006 · Registrar compra de insumos (CS02)

**Prototipo:** `docs/prototipos/hu006/` (capturas del tablero de Miro)
**Depende de:** HU-002 (inicio de sesión y pantalla de cada rol) y HU-003 (roles). Necesita insumos; mientras no exista la historia de insumos, se crean insumos de prueba (ver más abajo).

## Historia

Yo como auxiliar de cocina quiero registrar las compras de insumos indicando producto, cantidad, unidad de medida y precio pagado para mantener un control detallado de las adquisiciones.

> **Aclaración (actualizada en HU-007):** la historia dice "auxiliar de cocina" y el CA1 y el CA12 dicen "administrador". Primero se decidió que solo el administrador registraba compras; con HU-007 se cambió: **el administrador y el auxiliar de cocina** registran compras. El administrador tiene más control (ver `docs/HU-007-compra-planeada-emergencia.md`).

## Criterios de aceptación

1. El sistema debe permitir al administrador ingresar los siguientes datos de la compra: insumo, cantidad, unidad de medida, proveedor y precio total pagado.
2. Insumo, cantidad, unidad y precio son obligatorios; el proveedor es opcional.
3. El insumo debe ser una lista desplegable con los insumos activos.
4. La unidad de medida debe ser una lista desplegable con: kilogramo, gramo, libra, litro, mililitro o unidad.
5. El sistema debe informar cuáles campos obligatorios están pendientes cuando se intente guardar sin diligenciarlos, con el mensaje "Debe completar todos los campos para guardar la compra".
6. El sistema debe validar que la cantidad y el precio sean números mayores a cero; si no, debe mostrar "Ingrese valores válidos para la cantidad y el precio".
7. El sistema debe registrar automáticamente la fecha y la hora de la compra y el usuario que la registró.
8. Si todos los datos son válidos, el sistema debe guardar la compra y sumar la cantidad comprada a la cantidad disponible del insumo.
9. El sistema debe calcular y guardar el precio por unidad de la compra (precio total ÷ cantidad).
10. Si con la compra el insumo supera su nivel mínimo, el sistema debe actualizar su estado a "Disponible".
11. Una vez guardada, el sistema debe informar que la compra fue registrada y mostrar el insumo, la cantidad, el precio y la nueva cantidad disponible.
12. El sistema debe mostrar la opción "Compras" solo al administrador.
13. El sistema debe guardar la compra en máximo 2 segundos.

## Pantallas (según el prototipo)

1. **Compra de insumos**: tipo (Planeada / Emergencia), insumo, cantidad y unidad, proveedor, precio total y "Guardar compra".
2. **Historial de compras**: "Compra guardada correctamente", la compra recién guardada y las anteriores, y "Registrar otra compra".

## Decisiones tomadas

- **Quién:** al principio solo el administrador; desde HU-007, el administrador y el auxiliar de cocina. El servidor exige un rol activo.
- **Tipo de compra:** el selector "Planeada / Emergencia" del prototipo se incluye, con "Planeada" por defecto. Servirá para la pérdida por compra de emergencia.
- **Unidades:** cada insumo tiene su unidad. Si la compra viene en otra unidad del mismo tipo, se convierte antes de sumar: 1 kg = 1000 g, 1 lb = 453,592 g, 1 L = 1000 mL. Si no se puede convertir (por ejemplo, kilogramos a litros), se informa y no se guarda.
- **Precio por unidad (CA9):** precio total ÷ cantidad, en la unidad en que se registró la compra.
- **Estado del insumo (CA10):** si la nueva cantidad disponible es mayor que el nivel mínimo, el estado pasa a "Disponible"; si no, se deja como estaba.
- **Guardado:** lo hace la Cloud Function `registrarCompra` en una sola transacción: guarda la compra con fecha, hora y usuario (CA7) y suma al insumo (CA8). La app no escribe compras ni insumos directamente.

## Datos

Ambas colecciones van dentro del restaurante, para que las reglas de Firestore sean simples.

### `restaurants/{restaurantId}/insumos/{insumoId}`

| Campo | Tipo | Nota |
|---|---|---|
| `nombre` | string | |
| `unidad` | string | `kilogramo`, `gramo`, `libra`, `litro`, `mililitro` o `unidad` |
| `cantidadDisponible` | number | En la unidad del insumo |
| `nivelMinimo` | number | En la unidad del insumo |
| `estado` | string | `disponible`, `bajo` o `agotado` |
| `activo` | boolean | Solo los activos salen en la lista (CA3) |

Mientras no exista la historia de insumos, `npm run sembrar` crea insumos de prueba en "Sabor Casero".

### `restaurants/{restaurantId}/compras/{compraId}`

| Campo | Tipo | Nota |
|---|---|---|
| `insumoId`, `insumoNombre` | string | |
| `tipo` | string | `planeada` o `emergencia` |
| `cantidad`, `unidad` | number, string | Como se registró |
| `cantidadConvertida`, `unidadInsumo` | number, string | Lo que se sumó al insumo |
| `proveedor` | string o null | Opcional |
| `precioTotal` | number | |
| `precioUnitario` | number | `precioTotal ÷ cantidad` (CA9) |
| `cantidadDisponibleDespues` | number | Para mostrarla después (CA11) |
| `registradoPor`, `registradoPorNombre` | string | CA7 |
| `fecha` | timestamp | Hora del servidor (CA7) |
