import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/marca_stockchef.dart';

/// Se ve un instante al abrir la app, mientras se revisa si quedó una sesión
/// abierta (HU-002, CA13).
class CargandoPantalla extends StatelessWidget {
  const CargandoPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MarcaStockChef(),
            SizedBox(height: 32),
            CircularProgressIndicator(color: AppColors.verde),
          ],
        ),
      ),
    );
  }
}
