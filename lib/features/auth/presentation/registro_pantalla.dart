import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/aviso_error.dart';
import '../../../core/widgets/campo_texto.dart';
import '../../../core/widgets/titulo_resaltado.dart';
import '../domain/datos_registro.dart';
import '../domain/mensajes_validacion.dart';
import 'registro_controlador.dart';

/// Formulario de registro de usuario (HU-001).
class RegistroPantalla extends ConsumerStatefulWidget {
  const RegistroPantalla({super.key});

  @override
  ConsumerState<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends ConsumerState<RegistroPantalla> {
  final _controladores = {
    for (final campo in CampoRegistro.values) campo: TextEditingController(),
  };

  @override
  void dispose() {
    for (final controlador in _controladores.values) {
      controlador.dispose();
    }
    super.dispose();
  }

  String _texto(CampoRegistro campo) => _controladores[campo]!.text;

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    final datos = DatosRegistro(
      nombres: _texto(CampoRegistro.nombres),
      apellidos: _texto(CampoRegistro.apellidos),
      correo: _texto(CampoRegistro.correo),
      restaurante: _texto(CampoRegistro.restaurante),
      contrasena: _texto(CampoRegistro.contrasena),
      confirmacion: _texto(CampoRegistro.confirmacion),
    );
    final creada = await ref
        .read(registroControladorProvider.notifier)
        .registrar(datos);
    if (creada && mounted) {
      TextInput.finishAutofillContext();
      context.go(Rutas.cuentaCreada);
    }
  }

  void _volverAlInicio() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Rutas.inicioSesion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(registroControladorProvider);

    Widget campo(
      CampoRegistro campo, {
      String? pista,
      String? ayuda,
      bool esContrasena = false,
      TextInputType? tipoTeclado,
      TextInputAction accion = TextInputAction.next,
      TextCapitalization mayusculas = TextCapitalization.none,
      Iterable<String>? autocompletar,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: CampoTexto(
          key: Key('campo-${campo.name}'),
          etiqueta: campo.etiqueta,
          controlador: _controladores[campo]!,
          pista: pista,
          error: estado.errores[campo],
          ayuda: ayuda,
          esContrasena: esContrasena,
          tipoTeclado: tipoTeclado,
          accionTeclado: accion,
          mayusculas: mayusculas,
          autocompletar: autocompletar,
          habilitado: !estado.enviando,
          alCambiar: (_) => ref
              .read(registroControladorProvider.notifier)
              .campoEditado(campo),
          alEnviar: accion == TextInputAction.done ? (_) => _registrar() : null,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: _volverAlInicio,
        ),
        title: const TituloResaltado('Registro de usuario'),
      ),
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              if (estado.aviso != null) ...[
                AvisoError(estado.aviso!),
                const SizedBox(height: 16),
              ],
              campo(
                CampoRegistro.nombres,
                pista: 'Ej. Camila',
                mayusculas: TextCapitalization.words,
                autocompletar: const [AutofillHints.givenName],
              ),
              campo(
                CampoRegistro.apellidos,
                pista: 'Ej. Ruiz',
                mayusculas: TextCapitalization.words,
                autocompletar: const [AutofillHints.familyName],
              ),
              campo(
                CampoRegistro.correo,
                pista: 'nombre@ejemplo.com',
                tipoTeclado: TextInputType.emailAddress,
                autocompletar: const [AutofillHints.email],
              ),
              campo(
                CampoRegistro.restaurante,
                pista: 'Nombre del restaurante',
                mayusculas: TextCapitalization.words,
                autocompletar: const [AutofillHints.organizationName],
              ),
              campo(
                CampoRegistro.contrasena,
                pista: 'Contraseña',
                ayuda: MensajesValidacion.ayudaContrasena,
                esContrasena: true,
                tipoTeclado: TextInputType.visiblePassword,
                autocompletar: const [AutofillHints.newPassword],
              ),
              campo(
                CampoRegistro.confirmacion,
                pista: 'Repite la contraseña',
                esContrasena: true,
                tipoTeclado: TextInputType.visiblePassword,
                accion: TextInputAction.done,
                autocompletar: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: estado.enviando ? null : _registrar,
                child: estado.enviando
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Registrarse'),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: estado.enviando ? null : _volverAlInicio,
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
