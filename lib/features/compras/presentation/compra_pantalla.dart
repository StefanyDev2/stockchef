import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formato.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/aviso_error.dart';
import '../../../core/widgets/campo_texto.dart';
import '../../../core/widgets/titulo_resaltado.dart';
import '../../auth/domain/perfil_usuario.dart';
import '../domain/compras.dart';
import '../domain/unidades.dart';
import 'compras_providers.dart';

/// Formulario "Compra de insumos" (HU-006). Solo lo abre el administrador.
class CompraPantalla extends ConsumerStatefulWidget {
  const CompraPantalla({super.key, required this.administrador});

  final PerfilUsuario administrador;

  @override
  ConsumerState<CompraPantalla> createState() => _CompraPantallaState();
}

class _CompraPantallaState extends ConsumerState<CompraPantalla> {
  final _cantidad = TextEditingController();
  final _proveedor = TextEditingController();
  final _precio = TextEditingController();

  TipoCompra _tipo = TipoCompra.planeada;
  String? _insumoId;
  UnidadMedida? _unidad;

  Map<CampoCompra, String> _errores = const {};
  String? _aviso;
  bool _guardando = false;

  @override
  void dispose() {
    _cantidad.dispose();
    _proveedor.dispose();
    _precio.dispose();
    super.dispose();
  }

  DatosCompra get _datos => DatosCompra(
    insumoId: _insumoId,
    cantidad: _cantidad.text,
    unidad: _unidad,
    proveedor: _proveedor.text,
    precio: _precio.text,
    tipo: _tipo,
  );

  /// Al corregir un campo se quita su error; el aviso se va cuando ya no
  /// queda ninguno.
  void _corregido(CampoCompra campo) {
    if (!_errores.containsKey(campo)) return;
    setState(() {
      _errores = Map.of(_errores)..remove(campo);
      if (_errores.isEmpty) _aviso = null;
    });
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final datos = _datos;
    final validacion = datos.validar();
    if (!validacion.esValida) {
      setState(() {
        _errores = validacion.errores;
        _aviso = validacion.aviso;
      });
      return;
    }

    setState(() {
      _guardando = true;
      _errores = const {};
      _aviso = null;
    });
    final resultado = await ref
        .read(comprasRepositorioProvider)
        .registrar(datos);
    if (!mounted) return;
    setState(() => _guardando = false);

    switch (resultado) {
      case CompraGuardada(:final compra):
        context.pushReplacement(Rutas.historialCompras, extra: compra);
      case CompraRechazada(:final mensaje, :final pendientes):
        setState(() {
          _aviso = mensaje;
          _errores = {
            for (final campo in pendientes)
              campo: MensajesCompras.campoObligatorio,
          };
        });
      case CompraSinPermiso():
        context.go(Rutas.sinPermiso);
    }
  }

  void _volver() => context.canPop() ? context.pop() : context.go(Rutas.inicio);

  @override
  Widget build(BuildContext context) {
    final insumos = ref.watch(
      insumosActivosProvider(widget.administrador.restaurantId),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: _guardando ? null : _volver,
        ),
        title: const TituloResaltado('Compra de insumos'),
      ),
      body: SafeArea(
        child: insumos.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.verde),
          ),
          error: (_, _) =>
              const Center(child: Text(MensajesCompras.errorLista)),
          data: (lista) => lista.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      MensajesCompras.sinInsumos,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _formulario(lista),
        ),
      ),
    );
  }

  Widget _formulario(List<Insumo> insumos) {
    final elegido = insumos.where((i) => i.id == _insumoId).firstOrNull;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        if (_aviso != null) ...[
          AvisoError(_aviso!),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            for (final tipo in TipoCompra.values) ...[
              Expanded(
                child: _BotonTipo(
                  tipo: tipo,
                  elegido: _tipo == tipo,
                  alElegir: _guardando
                      ? null
                      : () => setState(() => _tipo = tipo),
                ),
              ),
              if (tipo != TipoCompra.values.last) const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: 20),
        _Lista<String>(
          clave: const Key('campo-insumo'),
          etiqueta: 'Insumo',
          pista: 'Elige un insumo',
          valor: _insumoId,
          error: _errores[CampoCompra.insumo],
          opciones: {for (final i in insumos) i.id: i.nombre},
          habilitado: !_guardando,
          alCambiar: (id) {
            setState(() {
              _insumoId = id;
              // Se propone la unidad del insumo; se puede cambiar.
              _unidad ??= insumos.firstWhere((i) => i.id == id).unidad;
            });
            _corregido(CampoCompra.insumo);
            _corregido(CampoCompra.unidad);
          },
        ),
        if (elegido != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Disponible: ${_cantidadConUnidad(elegido.cantidadDisponible, elegido.unidad)}',
              style: const TextStyle(color: AppColors.atenuado),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoTexto(
                key: const Key('campo-cantidad'),
                etiqueta: 'Cantidad',
                controlador: _cantidad,
                pista: 'Ej. 10',
                error: _errores[CampoCompra.cantidad],
                tipoTeclado: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                habilitado: !_guardando,
                alCambiar: (_) => _corregido(CampoCompra.cantidad),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Lista<UnidadMedida>(
                clave: const Key('campo-unidad'),
                etiqueta: 'Unidad',
                pista: 'Elige',
                valor: _unidad,
                error: _errores[CampoCompra.unidad],
                opciones: {for (final u in UnidadMedida.values) u: u.etiqueta},
                habilitado: !_guardando,
                alCambiar: (unidad) {
                  setState(() => _unidad = unidad);
                  _corregido(CampoCompra.unidad);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        CampoTexto(
          key: const Key('campo-proveedor'),
          etiqueta: 'Proveedor (opcional)',
          controlador: _proveedor,
          pista: 'Ej. Distrialimentos',
          mayusculas: TextCapitalization.words,
          habilitado: !_guardando,
        ),
        const SizedBox(height: 14),
        CampoTexto(
          key: const Key('campo-precio'),
          etiqueta: 'Precio total',
          controlador: _precio,
          pista: r'Ej. $50.000',
          error: _errores[CampoCompra.precio],
          tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
          accionTeclado: TextInputAction.done,
          habilitado: !_guardando,
          alCambiar: (_) => _corregido(CampoCompra.precio),
          alEnviar: (_) => _guardar(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Guardar compra'),
        ),
      ],
    );
  }
}

String _cantidadConUnidad(num cantidad, UnidadMedida unidad) =>
    '${Formato.numero(cantidad)} ${unidad.abreviatura}';

/// Lista desplegable con la etiqueta encima, como los campos de texto.
class _Lista<T> extends StatelessWidget {
  const _Lista({
    required this.clave,
    required this.etiqueta,
    required this.pista,
    required this.valor,
    required this.error,
    required this.opciones,
    required this.habilitado,
    required this.alCambiar,
  });

  final Key clave;
  final String etiqueta;
  final String pista;
  final T? valor;
  final String? error;
  final Map<T, String> opciones;
  final bool habilitado;
  final ValueChanged<T> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.tinta,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          key: clave,
          initialValue: valor,
          isExpanded: true,
          hint: Text(pista),
          decoration: InputDecoration(errorText: error),
          items: [
            for (final MapEntry(:key, :value) in opciones.entries)
              DropdownMenuItem(value: key, child: Text(value)),
          ],
          onChanged: habilitado
              ? (nuevo) {
                  if (nuevo != null) alCambiar(nuevo);
                }
              : null,
        ),
      ],
    );
  }
}

/// "Planeada" / "Emergencia" del prototipo: durazno el elegido.
class _BotonTipo extends StatelessWidget {
  const _BotonTipo({
    required this.tipo,
    required this.elegido,
    required this.alElegir,
  });

  final TipoCompra tipo;
  final bool elegido;
  final VoidCallback? alElegir;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: elegido,
      button: true,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: elegido ? AppColors.naranja : AppColors.fondo,
          foregroundColor: AppColors.tinta,
          side: BorderSide(
            color: elegido ? AppColors.naranja : AppColors.borde,
          ),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: TextStyle(
            fontWeight: elegido ? FontWeight.w800 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onPressed: alElegir,
        child: Text(tipo.etiqueta),
      ),
    );
  }
}
