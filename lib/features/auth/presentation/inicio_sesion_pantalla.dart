import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/marca_stockchef.dart';
import '../../../core/widgets/titulo_resaltado.dart';

/// Pantalla de inicio de sesión. Por ahora solo muestra la marca y el
/// acceso al registro; el formulario se construye en HU-001 (CA12) y HU-002.
class InicioSesionPantalla extends StatelessWidget {
  const InicioSesionPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const MarcaStockChef(),
              const SizedBox(height: 12),
              const TituloResaltado('Bienvenido a StockChef'),
              const Spacer(),
              // Ocupa todo el ancho para que la columna quede centrada, y
              // pasa a otra línea en pantallas angostas en vez de salirse.
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      '¿No tienes cuenta?',
                      style: TextStyle(color: AppColors.atenuado),
                    ),
                    TextButton(
                      onPressed: () => context.push(Rutas.registro),
                      child: const Text('Registrarse'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
