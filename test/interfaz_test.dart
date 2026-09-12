import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketing_strategy_lab/app.dart';
import 'package:marketing_strategy_lab/core/widgets/metrica.dart';
import 'package:marketing_strategy_lab/data/catalogo_mercados.dart';
import 'package:marketing_strategy_lab/domain/models/mercado.dart';
import 'package:marketing_strategy_lab/features/panel/vista_panel.dart';
import 'package:marketing_strategy_lab/features/panel/vm_partida.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pruebas de interfaz.
///
/// No verifican el diseno, verifican que la aplicacion arranque, que la
/// pantalla de inicio ofrezca los tres escenarios y que el tablero de una
/// partida en curso muestre lo que el estudiante necesita para decidir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Las vistas son listas largas: sin una pantalla alta, los widgets de mas
  /// abajo no llegan a construirse y las busquedas fallan por razones que no
  /// tienen que ver con la aplicacion.
  Future<void> pantallaAlta(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1100, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('la aplicacion arranca en la pantalla de inicio',
      (WidgetTester tester) async {
    await pantallaAlta(tester);
    await tester.pumpWidget(const AplicacionMSL());
    await tester.pumpAndSettle();

    expect(find.text('Marketing Strategy Lab'), findsOneWidget);
    for (final Mercado m in CatalogoMercados.todos) {
      expect(find.text(m.nombre), findsOneWidget);
    }
  });

  testWidgets('el tablero de una partida muestra los cinco modulos',
      (WidgetTester tester) async {
    await pantallaAlta(tester);
    final VmPartida vm = VmPartida();
    await vm.iniciar();
    await vm.nuevaPartida(CatalogoMercados.bebida, 'Marca de prueba');

    await tester.pumpWidget(
      AlcancePartida(
        vm: vm,
        child: const MaterialApp(home: VistaPanel()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marca de prueba'), findsOneWidget);
    for (final String modulo in <String>[
      'Mercado',
      'Cliente',
      'Producto',
      'Precio',
      'Campañas',
    ]) {
      expect(find.text(modulo), findsWidgets, reason: 'modulo $modulo');
    }
    expect(find.byType(Metrica), findsWidgets);
    expect(find.textContaining('Cerrar periodo 1'), findsWidgets);
  });

  testWidgets('el tablero avisa cuando no se ha cerrado ningun periodo',
      (WidgetTester tester) async {
    await pantallaAlta(tester);
    final VmPartida vm = VmPartida();
    await vm.iniciar();
    await vm.nuevaPartida(CatalogoMercados.academia, 'Otra marca');

    await tester.pumpWidget(
      AlcancePartida(
        vm: vm,
        child: const MaterialApp(home: VistaPanel()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Todavía no has cerrado ningún periodo'),
        findsOneWidget);
  });
}
