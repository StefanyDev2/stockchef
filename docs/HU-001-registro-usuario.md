# HU-001 · Registro de usuario

**Prototipo:** `docs/prototipos/hu001_registro_usuario_prototipo.html`

## Historia

Como persona que trabaja en un restaurante, quiero crear una cuenta en StockChef para poder usar la aplicación.

## Criterios de aceptación

1. El sistema debe permitir al usuario ingresar los siguientes datos: nombres, apellidos, correo electrónico, nombre del restaurante, contraseña y confirmación de contraseña.
2. Todos los campos son obligatorios.
3. El sistema debe informar al usuario cuáles campos obligatorios están pendientes cuando intente completar el registro sin diligenciarlos.
4. El sistema debe validar que el correo electrónico tenga un formato válido.
5. El sistema debe verificar que el correo electrónico no se encuentre registrado previamente.
6. El sistema debe validar que la contraseña tenga mínimo 8 caracteres y contenga una mayúscula, una minúscula y un número.
7. El sistema debe verificar que la contraseña y la confirmación de contraseña sean iguales. Si no coinciden, el sistema debe informar al usuario y solicitar que las ingrese nuevamente.
8. Si alguno de los datos no cumple las validaciones, el sistema debe informar el error correspondiente y permitir al usuario corregirlo sin borrar los demás datos.
9. Si todos los datos son válidos, el sistema debe crear la cuenta del usuario.
10. El primer usuario que registra un restaurante debe quedar con el rol de administrador; los usuarios siguientes deben quedar sin rol hasta que el administrador se lo asigne (HU-003).
11. Una vez creada la cuenta, el sistema debe informar al usuario que su cuenta fue creada exitosamente y llevarlo a la pantalla de inicio de sesión.
12. El usuario registrado debe poder usar su correo electrónico y contraseña para ingresar a la aplicación.

## Lista de tareas

(Tomar la lista de tareas de la tarjeta de HU-001 en Trello. Pegarla aquí si se quiere que Claude Code la use como checklist.)

## Pantallas (según el prototipo)

1. **Login** → el enlace "¿No tienes cuenta? Registrarse" abre el formulario.
2. **Formulario de registro**: 6 campos, regla de contraseña visible como ayuda, botón "Registrarse", enlace "¿Ya tienes cuenta? Inicia sesión".
3. **E1 · Campos pendientes**: cada campo vacío muestra "Campo obligatorio" y arriba un aviso "Completa los campos obligatorios".
4. **E2 · Datos no válidos**: mensajes por campo, conservando los datos válidos.
5. **Cuenta creada**: mensaje de éxito y botón "Ir a iniciar sesión" (lleva al Login).

## Mensajes de validación (propuestos en el prototipo)

- Campo vacío: "Campo obligatorio"
- Formato de correo: "Ingresa un correo válido"
- Correo repetido: "Este correo ya está registrado"
- Contraseña débil: "Mínimo 8 caracteres, con mayúscula, minúscula y número"
- No coinciden: "Las contraseñas no coinciden"

## Decisiones pendientes (preguntar a la persona antes de implementar)

1. **¿Cómo se une el segundo usuario a un restaurante existente?** El CA10 dice que el primero que registra un restaurante es administrador y los siguientes quedan sin rol, pero el formulario solo pide el "nombre del restaurante". Propuesta: se normaliza el nombre (minúsculas, sin tildes, espacios recortados); si ya existe un restaurante con ese nombre, el usuario se une con `rol = null`; si no existe, se crea y el usuario queda como administrador. Riesgo: cualquiera que escriba el mismo nombre se une al restaurante. Para el curso es aceptable; si se quiere más control, se puede usar un código de invitación (cambiaría el formulario y los criterios).
2. **¿Cloud Functions (requiere plan Blaze de Firebase) o solo cliente + reglas?** Con Functions, una función invocable crea el documento del usuario y asigna el rol de forma atómica (más seguro). Sin Functions, el cliente escribe en una transacción y las reglas de Firestore validan que solo se pueda ser administrador al crear un restaurante nuevo.
3. La pantalla de éxito tiene botón "Ir a iniciar sesión". Si el equipo la quiere automática, cambiar solo ese paso.

## Pruebas de aceptación sugeridas

- Registro con todos los datos válidos crea la cuenta (CA9) y lleva al Login (CA11).
- Registro con un campo vacío muestra cuáles faltan (CA2, CA3).
- Correo con formato inválido, correo repetido, contraseña débil y contraseñas distintas muestran su error y no borran los demás campos (CA4 a CA8).
- Primer usuario de un restaurante queda administrador; el segundo queda sin rol (CA10).
- El usuario recién registrado puede iniciar sesión (CA12).
