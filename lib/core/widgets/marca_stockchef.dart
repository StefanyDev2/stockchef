import 'package:flutter/material.dart';

/// Logo oficial de StockChef (gorro de chef, lista, insumos y el lema
/// "Controla hoy, crece mañana."), en assets/imagenes/logo_stockchef.webp.
class MarcaStockChef extends StatelessWidget {
  const MarcaStockChef({super.key, this.ancho = 260});

  /// Ancho máximo del logo. En pantallas angostas se ajusta solo.
  final double ancho;

  static const ruta = 'assets/imagenes/logo_stockchef.webp';

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: ancho),
      child: const AspectRatio(
        aspectRatio: 1,
        child: Image(
          image: AssetImage(ruta),
          fit: BoxFit.contain,
          semanticLabel: 'StockChef',
        ),
      ),
    );
  }
}
