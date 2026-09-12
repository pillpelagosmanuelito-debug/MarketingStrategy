import 'package:flutter_test/flutter_test.dart';
import 'package:marketing_strategy_lab/data/catalogo_mercados.dart';
import 'package:marketing_strategy_lab/data/repositorio_partida.dart';
import 'package:marketing_strategy_lab/domain/models/mercado.dart';
import 'package:marketing_strategy_lab/domain/models/partida.dart';
import 'package:marketing_strategy_lab/features/panel/vm_partida.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayuda_simulacion.dart';
import 'politicas.dart';

/// Persistencia local.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Mercado bebida = CatalogoMercados.bebida;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('guardar y cargar devuelve la misma partida', () async {
    final RepositorioPartida repositorio = RepositorioPartida();
    final Partida original = partidaJugada(
        bebida, Politicas.fija(Politicas.nichoPremiumBebida),
        periodos: 2);
    await repositorio.guardar(original);

    final Partida? cargada = await repositorio.cargar();
    expect(cargada, isNotNull);
    expect(cargada!.mercadoId, 'bebida');
    expect(cargada.periodo, original.periodo);
    expect(cargada.historial.length, 2);
    expect(cargada.caja, closeTo(original.caja, 0.0001));
  });

  test('sin partida guardada devuelve null', () async {
    expect(await RepositorioPartida().cargar(), isNull);
  });

  test('una partida corrupta no rompe la aplicacion', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'msl_partida_actual': '{esto no es json valido',
    });
    expect(await RepositorioPartida().cargar(), isNull);
  });

  test('borrar elimina la partida en curso', () async {
    final RepositorioPartida repositorio = RepositorioPartida();
    await repositorio.guardar(partidaJugada(
        bebida, Politicas.fija(Politicas.nichoPremiumBebida),
        periodos: 1));
    await repositorio.borrar();
    expect(await repositorio.cargar(), isNull);
  });

  test('el historial conserva las partidas terminadas mas recientes', () async {
    final RepositorioPartida repositorio = RepositorioPartida();
    for (int i = 0; i < 25; i++) {
      await repositorio.registrar(ResumenPartida(
        mercadoId: 'bebida',
        mercadoNombre: bebida.nombre,
        marca: 'Marca $i',
        fecha: DateTime(2026, 1, 1).add(Duration(days: i)),
        utilidad: 1000.0 * i,
        puntaje: 50 + i.toDouble(),
        quiebra: false,
      ));
    }
    final List<ResumenPartida> historial = await repositorio.historial();
    expect(historial.length, 20);
    expect(historial.first.marca, 'Marca 24');
  });

  group('ViewModel', () {
    test('una partida nueva arranca con decisiones validas', () async {
      final VmPartida vm = VmPartida();
      await vm.nuevaPartida(bebida, 'Prueba');
      expect(vm.hayPartida, isTrue);
      expect(vm.periodo, 0);
      expect(vm.caja, bebida.cajaInicial);
      expect(vm.decisiones.canales, isNotEmpty);
      expect(vm.decisiones.precio, greaterThan(vm.costoUnitario));
      expect(vm.partida!.marca, 'Prueba');
    });

    test('cerrar un periodo avanza el juego y persiste el resultado', () async {
      final VmPartida vm = VmPartida();
      await vm.nuevaPartida(bebida, 'Prueba');
      await vm.cerrarPeriodo();
      expect(vm.periodo, 1);
      expect(vm.partida!.historial.length, 1);
      expect(vm.partida!.decisionesTomadas.length, 1);
      expect(vm.decisiones.investigacion, 0);

      final VmPartida otra = VmPartida();
      await otra.iniciar();
      expect(otra.hayPartida, isTrue);
      expect(otra.periodo, 1);
    });

    test('la partida termina al completar todos los periodos', () async {
      final VmPartida vm = VmPartida();
      await vm.nuevaPartida(bebida, 'Prueba');
      for (int i = 0; i < bebida.periodos; i++) {
        await vm.cerrarPeriodo();
      }
      expect(vm.partida!.terminada, isTrue);
      expect(vm.partida!.historial.length, bebida.periodos);
      expect((await RepositorioPartida().historial()).length, 1);
    });

    test('contratar un estudio descuenta del presupuesto del periodo',
        () async {
      final VmPartida vm = VmPartida();
      await vm.nuevaPartida(bebida, 'Prueba');
      final double antes = vm.disponible;
      vm.contratar(vm.estudiosDisponibles.first, 'fitness');
      expect(vm.decisiones.investigacion,
          vm.estudiosDisponibles.first.costo);
      expect(vm.disponible, lessThan(antes));
      expect(vm.partida!.hallazgos.length, 1);
    });

    test('abandonar borra la partida en curso', () async {
      final VmPartida vm = VmPartida();
      await vm.nuevaPartida(bebida, 'Prueba');
      await vm.abandonar();
      expect(vm.hayPartida, isFalse);
      expect(await RepositorioPartida().cargar(), isNull);
    });
  });
}
