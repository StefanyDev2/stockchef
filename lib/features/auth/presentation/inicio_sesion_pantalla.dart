import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/aviso_error.dart';
import '../../../core/widgets/campo_texto.dart';
import '../../../core/widgets/marca_stockchef.dart';
import '../../../core/widgets/titulo_resaltado.dart';
import '../domain/inicio_sesion.dart';
import 'inicio_sesion_controlador.dart';

/// Inicio de sesión con correo y contraseña (HU-002). Al entrar, las rutas
/// llevan a la pantalla del rol; aquí solo se muestran los errores y el
/// bloqueo por intentos fallidos (pantallas E1, E2 y E3 del prototipo).
class InicioSesionPantalla extends ConsumerStatefulWidget {
  const InicioSesionPantalla({super.key});

  @override
  ConsumerState<InicioSesionPantalla> createState() =>
      _InicioSesionPantallaState();
}

class _InicioSesionPantallaState extends ConsumerState<InicioSesionPantalla> {
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(inicioSesionControladorProvider.notifier)
        .iniciarSesion(
          DatosInicioSesion(correo: _correo.text, contrasena: _contrasena.text),
        );
  }

  void _editado(CampoInicioSesion campo) =>
      ref.read(inicioSesionControladorProvider.notifier).campoEditado(campo);

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(inicioSesionControladorProvider);
    final ocupado = estado.enviando || estado.bloqueado;

    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            children: [
              const Center(child: MarcaStockChef()),
              const SizedBox(height: 12),
              const Center(child: TituloResaltado('Bienvenido a StockChef')),
              const SizedBox(height: 32),
              if (estado.aviso != null) ...[
                AvisoError(estado.aviso!),
                const SizedBox(height: 16),
              ],
              CampoTexto(
                key: const Key('campo-correo'),
                etiqueta: 'Correo electrónico',
                controlador: _correo,
                pista: 'nombre@ejemplo.com',
                error: estado.errores[CampoInicioSesion.correo],
                tipoTeclado: TextInputType.emailAddress,
                autocompletar: const [AutofillHints.email],
                habilitado: !ocupado,
                alCambiar: (_) => _editado(CampoInicioSesion.correo),
              ),
              const SizedBox(height: 14),
              CampoTexto(
                key: const Key('campo-contrasena'),
                etiqueta: 'Contraseña',
                controlador: _contrasena,
                pista: 'Contraseña',
                error: estado.errores[CampoInicioSesion.contrasena],
                esContrasena: true,
                tipoTeclado: TextInputType.visiblePassword,
                accionTeclado: TextInputAction.done,
                autocompletar: const [AutofillHints.password],
                habilitado: !ocupado,
                alCambiar: (_) => _editado(CampoInicioSesion.contrasena),
                alEnviar: (_) => _iniciarSesion(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: ocupado ? null : _iniciarSesion,
                child: estado.enviando
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('INICIAR SESIÓN'),
              ),
              if (estado.bloqueado) ...[
                const SizedBox(height: 12),
                const Text(
                  MensajesInicioSesion.notaBloqueo,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.atenuado),
                ),
              ],
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    '¿No tienes cuenta?',
                    style: TextStyle(color: AppColors.atenuado),
                  ),
                  TextButton(
                    onPressed: estado.enviando
                        ? null
                        : () => context.push(Rutas.registro),
                    child: const Text('Registrarse'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
