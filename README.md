# StockChef

Control de compras, consumo y pérdidas de insumos para restaurantes pequeños de menú del día.
Proyecto universitario de Ingeniería de Software (Scrum).

**Sprint 1:** HU-001 (Registro de usuario) y HU-002 (Inicio de sesión). App móvil Android hecha en Flutter, con Firebase (Authentication, Firestore y Cloud Functions).

- Historias de usuario, prototipos y modelo de datos: [`docs/`](docs/)
- Contexto, alcance y reglas de trabajo: [`CLAUDE.md`](CLAUDE.md)

## Ramas

Todo el Sprint 1 (HU-001 y HU-002) está en **`main`**. Cada historia se trabaja en su propia rama (`feature/...`) y entra a `main` con un pull request.

---

## Guía para el equipo: correr la app en tu computador

Se hace una sola vez. Está pensada para Windows; en Mac o Linux los pasos son los mismos.

### 1. Instala las herramientas

| Herramienta | Para qué | Cómo comprobarlo |
|---|---|---|
| [Git](https://git-scm.com/downloads) | Descargar el código | `git --version` |
| [Flutter](https://docs.flutter.dev/get-started/install/windows/mobile) (canal stable) | La app | `flutter --version` |
| [Android Studio](https://developer.android.com/studio) | El SDK de Android, el emulador y Java 21 | `flutter doctor` |
| [Node.js 20 o más](https://nodejs.org/) | Las Cloud Functions | `node --version` |

Luego, en una terminal:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
flutter doctor --android-licenses
```

En `flutter doctor -v` deben salir en verde **Flutter**, **Android toolchain** y **Android Studio**. "Visual Studio" puede salir en rojo: solo sirve para apps de escritorio Windows y no se usa.

### 2. Descarga el código

```bash
git clone https://github.com/StefanyDev2/stockchef.git
cd stockchef
```

### 3. Conecta la app con Firebase

Los archivos de configuración de Firebase no se suben al repositorio. Cada una los genera así:

1. Pídele a la dueña del proyecto que te agregue en la [consola de Firebase](https://console.firebase.google.com) → proyecto **stockchef** → ⚙️ **Configuración del proyecto** → **Usuarios y permisos** → **Agregar miembro** (rol *Editor*).
2. En la terminal, dentro de la carpeta `stockchef`:

   ```bash
   firebase login
   flutterfire configure --project=stockchef-1a71e --platforms=android --android-package-name=com.stockchef.stockchef --yes
   ```

   Debe terminar diciendo que creó `lib/firebase_options.dart`.

> En Git Bash, si `firebase login` falla con "could not prompt", usa `winpty firebase.cmd login`.

### 4. Instala las dependencias

```bash
flutter pub get
cd functions
npm install
cd ..
```

### 5. Enciende el emulador de Firebase

La app se prueba contra un Firebase que corre en tu propio computador (no gasta nada ni toca los datos reales). En una terminal aparte, y déjala abierta:

```bash
cd functions
npm run emuladores
```

Espera a que diga **"All emulators ready!"**. La primera vez descarga unos archivos, así que tarda un poco.

- Los datos se guardan en `.emulador-datos/` cada 2 minutos y al cerrar con Ctrl+C, y se cargan la próxima vez.
- En http://127.0.0.1:4000 se ven los usuarios y documentos creados.
- Necesita Java 21. En Windows se usa automáticamente el que trae Android Studio.

### 6. Crea los usuarios de prueba (solo la primera vez)

En otra terminal, con el emulador encendido:

```bash
cd functions
npm run sembrar
```

| Correo | Qué ve al entrar |
|---|---|
| `camila@correo.com` | Administradora: Compras, Insumos, Menú, Reportes, Usuarios |
| `daniela@correo.com` | Auxiliar de cocina: Consumo del día, Pérdidas, Platos vendidos, Menú del día |
| `andres@correo.com` | Cuenta sin rol: solo el aviso de rol pendiente |
| `pedro@correo.com` | Cuenta desactivada: no puede entrar |

Todos usan la contraseña `Cocina12` y el restaurante "Sabor Casero". Solo existen en el emulador de tu computador: cada una tiene los suyos.

### 7. Abre la app

Abre un emulador de Android (Android Studio → **Device Manager** → ▶) y luego:

```bash
flutter run --dart-define=USAR_EMULADOR=true
```

La primera compilación tarda varios minutos. Después, con la app abierta, `r` recarga los cambios del código.

### Para la demo: bloqueo de 1 minuto

Por defecto, tres contraseñas equivocadas seguidas bloquean la cuenta **2 horas**. Para mostrarlo en clase, crea el archivo `functions/.env.local` con esta línea y reinicia el emulador de Firebase:

```
BLOQUEO_MINUTOS=1
```

---

## Pruebas

```bash
flutter analyze
flutter test
```

Pruebas de las Cloud Functions (con el emulador de Firebase **apagado**, porque levantan uno propio):

```bash
cd functions
npm run test:todo
```

## Problemas comunes

| Síntoma | Solución |
|---|---|
| `flutter: command not found` | Agrega la carpeta `flutter\bin` al PATH y abre una terminal nueva |
| Falla `lib/firebase_options.dart` al compilar | Falta el paso 3 (`flutterfire configure`) |
| "No se pudo crear la cuenta" o "No se pudo iniciar sesión" | El emulador de Firebase no está encendido (paso 5) |
| `firebase-tools no longer supports Java version before 21` | Instala Android Studio, o un JDK 21, y vuelve a correr `npm run emuladores` |
| El emulador de Android no responde a los clics | Cierra programas pesados (navegador con muchas pestañas, otros IDE); necesita varios GB de RAM libres |
| Sin espacio en disco al compilar | La primera compilación usa varios GB; libera espacio en C: |
