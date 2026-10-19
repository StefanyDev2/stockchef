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
/// guardar, muestra el aviso y el resumen de la compra (CA11).
class HistorialComprasPantalla extends ConsumerWidget {
  const HistorialComprasPantalla({
    super.key,
    required this.administrador,
    this.recienGuardada,
  });

  final PerfilUsuario administrador;
  final Compra? recienGuardada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compras = ref.watch(comprasProvider(administrador.restaurantId));

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
                    _Resumen(recienGuardada!),
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
                    data: (lista) => [
                      if (lista.isEmpty)
                        const Text(
                          'Todavía no hay compras registradas.',
                          style: TextStyle(color: AppColors.atenuado),
                        ),
                      for (final compra in lista)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TarjetaCompra(compra),
                        ),
                    ],
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
