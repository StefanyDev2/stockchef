# HU-004 · Insumos críticos

**Prototipo:** no hay; se sigue el estilo de la pantalla "Usuarios" (HU-003).
**Depende de:** HU-003 (roles) y los insumos de HU-006.

## Historia

Yo como administrador quiero definir la lista de insumos críticos para realizar un seguimiento de aquellos productos que requieren mayor control.

## Criterios de aceptación

1. El sistema debe permitir al administrador consultar la lista de insumos registrados en su restaurante.
2. El sistema debe permitir al administrador seleccionar los insumos que desea clasificar como críticos.
3. El sistema debe permitir al administrador marcar un insumo como crítico y quitarle esta clasificación cuando sea necesario.
4. Para cada insumo, el sistema debe mostrar su nombre y su estado de clasificación (Crítico o No crítico).
5. El sistema debe guardar los cambios realizados en la clasificación de los insumos.
6. El sistema debe permitir al administrador identificar cuáles son los insumos críticos mediante una lista diferenciada de los demás insumos.
7. El sistema debe mostrar un mensaje de confirmación cuando se guarde correctamente la lista de insumos críticos.

## Pantalla

**Insumos** (opción "Insumos" del administrador):

- Dos secciones: **"Insumos críticos"** y **"Otros insumos"** (CA6).
- Cada insumo muestra su nombre, la etiqueta **Crítico** o **No crítico** (CA4) y un interruptor para marcarlo o quitarlo (CA2, CA3). Los inactivos llevan además la etiqueta "Inactivo".
- **"Guardar cambios"** guarda toda la lista (CA5) y muestra "Lista de insumos críticos guardada correctamente" (CA7). Si se intenta salir con cambios sin guardar, se pregunta.

## Decisiones tomadas

- Solo el **administrador** ve y cambia la lista. Lo exige también el servidor.
- Se guarda con la Cloud Function `guardarInsumosCriticos`, que recibe la lista completa de insumos críticos y actualiza todos los insumos del restaurante en una sola operación. La app no escribe insumos directamente.
- Se muestran todos los insumos registrados, también los inactivos (CA1 dice "registrados").
- Nuevo campo en cada insumo: `critico` (boolean). Si no existe, se considera "No crítico".
