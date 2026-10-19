# HU-003 · Asignación de roles

**Prototipo:** `docs/prototipos/hu003/` (capturas del tablero de Miro)
**Depende de:** HU-001 (usuarios y restaurante) y HU-002 (inicio de sesión y pantalla de cada rol).

## Historia

Yo como administrador quiero asignar a cada usuario un rol de administrador o auxiliar de cocina para controlar las acciones que puede realizar dentro del sistema.

## Criterios de aceptación

1. El sistema debe permitir al administrador consultar la lista de usuarios de su restaurante.
2. Para cada usuario, el sistema debe mostrar: nombres, apellidos, correo y rol actual (Administrador, Auxiliar de cocina o Sin rol).
3. El sistema debe permitir al administrador asignar o cambiar el rol de un usuario eligiendo de una lista: Administrador o Auxiliar de cocina.
4. El sistema debe permitir al administrador desactivar un usuario; un usuario desactivado no puede ingresar a la aplicación.
5. El sistema no debe permitir quitar el rol ni desactivar al último administrador del restaurante, e informar que debe haber al menos un administrador.
6. Al guardar el cambio, el sistema debe informar que el rol fue actualizado.
7. El nuevo rol debe aplicarse la próxima vez que el usuario ingrese a la aplicación.
8. El sistema debe mostrar la opción "Usuarios" solo al administrador.
9. El sistema debe impedir que un auxiliar de cocina ejecute acciones del administrador, aunque intente acceder a ellas (restricción también en las reglas de Firestore).

## Pantallas (según el prototipo)

1. **Pantalla principal del administrador** → opción "Usuarios".
2. **Lista de usuarios**: tarjeta por usuario con nombre, correo y etiqueta del rol (Administrador, Auxiliar de cocina, Sin rol o Desactivado).
3. **Detalle del usuario**: avatar, nombre, correo, rol actual, "Asignar rol" (Administrador / Auxiliar de cocina), "Guardar cambios" y "Desactivar usuario".
4. **Rol actualizado**: vuelve a la lista con "Rol actualizado correctamente" y el usuario resaltado.
5. **D1 · Usuario desactivado**: la lista muestra "Usuario desactivado correctamente"; al intentar entrar, el inicio de sesión dice "Tu cuenta está inactiva. Comunícate con un administrador."
6. **E1 · Último administrador**: "Debe haber al menos un administrador en el restaurante."
7. **R1 · Acción rechazada**: "No tienes permisos para realizar esta acción. Solo un administrador puede gestionar usuarios y roles." con el botón "Volver".

## Decisiones tomadas

- Los cambios los hacen dos Cloud Functions (`asignarRol` y `cambiarEstadoUsuario`); la app no escribe `users` directamente. Así se puede revisar, dentro de una transacción, que quede al menos un administrador activo (CA5), cosa que las reglas de Firestore no pueden contar.
- Solo un administrador **activo** puede hacer cambios, y solo sobre usuarios de **su** restaurante (CA9).
- Al desactivar, la cuenta también se deshabilita en Firebase Authentication y se cierran sus sesiones, así no entra aunque tenga la app abierta (CA4).
- Un usuario desactivado se puede **reactivar** desde su detalle (no está en el prototipo; se agregó para corregir errores).
- El administrador puede cambiarse el rol a sí mismo si queda otro administrador, pero **no puede desactivar su propia cuenta**.
- Antes de desactivar se pide confirmación.
- No se puede volver a dejar a alguien "Sin rol": la lista de roles solo tiene Administrador y Auxiliar de cocina (CA3).
- Si alguien que ya tiene la sesión abierta cambia de rol, lo ve la próxima vez que entra o abre la app (CA7). El servidor aplica el rol nuevo de inmediato.
