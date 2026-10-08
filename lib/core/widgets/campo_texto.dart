import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Campo de formulario con la etiqueta en negrita encima, como en los
/// prototipos. Si es de contraseña, el texto va oculto y un ícono de ojo
/// permite verlo.
class CampoTexto extends StatefulWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.pista,
    this.error,
    this.ayuda,
    this.esContrasena = false,
    this.tipoTeclado,
    this.accionTeclado = TextInputAction.next,
    this.mayusculas = TextCapitalization.none,
    this.autocompletar,
    this.habilitado = true,
    this.alCambiar,
    this.alEnviar,
  });

  final String etiqueta;
  final TextEditingController controlador;
  final String? pista;
  final String? error;

  /// Texto gris bajo el campo cuando no hay error.
  final String? ayuda;
  final bool esContrasena;
  final TextInputType? tipoTeclado;
  final TextInputAction accionTeclado;
  final TextCapitalization mayusculas;
  final Iterable<String>? autocompletar;
  final bool habilitado;
  final ValueChanged<String>? alCambiar;
  final ValueChanged<String>? alEnviar;

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  bool _oculto = true;

  /// El ojo no recibe el foco con "Siguiente" del teclado; así el foco pasa
  /// directo al campo siguiente. Se sigue usando al tocarlo.
  final _focoOjo = FocusNode(skipTraversal: true);

  @override
  void dispose() {
    _focoOjo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ocultar = widget.esContrasena && _oculto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.etiqueta,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.tinta,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controlador,
          enabled: widget.habilitado,
          obscureText: ocultar,
          enableSuggestions: !widget.esContrasena,
          autocorrect: false,
          keyboardType: widget.tipoTeclado,
          textInputAction: widget.accionTeclado,
          textCapitalization: widget.mayusculas,
          autofillHints: widget.autocompletar,
          onChanged: widget.alCambiar,
          onSubmitted: widget.alEnviar,
          decoration: InputDecoration(
            hintText: widget.pista,
            errorText: widget.error,
            helperText: widget.error == null ? widget.ayuda : null,
            suffixIcon: widget.esContrasena
                ? IconButton(
                    focusNode: _focoOjo,
                    icon: Icon(
                      _oculto ? Icons.visibility_off : Icons.visibility,
                    ),
                    color: AppColors.atenuado,
                    tooltip: _oculto
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: () => setState(() => _oculto = !_oculto),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
