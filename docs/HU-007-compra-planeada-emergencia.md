# HU-007 · Compra planeada o de emergencia

**Prototipo:** el de HU-006 (`docs/prototipos/hu006/`): botones "Planeada" y "Emergencia" en el formulario de compra.
**Depende de:** HU-006 (registrar compra).

## Historia

Yo como auxiliar de cocina quiero diferenciar las compras planeadas de las compras de emergencia para identificar y analizar las adquisiciones no previstas.

## Criterios de aceptación

1. El sistema debe permitir al auxiliar de cocina seleccionar el tipo de compra al momento de registrar una compra (Planeada o De emergencia).
2. El tipo de compra debe mostrarse Planeada y De emergencia.
3. El sistema debe solicitar el tipo de compra como un campo obligatorio al registrar una compra.
4. El sistema debe guardar el tipo de compra seleccionado junto con la información de la compra registrada.
5. El sistema debe permitir consultar el tipo de compra asociado a cada compra registrada.
6. El sistema debe permitir diferenciar las compras planeadas de las compras de emergencia para facilitar su identificación y análisis.

## Qué ya existía desde HU-006 y qué se agregó

| CA | Desde HU-006 | En HU-007 |
|---|---|---|
| 1 | Botones Planeada / Emergencia (solo administrador) | El **auxiliar de cocina** también registra compras, desde "Registrar compra" |
| 2 | Decía "Emergencia" | Dice **"De emergencia"** |
| 3 | "Planeada" viene marcada | Se mantiene así, y el **servidor rechaza** una compra sin tipo |
| 4 | Se guarda `tipo` con la compra | — |
| 5 | Etiqueta en el historial | El auxiliar también consulta el historial |
| 6 | Solo la etiqueta | Filtro **Todas / Planeadas / De emergencia** y resumen con cantidad de compras y total en pesos de cada tipo (administrador) |

## Decisiones tomadas

- **Cambio sobre HU-006:** el administrador **y** el auxiliar de cocina registran compras (la HU-006 en el tablero del equipo dice "auxiliar de cocina"). El administrador tiene más control: el filtro y el resumen para el análisis (CA6), los insumos críticos (HU-004) y los usuarios (HU-003).
- El auxiliar ve el historial completo del restaurante, solo para consultar.
- Un usuario sin rol o desactivado no puede registrar compras.
- El tipo de compra no es una lista desplegable: se mantienen los dos botones del prototipo, con "Planeada" marcada por defecto.
