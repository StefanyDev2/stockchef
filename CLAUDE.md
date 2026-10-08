# StockChef

Aplicación para restaurantes pequeños de menú del día. Registra compras, consumo y pérdidas de insumos, y clasifica las pérdidas por causa (dañado, sobrante, faltante, compra de emergencia). Proyecto universitario de Ingeniería de Software (metodología Scrum).

El problema que resuelve: los dueños compran por costumbre, cocinan sin recetas ni porciones medidas y no saben cuánto pierden ni por qué.

## Alcance de esta etapa (Sprint 1)

Solo se construyen **HU-001 (Registro de usuario)** y **HU-002 (Inicio de sesión)**.
No construir nada de HU-003 en adelante (roles, compras, pérdidas, menú, reportes), salvo lo mínimo para que HU-001 y HU-002 funcionen.

- Especificación y criterios de aceptación: `docs/HU-001-registro-usuario.md` y `docs/HU-002-inicio-sesion.md`
- Prototipos visuales (abrir en el navegador): `docs/prototipos/hu001_registro_usuario_prototipo.html` y `docs/prototipos/hu002_inicio_sesion_prototipo.html`
- Modelo de datos y reglas: `docs/modelo-datos.md`

El prototipo manda sobre cualquier suposición de diseño. Cada pantalla trae la etiqueta de los criterios de aceptación (CA) que cubre.

## Stack tecnológico (definido, no cambiar sin avisar)

| Capa | Tecnología |
|---|---|
| App | Flutter (Dart) |
| Base de datos | Firebase Firestore |
| Autenticación | Firebase Authentication (correo y contraseña) |
| Lógica en la nube | Firebase Cloud Functions (TypeScript) |
| Archivos | Firebase Cloud Storage (no se usa en HU-001 ni HU-002) |

Plataforma: **app móvil, Android primero** (iOS queda como extensión futura). No construir ni probar versión web. Se prueba en emulador o en un celular Android real con `flutter run`.

## Decisiones técnicas propuestas

- Estructura por funcionalidad: `lib/features/auth/{data,domain,presentation}`, `lib/core/` para tema, rutas y utilidades compartidas.
- Estado: `flutter_riverpod`. Navegación: `go_router`.
- Paquetes: `firebase_core`, `firebase_auth`, `cloud_firestore`, `flutter_riverpod`, `go_router`.
- La lógica de validación (correo, contraseña, campos obligatorios) va en clases puras de Dart, fuera de los widgets, para poder probarla con tests unitarios.
- Todo texto visible al usuario va en español.
- Cada módulo debe poder cambiar sin afectar a los demás (requerimiento de mantenibilidad).

## Diseño visual

Seguir los prototipos HTML. Resumen:

- Fondo blanco, tarjetas redondeadas, bordes grises claros.
- Verde menta (`#B8F0D0`) para títulos y banners positivos, verde `#1F8F5F` para flechas y enlaces.
- Durazno (`#F9CFA6`, borde `#F0B27A`) para botones primarios; naranja `#F5A65B` para el botón presionado.
- Rojo `#E03E3E` para errores.
- Marca: "StockChef" (la "Chef" en naranja `#E8892B`). Ojo: en el Miro dice "Cheef"; el nombre correcto es **StockChef**.

## Requerimientos no funcionales (línea base del curso)

- Funcionalidad: no se puede completar una solicitud omitiendo datos obligatorios.
- Fiabilidad: disponibilidad mínima del 99,5 %.
- Eficiencia: máximo 2 segundos de respuesta en consultas habituales (el inicio de sesión también, CA14 de HU-002).
- Compatibilidad: Android 8.0 en adelante (el proyecto es móvil, así que la parte web de la línea base no aplica).
- Usabilidad: un usuario nuevo completa las tareas principales sin capacitación.
- Seguridad: autenticación y control de acceso por rol, también en las reglas de Firestore.
- Mantenibilidad: módulos independientes.
- Portabilidad: instalable en Android, extensible a iOS.

## Definition of Done (aplica a toda historia)

1. Todas las tareas de la historia están completas.
2. Pasó las pruebas de aceptación (cada CA verificado).
3. Está documentada: se actualizan los modelos (casos de uso, diagrama de secuencia, etc.).
4. Se puede mostrar funcionando a usuarios e interesados.

## Cómo trabajar

1. Antes de escribir código, proponer un plan corto y esperar confirmación.
2. Preguntar antes de decidir los puntos marcados como "Decisión pendiente" en los documentos de `docs/`.
3. Trabajar una historia a la vez: terminar HU-001, probarla, y recién después HU-002.
4. Después de cada bloque, ejecutar `flutter analyze` y los tests, y corregir lo que falle.
5. Nunca poner credenciales, claves ni archivos de configuración de Firebase con secretos en el repositorio de ejemplo ni en los documentos. Usar `.gitignore` para `google-services.json`, `GoogleService-Info.plist`, `.env` y similares.
6. Los pasos que requieren la cuenta de la persona (crear el proyecto de Firebase, iniciar sesión en la consola, `flutterfire configure`) los hace ella; indicarle el comando y esperar.

## GitHub

Claude Code ya está conectado a la cuenta de GitHub de la persona. Al iniciar:

1. Preguntar el nombre del repositorio y si va en su cuenta personal o en una organización. Proponer `stockchef`, **privado** (es un trabajo académico).
2. Crear el repositorio, inicializar git en la carpeta del proyecto y subir la rama `main` con un primer commit que incluya `CLAUDE.md`, `docs/` y el esqueleto de Flutter.
3. Antes del primer commit, crear un `.gitignore` de Flutter que además excluya `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart` si contiene claves que la persona no quiera publicar, `.env`, `*.jks`, `*.keystore` y `key.properties`. Confirmar con `git status` que no se sube ningún secreto.
4. Una rama por historia: `feature/hu-001-registro` y `feature/hu-002-inicio-sesion`, creadas desde `main`.
5. Commits pequeños, en español, con mensajes como `feat(auth): validar formato de correo (HU-001, CA4)`. Subir (`push`) después de cada bloque que pase `flutter analyze` y los tests.
6. Al terminar cada historia, abrir un pull request hacia `main` con la lista de criterios de aceptación verificados. No fusionarlo sin que la persona lo apruebe.
7. Nunca hacer `push --force` ni reescribir el historial sin pedir permiso.

## Pasos manuales previos (los hace la persona, no Claude Code)

1. Crear un proyecto en la consola de Firebase.
2. Activar Authentication (proveedor Correo/Contraseña) y Firestore.
3. Instalar Flutter y las CLI de Firebase (`firebase-tools`, `flutterfire_cli`).
4. Ejecutar `flutterfire configure` dentro del proyecto.
