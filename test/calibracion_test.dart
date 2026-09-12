import 'package:flutter_test/flutter_test.dart';
import 'package:marketing_strategy_lab/data/catalogo_mercados.dart';
import 'package:marketing_strategy_lab/domain/models/decisiones.dart';
import 'package:marketing_strategy_lab/domain/models/medio.dart';
import 'package:marketing_strategy_lab/domain/models/mercado.dart';
import 'package:marketing_strategy_lab/domain/models/resultado_periodo.dart';

import 'ayuda_simulacion.dart';
import 'politicas.dart';

/// Pruebas de calibracion: la red de seguridad pedagogica.
///
/// No verifican funciones, verifican que cada escenario premie lo que dice
/// premiar. Si alguna falla despues de tocar un parametro, el simulador dejo
/// de ensenar lo que dice ensenar, aunque todas las pruebas unitarias pasen.
void main() {
  final Mercado bebida = CatalogoMercados.bebida;
  final Mercado mochilas = CatalogoMercados.mochilas;
  final Mercado academia = CatalogoMercados.academia;

  Corrida correr(Mercado m, Decisiones d) =>
      jugar(m, Politicas.fija(d));

  group('Bebida funcional: el nicho de valor gana, el volumen no', () {
    late Corrida nicho;
    late Corrida imagen;
    late Corrida masivo;
    late Corrida promedio;

    setUp(() {
      nicho = correr(bebida, Politicas.nichoPremiumBebida);
      imagen = correr(bebida, Politicas.imagenJovenBebida);
      masivo = correr(bebida, Politicas.masivoBaratoBebida);
      promedio = correr(bebida, Politicas.promedioBebida);
    });

    test('las dos estrategias de nicho superan al ataque masivo', () {
      expect(nicho.utilidadAcumulada, greaterThan(masivo.utilidadAcumulada));
      expect(imagen.utilidadAcumulada, greaterThan(masivo.utilidadAcumulada));
    });

    test('pelear por volumen contra el lider deja menos de un tercio', () {
      expect(masivo.utilidadAcumulada,
          lessThan(imagen.utilidadAcumulada * 0.33));
    });

    test('el producto promedio para todos rinde al menos 20% menos que el '
        'mejor enfoque', () {
      expect(promedio.utilidadAcumulada,
          lessThan(imagen.utilidadAcumulada * 0.80));
    });

    test('decidir sin investigar (segmento equivocado) cuesta mas de la mitad',
        () {
      final Corrida ciegas = correr(bebida, Politicas.aCiegasBebida);
      expect(ciegas.utilidadAcumulada,
          lessThan(imagen.utilidadAcumulada * 0.5));
    });
  });

  group('Mochilas: aqui el volumen si manda', () {
    late Corrida masivo;
    late Corrida nicho;
    late Corrida promedio;

    setUp(() {
      masivo = correr(mochilas, Politicas.masivoBaratoMochilas);
      nicho = correr(mochilas, Politicas.nichoPremiumMochilas);
      promedio = correr(mochilas, Politicas.promedioMochilas);
    });

    test('la penetracion supera al premium por mas de 1.5 veces', () {
      expect(masivo.utilidadAcumulada,
          greaterThan(nicho.utilidadAcumulada * 1.5));
    });

    test('el promedio para todos no llega ni al 10% del mejor', () {
      expect(promedio.utilidadAcumulada,
          lessThan(masivo.utilidadAcumulada * 0.10));
    });

    test('la mezcla premium en canales masivos termina en quiebra', () {
      final Corrida ciegas = correr(mochilas, Politicas.aCiegasMochilas);
      expect(ciegas.quiebra, isTrue);
    });
  });

  group('Academia: el territorio del lider no se ataca de frente', () {
    late Corrida flexible;
    late Corrida premium;
    late Corrida promedio;
    late Corrida masivo;

    setUp(() {
      flexible = correr(academia, Politicas.flexibleAcademia);
      premium = correr(academia, Politicas.nichoPremiumAcademia);
      promedio = correr(academia, Politicas.promedioAcademia);
      masivo = correr(academia, Politicas.masivoBaratoAcademia);
    });

    test('el segmento desatendido rinde mas que el disputado', () {
      expect(flexible.utilidadAcumulada,
          greaterThan(premium.utilidadAcumulada));
    });

    test('el orden completo del escenario se mantiene', () {
      expect(premium.utilidadAcumulada,
          greaterThan(promedio.utilidadAcumulada));
      expect(promedio.utilidadAcumulada,
          greaterThan(masivo.utilidadAcumulada));
    });

    test('reposicionar a mitad de camino no recupera la ventaja de haber '
        'elegido bien desde el principio', () {
      final Corrida reposiciona = jugar(
        academia,
        (int periodo) => periodo < 3
            ? Politicas.nichoPremiumAcademia
            : Politicas.flexibleAcademia,
      );
      expect(reposiciona.utilidadAcumulada,
          lessThan(flexible.utilidadAcumulada));
    });
  });

  group('Ninguna estrategia domina los tres mercados', () {
    test('la que gana en mochilas pierde en bebida y en academia', () {
      final double masivoBebida =
          correr(bebida, Politicas.masivoBaratoBebida).utilidadAcumulada;
      final double nichoBebida =
          correr(bebida, Politicas.imagenJovenBebida).utilidadAcumulada;
      final double masivoAcademia =
          correr(academia, Politicas.masivoBaratoAcademia).utilidadAcumulada;
      final double flexibleAcademia =
          correr(academia, Politicas.flexibleAcademia).utilidadAcumulada;
      expect(masivoBebida, lessThan(nichoBebida));
      expect(masivoAcademia, lessThan(flexibleAcademia));
    });

    test('la que gana en bebida pierde en mochilas', () {
      final double premiumMochilas =
          correr(mochilas, Politicas.nichoPremiumMochilas).utilidadAcumulada;
      final double masivoMochilas =
          correr(mochilas, Politicas.masivoBaratoMochilas).utilidadAcumulada;
      expect(premiumMochilas, lessThan(masivoMochilas));
    });
  });

  group('Prometer mas de lo que se entrega se paga', () {
    test('la satisfaccion se desploma en los tres mercados', () {
      for (final Mercado m in <Mercado>[bebida, mochilas, academia]) {
        final Decisiones d = m.id == 'bebida'
            ? Politicas.promesaIncumplidaBebida
            : m.id == 'mochilas'
                ? Politicas.promesaIncumplidaMochilas
                : Politicas.promesaIncumplidaAcademia;
        final Corrida p = correr(m, d);
        expect(p.satisfaccionPromedio, lessThan(0.20),
            reason: 'satisfaccion en ${m.id}');
      }
    });

    test('y ademas cuesta mas de la mitad de la utilidad', () {
      final Corrida honesta = correr(bebida, Politicas.nichoPremiumBebida);
      final Corrida mentirosa =
          correr(bebida, Politicas.promesaIncumplidaBebida);
      expect(mentirosa.utilidadAcumulada,
          lessThan(honesta.utilidadAcumulada * 0.5));
      expect(mentirosa.participacionFinal,
          lessThan(honesta.participacionFinal * 0.6));
    });
  });

  group('Los extremos no son estrategias', () {
    test('vender por debajo del costo lleva a la quiebra en los tres mercados',
        () {
      expect(correr(bebida, Politicas.regaladoBebida).quiebra, isTrue);
      expect(correr(mochilas, Politicas.regaladoMochilas).quiebra, isTrue);
      expect(correr(academia, Politicas.regaladoAcademia).quiebra, isTrue);
    });

    test('no invertir en medios deja la marca sin ventas y con perdida', () {
      final Corrida p = correr(bebida, Politicas.sinMediosBebida);
      expect(p.utilidadAcumulada, lessThan(0));
      expect(p.participacionFinal, lessThan(0.02));
    });
  });

  group('Ningun efecto llega a 0 ni a 1', () {
    test('la satisfaccion y la participacion se mantienen dentro de rango', () {
      for (final Mercado m in <Mercado>[bebida, mochilas, academia]) {
        for (final Decisiones d in <Decisiones>[
          m.id == 'bebida'
              ? Politicas.nichoPremiumBebida
              : m.id == 'mochilas'
                  ? Politicas.masivoBaratoMochilas
                  : Politicas.flexibleAcademia,
        ]) {
          final Corrida p = correr(m, d);
          for (final ResultadoPeriodo r in p.historial) {
            expect(r.satisfaccion, greaterThan(0.02));
            expect(r.satisfaccion, lessThan(0.98));
            expect(r.participacion, lessThan(0.95));
            for (final ResultadoSegmento s in r.segmentos) {
              expect(s.awareness, lessThanOrEqualTo(0.92));
              expect(s.cobertura, lessThanOrEqualTo(0.95));
            }
          }
        }
      }
    });

    test('duplicar la inversion en medios no duplica las ventas', () {
      final Corrida base = correr(bebida, Politicas.nichoPremiumBebida);
      final Map<Medio, double> dobles = <Medio, double>{};
      Politicas.nichoPremiumBebida.medios.forEach((Medio m, double v) {
        dobles[m] = v * 2;
      });
      final Corrida doble = correr(
        bebida,
        Politicas.nichoPremiumBebida.copiarCon(medios: dobles),
      );
      expect(doble.unidadesTotales,
          lessThan(base.unidadesTotales * 1.25),
          reason: 'el recuerdo de marca se satura');
    });

    test('mas inversion en medios puede reducir la utilidad', () {
      final Corrida base = correr(bebida, Politicas.nichoPremiumBebida);
      final Map<Medio, double> cuadruples = <Medio, double>{};
      Politicas.nichoPremiumBebida.medios.forEach((Medio m, double v) {
        cuadruples[m] = v * 4;
      });
      final Corrida excesiva = correr(
        bebida,
        Politicas.nichoPremiumBebida.copiarCon(medios: cuadruples),
      );
      expect(excesiva.utilidadAcumulada,
          lessThan(base.utilidadAcumulada * 1.05));
    });
  });

  group('Identidad contable', () {
    test('la caja de cierre es siempre la caja previa mas la utilidad', () {
      final Corrida p = correr(mochilas, Politicas.masivoBaratoMochilas);
      double caja = mochilas.cajaInicial;
      for (final ResultadoPeriodo r in p.historial) {
        expect(r.cajaFinal, closeTo(caja + r.utilidad, 0.01));
        caja = r.cajaFinal;
      }
      expect(p.caja, closeTo(caja, 0.01));
    });

    test('la utilidad es ingreso menos costos menos impuesto', () {
      final Corrida p = correr(academia, Politicas.flexibleAcademia);
      for (final ResultadoPeriodo r in p.historial) {
        expect(r.utilidad,
            closeTo(r.ingresos - r.costosTotales - r.impuesto, 0.01));
      }
    });
  });
}
