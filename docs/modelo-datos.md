# Modelo de datos inicial (Firestore)

Solo lo necesario para HU-001 y HU-002. Se ampliará en las siguientes historias.

## Colecciones

### `restaurants/{restaurantId}`

| Campo | Tipo | Nota |
|---|---|---|
| `nombre` | string | Como lo escribió el primer usuario |
| `nombreNormalizado` | string | Minúsculas, sin tildes, espacios recortados. Sirve para buscar si ya existe |
| `creadoPor` | string | `uid` del primer usuario |
| `creadoEn` | timestamp | |

### `users/{uid}`

El id del documento es el `uid` de Firebase Authentication.

| Campo | Tipo | Nota |
|---|---|---|
| `nombres` | string | |
| `apellidos` | string | |
| `correo` | string | En minúsculas |
| `restaurantId` | string | Referencia a `restaurants` |
| `rol` | string o null | `"administrador"`, `"auxiliar_cocina"` o `null` (sin rol) |
| `activo` | boolean | `true` por defecto. Lo usa HU-003 |
| `creadoEn` | timestamp | |

### `loginLockouts/{correoNormalizado}`

| Campo | Tipo | Nota |
|---|---|---|
| `intentosFallidos` | number | Se reinicia en 0 al ingresar bien o al vencer el bloqueo |
| `bloqueadoHasta` | timestamp o null | Ahora + 2 horas al tercer fallo |

El correo se usa como id del documento (con los caracteres no permitidos reemplazados) para poder consultarlo sin haber iniciado sesión.

## Reglas de seguridad (principios)

- Nadie lee ni escribe sin estar autenticado, salvo lo estrictamente necesario del bloqueo de inicio de sesión.
- Un usuario solo puede leer su propio documento en `users`. El administrador puede leer los usuarios de su mismo `restaurantId` (se usa en HU-003).
- Un usuario **no puede cambiar su propio `rol` ni `activo`**. Eso solo lo hace un administrador del mismo restaurante, o la lógica de registro.
- El rol `administrador` solo se asigna automáticamente al crear un restaurante nuevo.
- `loginLockouts` no debe poder escribirse libremente desde el cliente si se usa la Opción A (Cloud Functions).
- Las reglas se prueban con el emulador de Firebase antes de desplegar.

## Estados de acceso resultantes

| Condición | Resultado |
|---|---|
| `activo == false` | No ingresa |
| `rol == null` | Ingresa, ve el aviso de cuenta sin rol y ninguna función |
| `rol == "administrador"` | Pantalla principal del administrador |
| `rol == "auxiliar_cocina"` | Pantalla principal del auxiliar de cocina |
