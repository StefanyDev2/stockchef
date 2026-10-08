import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockchef/app.dart';

void main() {
  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: StockChefApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('abre en el inicio de sesión con la marca StockChef', (
    tester,
  ) async {
    await abrirApp(tester);

    expect(find.bySemanticsLabel('StockChef'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
  });

  testWidgets('"Registrarse" abre el registro y la flecha vuelve', (
    tester,
  ) async {
    await abrirApp(tester);

    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();
    expect(find.text('Registro de usuario'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Registrarse'), findsOneWidget);
    expect(find.text('Registro de usuario'), findsNothing);
  });

  testWidgets('"¿Ya tienes cuenta? Inicia sesión" vuelve al inicio', (
    tester,
  ) async {
    await abrirApp(tester);

    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();
    final enlace = find.text('¿Ya tienes cuenta? Inicia sesión');
    await tester.scrollUntilVisible(
      enlace,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(enlace);
    await tester.pumpAndSettle();

    expect(find.text('Registrarse'), findsOneWidget);
    expect(find.text('Registro de usuario'), findsNothing);
  });
}
