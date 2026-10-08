import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo y nombre de la marca: "Stock" en tinta y "Chef" en naranja.
class MarcaStockChef extends StatelessWidget {
  const MarcaStockChef({super.key, this.tamano = 32});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontSize: tamano,
      fontWeight: FontWeight.w800,
      color: AppColors.tinta,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('👨‍🍳', style: TextStyle(fontSize: tamano * 1.8)),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: 'Stock',
            style: estilo,
            children: const [
              TextSpan(
                text: 'Chef',
                style: TextStyle(color: AppColors.naranjaMarca),
              ),
            ],
          ),
          semanticsLabel: 'StockChef',
        ),
      ],
    );
  }
}
