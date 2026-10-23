import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formato.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/titulo_resaltado.dart';
import '../../auth/domain/perfil_usuario.dart';
import '../domain/compras.dart';
import 'compras_providers.dart';

/// "Historial de compras" (HU-006, pantalla 2). Si se llega después de
/// guardar, muestra el aviso y el resumen de la compra (CA11). Cada compra
/// muestra su tipo (HU-007, CA5); el administrador además puede filtrar por
/// tipo y ve el resumen de planeadas y de emergencia (HU-007, CA6).
class HistorialComprasPantalla extends ConsumerStatefulWidget {
  const HistorialComprasPantalla({
    super.key,
    required this.usuario,
    this.recienGuardada,
  });

  final PerfilUsuario usuario;
  final Compra? recienGuardada;

  @override
  ConsumerState<HistorialComprasPantalla> createState() =>
      _HistorialComprasPantallaState();
}

class _HistorialComprasPantallaState
    extends ConsumerState<HistorialComprasPantalla> {
  /// `null` muestra todas las compras.
  TipoCompra? _filtro;

  bool get _esAdministrador => widget.usuario.rol == Rol.administrador;

  @override
  Widget build(BuildContext context) {
    final compras = ref.watch(comprasProvider(widget.usuario.restaurantId));
    final recienGuardada = widget.recienGuardada;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Rutas.inicio),
        ),
        title: const TituloResaltado('Historial de compras'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  if (recienGuardada != null) ...[
                    _Resumen(recienGuardada),
                    const SizedBox(height: 24),
                  ],
                  ...compras.when(
                    loading: () => const [
                      Center(
                        child: CircularProgressIndicator(
                          color: AppColors.verde,
                        ),
                      ),
                    ],
                    error: (_, _) => const [Text(MensajesCompras.errorLista)],
                    data: (todas) {
                      final lista = filtrarCompras(todas, _filtro);
                      return [
                        if (_esAdministrador && todas.isNotEmpty) ...[
                          _ResumenPorTipo(resumirPorTipo(todas)),
                          const SizedBox(height: 16),
                          _FiltroTipo(
                            valor: _filtro,
                            alCambiar: (tipo) => setState(() => _filtro = tipo),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (lista.isEmpty)
                          Text(
                            todas.isEmpty
                                ? 'Todavía no hay compras registradas.'
                                : 'No hay compras de este tipo.',
                            style: const TextStyle(color: AppColors.atenuado),
                          ),
                        for (final compra in lista)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TarjetaCompra(compra),
                          ),
                      ];
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: FilledButton(
                onPressed: () => context.pushReplacement(Rutas.compras),
                child: const Text('Registrar otra compra'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CA11: "Compra guardada correctamente" con insumo, cantidad, precio y la
/// nueva cantidad disponible.
class _Resumen extends StatelessWidget {
  const _Resumen(this.compra);

  final Compra compra;

  @override
  Widget build(BuildContext context) {
    const negrita = TextStyle(
      fontWeight: FontWeight.w700,
      color: AppColors.tinta,
    );
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.verdeFondo,
          border: Border.all(color: AppColors.verde),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              MensajesCompras.compraGuardada,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.verdeTexto,
              ),
            ),
            const SizedBox(height: 10),
            Text('Insumo: ${compra.insumoNombre}', style: negrita),
            Text(
              'Cantidad: ${Formato.numero(compra.cantidad)} '
              '${compra.unidad.abreviatura}',
            ),
            Text('Precio: ${Formato.pesos(compra.precioTotal)}'),
            Text(
              'Nueva cantidad disponible: '
              '${Formato.numero(compra.cantidadDisponibleDespues)} '
              '${compra.unidadInsumo.abreviatura}',
              style: negrita,
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaCompra extends StatelessWidget {
  const _TarjetaCompra(this.compra);

  final Compra compra;

  @override
  Widget build(BuildContext context) {
    final emergencia = compra.tipo == TipoCompra.emergencia;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borde),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  compra.insumoNombre,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tinta,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: emergencia ? AppColors.errorFondo : AppColors.durazno,
                  border: Border.all(
                    color: emergencia
                        ? AppColors.error
                        : AppColors.duraznoBorde,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  compra.tipo.etiqueta,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: emergencia
                        ? AppColors.error
                        : AppColors.duraznoTexto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${Formato.numero(compra.cantidad)} ${compra.unidad.abreviatura}',
          ),
          if (compra.proveedor != null) Text('Proveedor: ${compra.proveedor}'),
          Text('Precio total: ${Formato.pesos(compra.precioTotal)}'),
          Text(
            'Precio por ${compra.unidad.etiqueta.toLowerCase()}: '
            '${Formato.pesos(compra.precioUnitario)}',
            style: const TextStyle(color: AppColors.atenuado),
          ),
          if (compra.fecha != null)
            Text(
              Formato.fecha(compra.fecha!),
              style: const TextStyle(color: AppColors.atenuado, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

/// HU-007, CA6: cuántas compras de cada tipo y cuánto se pagó en cada una.
class _ResumenPorTipo extends StatelessWidget {
  const _ResumenPorTipo(this.resumen);

  final Map<TipoCompra, ResumenTipo> resumen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen de compras',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.tinta,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final tipo in TipoCompra.values) ...[
              Expanded(child: _CajaResumen(tipo, resumen[tipo]!)),
              if (tipo != TipoCompra.values.last) const SizedBox(width: 12),
            ],
          ],
        ),
      ],
    );
  }
}

class _CajaResumen extends StatelessWidget {
  const _CajaResumen(this.tipo, this.resumen);

  final TipoCompra tipo;
  final ResumenTipo resumen;

  @override
  Widget build(BuildContext context) {
    final emergencia = tipo == TipoCompra.emergencia;
    final color = emergencia ? AppColors.error : AppColors.duraznoTexto;
    return Container(
      key: Key('resumen-${tipo.name}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: emergencia ? AppColors.errorFondo : AppColors.durazno,
        border: Border.all(
          color: emergencia ? AppColors.error : AppColors.duraznoBorde,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tipo.etiqueta,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            resumen.cantidad == 1 ? '1 compra' : '${resumen.cantidad} compras',
            style: TextStyle(color: color),
          ),
          Text(
            Formato.pesos(resumen.total),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// HU-007, CA6: Todas / Planeadas / Emergencia.
class _FiltroTipo extends StatelessWidget {
  const _FiltroTipo({required this.valor, required this.alCambiar});

  final TipoCompra? valor;
  final ValueChanged<TipoCompra?> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (tipo, etiqueta) in [
          (null, 'Todas'),
          (TipoCompra.planeada, 'Planeadas'),
          (TipoCompra.emergencia, 'Emergencia'),
        ])
          ChoiceChip(
            label: Text(etiqueta),
            selected: valor == tipo,
            selectedColor: AppColors.menta,
            side: BorderSide(
              color: valor == tipo ? AppColors.verde : AppColors.borde,
            ),
            labelStyle: TextStyle(
              fontWeight: valor == tipo ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.tinta,
            ),
            onSelected: (_) => alCambiar(tipo),
          ),
      ],
    );
  }
}
