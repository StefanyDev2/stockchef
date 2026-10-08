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
