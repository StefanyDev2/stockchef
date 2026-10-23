import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/aviso_error.dart';
import '../../../core/widgets/titulo_resaltado.dart';
import '../../auth/domain/perfil_usuario.dart';
import '../domain/insumos.dart';
import 'insumos_providers.dart';

/// "Insumos" del administrador (HU-004): marca cuáles son críticos y guarda
/// la lista completa con "Guardar cambios".
class InsumosCriticosPantalla extends ConsumerStatefulWidget {
  const InsumosCriticosPantalla({super.key, required this.administrador});

  final PerfilUsuario administrador;

  @override
  ConsumerState<InsumosCriticosPantalla> createState() =>
      _InsumosCriticosPantallaState();
}

class _InsumosCriticosPantallaState
    extends ConsumerState<InsumosCriticosPantalla> {
  /// Lo que está guardado y lo que el administrador va marcando.
  Set<String>? _guardados;
  Set<String> _elegidos = {};

  bool _guardando = false;
  String? _error;
  bool _exito = false;

  bool get _hayCambios =>
      _guardados != null &&
      (_guardados!.length != _elegidos.length ||
          !_guardados!.containsAll(_elegidos));

  /// Toma la clasificación guardada cada vez que llegan los insumos, mientras
  /// no haya cambios sin guardar. Firestore puede mandar primero una copia
  /// local vieja y después la del servidor; así se muestra siempre la última.
  void _sincronizar(List<InsumoRegistrado> insumos) {
    if (_hayCambios) return;
    _guardados = {
      for (final i in insumos)
        if (i.critico) i.id,
    };
    _elegidos = {..._guardados!};
  }

  void _cambiar(String id, bool critico) => setState(() {
    critico ? _elegidos.add(id) : _elegidos.remove(id);
    _exito = false;
    _error = null;
  });

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
      _exito = false;
    });
    final resultado = await ref
        .read(insumosRepositorioProvider)
        .guardarCriticos({..._elegidos});
    if (!mounted) return;
    setState(() => _guardando = false);

    switch (resultado) {
      case ListaGuardada():
        setState(() {
          _guardados = {..._elegidos};
          _exito = true;
        });
      case ListaRechazada(:final mensaje):
        setState(() => _error = mensaje);
      case ListaSinPermiso():
        context.go(Rutas.sinPermiso);
    }
  }

  Future<void> _volver() async {
    if (_hayCambios && !await _confirmarSalida()) return;
    if (!mounted) return;
    context.canPop() ? context.pop() : context.go(Rutas.inicio);
  }

  Future<bool> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(MensajesInsumos.cambiosSinGuardar),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir sin guardar'),
          ),
        ],
      ),
    );
    return salir ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final insumos = ref.watch(
      insumosRegistradosProvider(widget.administrador.restaurantId),
    );

    return PopScope(
      canPop: !_hayCambios,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _volver();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
            onPressed: _guardando ? null : _volver,
          ),
          title: const TituloResaltado('Insumos'),
        ),
        body: SafeArea(
          child: insumos.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.verde),
            ),
            error: (_, _) =>
                const Center(child: Text(MensajesInsumos.errorLista)),
            data: (lista) {
              _sincronizar(lista);
              return lista.isEmpty
                  ? const Center(child: Text(MensajesInsumos.sinInsumos))
                  : _contenido(lista);
            },
          ),
        ),
      ),
    );
  }

  Widget _contenido(List<InsumoRegistrado> insumos) {
    final grupos = separarPorCriticidad(insumos, _elegidos);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              if (_exito) ...[
                const _AvisoExito(MensajesInsumos.guardado),
                const SizedBox(height: 16),
              ],
              if (_error != null) ...[
                AvisoError(_error!),
                const SizedBox(height: 16),
              ],
              const Text(
                'Marca los insumos que requieren mayor control.',
                style: TextStyle(color: AppColors.atenuado),
              ),
              const SizedBox(height: 20),
              _Seccion(
                clave: const Key('seccion-criticos'),
                titulo: 'Insumos críticos (${grupos.criticos.length})',
                vacio: MensajesInsumos.sinCriticos,
                insumos: grupos.criticos,
                elegidos: _elegidos,
                habilitado: !_guardando,
                alCambiar: _cambiar,
              ),
              const SizedBox(height: 24),
              _Seccion(
                clave: const Key('seccion-otros'),
                titulo: 'Otros insumos (${grupos.otros.length})',
                vacio: MensajesInsumos.sinOtros,
                insumos: grupos.otros,
                elegidos: _elegidos,
                habilitado: !_guardando,
                alCambiar: _cambiar,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: FilledButton(
            onPressed: _hayCambios && !_guardando ? _guardar : null,
            child: _guardando
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Guardar cambios'),
          ),
        ),
      ],
    );
  }
}

/// CA6: una sección de la lista (críticos u otros).
class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.clave,
    required this.titulo,
    required this.vacio,
    required this.insumos,
    required this.elegidos,
    required this.habilitado,
    required this.alCambiar,
  });

  final Key clave;
  final String titulo;
  final String vacio;
  final List<InsumoRegistrado> insumos;
  final Set<String> elegidos;
  final bool habilitado;
  final void Function(String id, bool critico) alCambiar;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: clave,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.tinta,
          ),
        ),
        const SizedBox(height: 10),
        if (insumos.isEmpty)
          Text(vacio, style: const TextStyle(color: AppColors.atenuado)),
        for (final insumo in insumos)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TarjetaInsumo(
              insumo: insumo,
              critico: elegidos.contains(insumo.id),
              habilitado: habilitado,
              alCambiar: (critico) => alCambiar(insumo.id, critico),
            ),
          ),
      ],
    );
  }
}

/// CA4: nombre y "Crítico" o "No crítico"; el interruptor lo cambia (CA3).
class _TarjetaInsumo extends StatelessWidget {
  const _TarjetaInsumo({
    required this.insumo,
    required this.critico,
    required this.habilitado,
    required this.alCambiar,
  });

  final InsumoRegistrado insumo;
  final bool critico;
  final bool habilitado;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('insumo-${insumo.id}'),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: critico ? AppColors.errorFondo : AppColors.fondo,
        border: Border.all(color: critico ? AppColors.error : AppColors.borde),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insumo.nombre,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tinta,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Etiqueta(
                      critico ? 'Crítico' : 'No crítico',
                      fondo: critico
                          ? AppColors.error
                          : AppColors.campoDeshabilitado,
                      color: critico ? Colors.white : AppColors.tinta,
                    ),
                    if (!insumo.activo)
                      const _Etiqueta(
                        'Inactivo',
                        fondo: AppColors.campoDeshabilitado,
                        color: AppColors.atenuado,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: critico,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.error,
            onChanged: habilitado ? alCambiar : null,
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto, {required this.fondo, required this.color});

  final String texto;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _AvisoExito extends StatelessWidget {
  const _AvisoExito(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.menta,
          border: Border.all(color: AppColors.verde),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.verdeTexto,
          ),
        ),
      ),
    );
  }
}
