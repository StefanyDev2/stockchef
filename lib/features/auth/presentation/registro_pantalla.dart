import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/titulo_resaltado.dart';

/// Pantalla de registro de usuario (HU-001). El formulario se agrega en el
/// bloque de pantallas; por ahora solo tiene el encabezado y la navegación.
class RegistroPantalla extends StatelessWidget {
  const RegistroPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () => _volverAlInicio(context),
        ),
        title: const TituloResaltado('Registro de usuario'),
      ),
      body: SafeArea(
        child: Center(
          child: TextButton(
            onPressed: () => _volverAlInicio(context),
            child: const Text('¿Ya tienes cuenta? Inicia sesión'),
          ),
        ),
      ),
    );
  }

  void _volverAlInicio(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Rutas.inicioSesion);
    }
  }
}
