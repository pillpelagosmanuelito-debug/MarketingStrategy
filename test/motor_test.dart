import 'package:flutter_test/flutter_test.dart';
import 'package:marketing_strategy_lab/data/catalogo_mercados.dart';
import 'package:marketing_strategy_lab/domain/engine/motor_simulacion.dart';
import 'package:marketing_strategy_lab/domain/engine/parametros.dart';
import 'package:marketing_strategy_lab/domain/models/beneficio.dart';
import 'package:marketing_strategy_lab/domain/models/canal.dart';
import 'package:marketing_strategy_lab/domain/models/decisiones.dart';
import 'package:marketing_strategy_lab/domain/models/medio.dart';
import 'package:marketing_strategy_lab/domain/models/mercado.dart';
import 'package:marketing_strategy_lab/domain/models/segmento.dart';

import 'politicas.dart';

/// Pruebas del motor pieza por pieza.
///
/// Los valores esperados no se inventaron: salen del prototipo de calibracion
/// y de su transliteracion de vuelta a Python, que se corrio sobre el codigo
/// Dart realmente entregado.
void main() {
  final Mercado bebida = CatalogoMercados.bebida;
  final Segmento fitness = bebida.segmentoPorId('fitness')!;
  final Decisiones premium = Politicas.nichoPremiumBebida;

  group('Distribucion', () {
    test('la cobertura de varios canales se solapa, no se suma', () {
      final double tres = MotorSimulacion.cobertura(
          fitness, <Canal>{Canal.retail, Canal.propio, Canal.marketplace});
      final double suma = fitness.coberturaDe(Canal.retail) +
          fitness.coberturaDe(Canal.propio) +
          fitness.coberturaDe(Canal.marketplace);
      expect(tres, closeTo(0.8515, 0.0001));
      expect(tres, lessThan(suma));
    });

    test('la cobertura nunca llega a 1', () {
      final double todos =
          MotorSimulacion.cobertura(fitness, Canal.values.toSet());
      expect(todos, lessThanOrEqualTo(Parametros.techoCobertura));
    });

    test('sin canales no hay cobertura', () {
      expect(MotorSimulacion.cobertura(fitness, <Canal>{}), 0.0);
    });

    test('el margen del canal se pondera por la afinidad del segmento', () {
      final double margen = MotorSimulacion.margenCanal(
          fitness, <Canal>{Canal.retail, Canal.propio, Canal.marketplace});
      expect(margen, closeTo(0.186429, 0.0001));
    });
  });

  group('Costos', () {
    test('el costo unitario sube con la calidad', () {
      final double barato = MotorSimulacion.costoUnitario(
          bebida, EstadoMercado(), premium.copiarCon(calidad: 1), 0);
      final double caro = MotorSimulacion.costoUnitario(
          bebida, EstadoMercado(), premium.copiarCon(calidad: 5), 0);
      expect(caro, greaterThan(barato * 1.5));
    });

    test('el costo unitario de la politica premium es el calibrado', () {
      expect(
        MotorSimulacion.costoUnitario(bebida, EstadoMercado(), premium, 0),
        closeTo(2.0801, 0.0001),
      );
    });

    test('la curva de experiencia tiene piso: no baja indefinidamente', () {
      final double inicial =
          MotorSimulacion.costoUnitario(bebida, EstadoMercado(), premium, 0);
      final double conVolumen = MotorSimulacion.costoUnitario(
          bebida, EstadoMercado(), premium, 1000000);
      final double conMuchisimo = MotorSimulacion.costoUnitario(
          bebida, EstadoMercado(), premium, 900000000);
      expect(conVolumen, closeTo(inicial * Parametros.pisoExperiencia, 0.001));
      expect(conMuchisimo, closeTo(conVolumen, 0.0001));
    });

    test('la amplitud de linea encarece la unidad', () {
      final double una = MotorSimulacion.costoUnitario(
          bebida, EstadoMercado(), premium.copiarCon(amplitud: 1), 0);
      final double tres = MotorSimulacion.costoUnitario(
          bebida, EstadoMercado(), premium.copiarCon(amplitud: 3), 0);
      expect(tres, closeTo(una * 1.10, 0.0001));
    });
  });

  group('Satisfaccion', () {
    test('una promesa coherente deja al cliente satisfecho', () {
      expect(MotorSimulacion.satisfaccion(fitness, premium),
          closeTo(0.61558, 0.0001));
    });

    test('prometer de mas hunde la satisfaccion al piso', () {
      final double sat = MotorSimulacion.satisfaccion(
          fitness, Politicas.promesaIncumplidaBebida);
      expect(sat, closeTo(Parametros.pisoSatisfaccion, 0.0001));
    });

    test('entregar el mismo producto con menos promesa satisface mas', () {
      final double conPromesaAlta = MotorSimulacion.satisfaccion(
          fitness, premium.copiarCon(nivelPromesa: 5));
      final double conPromesaBaja = MotorSimulacion.satisfaccion(
          fitness, premium.copiarCon(nivelPromesa: 3));
      expect(conPromesaBaja, greaterThan(conPromesaAlta));
    });

    test('subir el precio sube la expectativa y baja la satisfaccion', () {
      final double barato = MotorSimulacion.satisfaccion(
          fitness, premium.copiarCon(precio: 5.0));
      final double caro = MotorSimulacion.satisfaccion(
          fitness, premium.copiarCon(precio: 12.0));
      expect(caro, lessThan(barato));
    });

    test('la satisfaccion esta acotada en ambos extremos', () {
      for (double calidad = 1; calidad <= 5; calidad += 0.5) {
        for (double nivel = 1; nivel <= 5; nivel += 0.5) {
          final double s = MotorSimulacion.satisfaccion(fitness,
              premium.copiarCon(calidad: calidad, nivelPromesa: nivel));
          expect(s, greaterThanOrEqualTo(Parametros.pisoSatisfaccion));
          expect(s, lessThanOrEqualTo(Parametros.techoSatisfaccion));
        }
      }
    });
  });

  group('Recuerdo de marca', () {
    test('una campana afin instala marca desde casi cero', () {
      final double aw = MotorSimulacion.actualizarAwareness(
        fitness,
        0.04,
        premium.medios,
        0.55,
      );
      expect(aw, closeTo(0.423451, 0.0001));
    });

    test('sin inversion el recuerdo se deprecia 15% por periodo', () {
      expect(
        MotorSimulacion.actualizarAwareness(
            fitness, 0.50, <Medio, double>{}, 0.55),
        closeTo(0.425, 0.0001),
      );
    });

    test('la insatisfaccion acelera el olvido', () {
      final double conBuenaFama = MotorSimulacion.actualizarAwareness(
          fitness, 0.50, <Medio, double>{}, 0.55);
      final double conMalaFama = MotorSimulacion.actualizarAwareness(
          fitness, 0.50, <Medio, double>{}, 0.10);
      expect(conMalaFama, lessThan(conBuenaFama));
      expect(conMalaFama, closeTo(0.32875, 0.0001));
    });

    test('invertir en un medio que el segmento no consume casi no sirve', () {
      final double afin = MotorSimulacion.actualizarAwareness(
          fitness, 0.10, <Medio, double>{Medio.influencers: 40000}, 0.55);
      final double noAfin = MotorSimulacion.actualizarAwareness(
          fitness, 0.10, <Medio, double>{Medio.radio: 40000}, 0.55);
      expect(noAfin, lessThan(afin * 0.6));
    });

    test('el recuerdo nunca supera el techo', () {
      double aw = 0.5;
      for (int i = 0; i < 40; i++) {
        aw = MotorSimulacion.actualizarAwareness(
            fitness, aw, <Medio, double>{Medio.digital: 900000}, 0.95);
      }
      expect(aw, lessThanOrEqualTo(Parametros.techoAwareness));
    });
  });

  group('Similitud entre beneficios', () {
    test('es simetrica y tiene piso', () {
      expect(
          Parametros.similitud(Beneficio.salud, Beneficio.rendimiento), 0.60);
      expect(
          Parametros.similitud(Beneficio.rendimiento, Beneficio.salud), 0.60);
      expect(Parametros.similitud(Beneficio.salud, Beneficio.precio),
          Parametros.pisoSimilitud);
      expect(Parametros.similitud(Beneficio.salud, Beneficio.salud), 1.0);
    });
  });

  group('Eventos', () {
    test('el alza de insumos encarece el costo para todos', () {
      final EstadoMercado estado = EstadoMercado();
      final double antes =
          MotorSimulacion.costoUnitario(bebida, estado, premium, 0);
      MotorSimulacion.aplicarEventos(
          bebida, estado, bebida.clonarCompetidores(), 2);
      final double despues =
          MotorSimulacion.costoUnitario(bebida, estado, premium, 0);
      expect(despues, closeTo(antes * 1.12, 0.0001));
    });

    test('los eventos de un periodo no se aplican en otro', () {
      final EstadoMercado estado = EstadoMercado();
      MotorSimulacion.aplicarEventos(
          bebida, estado, bebida.clonarCompetidores(), 0);
      expect(estado.factorCosto, 1.0);
    });
  });

  group('Punto de equilibrio', () {
    test('es infinito cuando la contribucion unitaria es negativa', () {
      final double pe = MotorSimulacion.puntoEquilibrio(
        bebida,
        EstadoMercado(),
        premium.copiarCon(precio: 1.0),
        0,
        0.20,
      );
      expect(pe.isFinite, isFalse);
    });

    test('baja cuando sube el precio', () {
      final double caro = MotorSimulacion.puntoEquilibrio(
          bebida, EstadoMercado(), premium.copiarCon(precio: 12), 0, 0.20);
      final double barato = MotorSimulacion.puntoEquilibrio(
          bebida, EstadoMercado(), premium.copiarCon(precio: 6), 0, 0.20);
      expect(caro, lessThan(barato));
    });
  });
}
