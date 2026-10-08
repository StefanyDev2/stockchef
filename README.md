# StockChef

Control de compras, consumo y pérdidas de insumos para restaurantes pequeños de menú del día.
Proyecto universitario de Ingeniería de Software (Scrum).

- Contexto, alcance y reglas de trabajo: [`CLAUDE.md`](CLAUDE.md)
- Historias de usuario, prototipos y modelo de datos: [`docs/`](docs/)

## Requisitos

- Flutter (canal stable) con el SDK de Android
- Node.js 20, `firebase-tools` y `flutterfire_cli`

## Configuración local

Los archivos de configuración de Firebase **no** están en el repositorio. Cada integrante los genera con su cuenta:

```bash
flutterfire configure
```

## Ejecutar

```bash
flutter pub get
flutter run
```

## Verificar

```bash
flutter analyze
flutter test
```

## Probar con el emulador de Firebase

Sin tocar el proyecto real ni pagar el plan Blaze:

```bash
cd functions
npm install
npm run emuladores
```

Los datos se guardan en `.emulador-datos/` cada 2 minutos y al cerrar con Ctrl+C, y se cargan la próxima vez.
En otra terminal, la primera vez, crea los usuarios de prueba:

```bash
cd functions
npm run sembrar
```

| Correo | Caso |
|---|---|
| `camila@correo.com` | Administrador |
| `daniela@correo.com` | Auxiliar de cocina |
| `andres@correo.com` | Sin rol |
| `pedro@correo.com` | Cuenta desactivada |

Todos usan la contraseña `Cocina12` y el restaurante "Sabor Casero". Solo existen en el emulador.

Luego abre la app conectada al emulador:

```bash
flutter run --dart-define=USAR_EMULADOR=true
```

Para probar el bloqueo sin esperar 2 horas, crea `functions/.env.local` con `BLOQUEO_MINUTOS=1` y reinicia los emuladores.

Pruebas de las Cloud Functions: `npm run test:todo` dentro de `functions/` (con los emuladores apagados).
