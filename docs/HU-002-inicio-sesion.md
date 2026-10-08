# HU-002 · Inicio de sesión

**Prototipo:** `docs/prototipos/hu002_inicio_sesion_prototipo.html`
**Depende de:** HU-001 (necesita usuarios registrados).

## Historia

Como usuario registrado, quiero iniciar sesión con mi correo y contraseña para acceder a las funciones que me corresponden según mi rol.

## Criterios de aceptación

1. El sistema debe permitir al usuario ingresar su correo electrónico.
2. El sistema debe permitir al usuario ingresar su contraseña y mostrarla oculta, con la opción de verla.
3. El sistema debe validar que ambos campos hayan sido diligenciados.
4. El sistema debe verificar que el correo electrónico corresponda a una cuenta registrada y que la contraseña corresponda a esa cuenta.
5. Si el correo y la contraseña son correctos, el sistema debe permitir el ingreso.
6. Después de un ingreso exitoso, el sistema debe mostrar la pantalla principal del rol del usuario: el administrador ve Compras, Insumos, Menú, Reportes y Usuarios; el auxiliar de cocina ve Consumo del día, Pérdidas, Platos vendidos y Menú del día.
7. Si el usuario no tiene rol asignado, el sistema debe informarle que su cuenta está pendiente de asignación de rol y no debe mostrarle ninguna función.
8. Si el correo o la contraseña son incorrectos, el sistema debe informar que las credenciales no son válidas, sin indicar cuál de los dos falló, y no debe permitir el ingreso.
9. El sistema debe permitir al usuario volver a ingresar sus credenciales después de un intento fallido.
10. Después de tres intentos fallidos consecutivos, el sistema debe bloquear el acceso de la cuenta durante 2 horas e informar al usuario que alcanzó el número máximo de intentos.
11. Mientras la cuenta esté bloqueada, el sistema no debe permitir el ingreso, aunque las credenciales sean correctas.
12. Pasadas las 2 horas, el sistema debe permitir de nuevo el ingreso y reiniciar el contador de intentos fallidos.
13. El sistema debe mantener la sesión abierta al cerrar la app y permitir cerrarla con la opción "Cerrar sesión".
14. El sistema debe responder al inicio de sesión en máximo 2 segundos.

## Lista de tareas

- Diseñar la pantalla de inicio de sesión según el prototipo
- Programar la validación de campos diligenciados
- Programar el inicio de sesión con Firebase Authentication y el mensaje de credenciales no válidas
- Leer el rol del usuario en Firestore y mostrar la pantalla principal de su rol
- Mostrar el aviso de cuenta sin rol
- Programar el contador de intentos fallidos y el bloqueo de 2 horas
- Mantener la sesión y programar "Cerrar sesión"
- Crear un usuario de prueba por rol
- Ejecutar las pruebas de aceptación (incluido el bloqueo)
- Actualizar los modelos: casos de uso y diagrama de secuencia del inicio de sesión
- Preparar la demostración con los dos roles

## Pantallas (según el prototipo)

1. **Login**: correo, contraseña con ícono de ojo, botón "INICIAR SESIÓN", enlace a registro.
2. **3A · Administrador**: opciones Compras, Insumos, Menú, Reportes, Usuarios.
3. **3B · Auxiliar de cocina**: Consumo del día, Pérdidas, Platos vendidos, Menú del día.
4. **3C · Sin rol**: aviso "Tu cuenta está pendiente de asignación de rol", ninguna función, solo "Cerrar sesión".
5. **Menú ☰ de la cuenta**: "Cerrar sesión".
6. **E1**: campos vacíos ("Ingresa tu correo electrónico", "Ingresa tu contraseña").
7. **E2**: "Las credenciales no son válidas" (siempre el mismo mensaje).
8. **E3**: cuenta bloqueada 2 horas, con el botón deshabilitado.

En esta etapa las opciones de las pantallas principales (Compras, Pérdidas, etc.) **solo se muestran**; todavía no llevan a ninguna pantalla funcional. Pueden mostrar un aviso "Próximamente".

## Decisiones pendientes (preguntar a la persona antes de implementar)

1. **Bloqueo por intentos fallidos (CA10 a CA12).** Firebase Authentication no ofrece un contador configurable de 3 intentos y 2 horas. Hay que llevarlo en Firestore, por correo. Opción A (recomendada, requiere plan Blaze): una Cloud Function invocable registra el intento fallido y devuelve si la cuenta está bloqueada, así el cliente no puede manipular el contador. Opción B (sin Blaze): documento `loginLockouts/{correo}` escrito desde el cliente con reglas restrictivas; es más fácil de saltar, y debe quedar documentado como limitación.
2. **Cuenta desactivada (viene de HU-003).** Si `activo == false`, no debe poder ingresar. Aunque HU-003 no se construye ahora, el login debería leer el campo `activo` para no tener que rehacerlo. Mensaje sugerido: "Tu cuenta está desactivada. Comunícate con un administrador."
3. El enlace "¿Olvidaste tu contraseña?" existe en el Login de Miro pero **no está en los criterios**. No implementarlo; dejarlo oculto o deshabilitado.

## Pruebas de aceptación sugeridas

- Campos vacíos muestran error (CA3).
- Credenciales incorrectas muestran el mensaje genérico, sin decir cuál falló (CA8), y se puede reintentar (CA9).
- Tres fallos seguidos bloquean 2 horas; con credenciales correctas sigue bloqueado (CA10, CA11). Para probarlo sin esperar, hacer configurable la duración (por ejemplo, 1 minuto en pruebas).
- Pasado el bloqueo, ingresa y el contador queda en cero (CA12).
- Administrador, auxiliar y sin rol ven cada uno su pantalla (CA6, CA7).
- Cerrar y abrir la app mantiene la sesión; "Cerrar sesión" la termina (CA13).
- El inicio de sesión responde en menos de 2 segundos con conexión normal (CA14).
- Crear tres usuarios de prueba, uno por caso: administrador, auxiliar y sin rol.
