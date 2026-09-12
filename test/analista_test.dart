import 'package:flutter_test/flutter_test.dart';
import 'package:marketing_strategy_lab/data/catalogo_estudios.dart';
import 'package:marketing_strategy_lab/data/catalogo_mercados.dart';
import 'package:marketing_strategy_lab/domain/engine/analista.dart';
import 'package:marketing_strategy_lab/domain/engine/estimador.dart';
import 'package:marketing_strategy_lab/domain/engine/investigacion.dart';
import 'package:marketing_strategy_lab/domain/models/beneficio.dart';
import 'package:marketing_strategy_lab/domain/models/canal.dart';
import 'package:marketing_strategy_lab/domain/models/estudio.dart';
import 'package:marketing_strategy_lab/domain/models/mercado.dart';
import 'package:marketing_strategy_lab/domain/models/partida.dart';
import 'package:marketing_strategy_lab/domain/models/segmento.dart';

import 'ayuda_simulacion.dart';
import 'politicas.dart';

/// Pruebas del analista de marketing.
///
/// La mas importante de este archivo es la primera: el analista no puede
/// filtrar informacion que el estudiante no compro. Si alguien "mejora" el
/// analista pasandole el mercado real, estas pruebas fallan.
void main() {
  final Mercado bebida = CatalogoMercados.bebida;
  final Segmento fitness = bebida.segmentoPorId('fitness')!;

  Partida partidaSinEstudios() => partidaJugada(
        bebida,
        Politicas.fija(Politicas.nichoPremiumBebida),
      );

  group('Honestidad: el analista solo ve lo que el estudiante compro', () {
    test('sin estudios, el mercado estimado no contiene ningun dato real', () {
      final Partida p = partidaSinEstudios();
      final MercadoEstimado estimado = MercadoEstimado.construir(p, bebida);
      final Segmento estimadoFitness =
          estimado.mercado.segmentoPorId('fitness')!;

      // El precio de referencia real es 6.8; sin prueba de precio, el
      // estimador supone el precio del propio estudiante.
      expect(estimadoFitness.precioReferencia, p.decisiones.precio);
      expect(estimadoFitness.precioReferencia,
          isNot(closeTo(fitness.precioReferencia, 0.001)));

      // El tamano real es 260,000; sin estudio, se reparte el total declarado.
      expect(estimadoFitness.tamano,
          closeTo(bebida.tamanoDeclarado / bebida.segmentos.length, 0.001));
      expect(estimadoFitness.tamano, isNot(closeTo(fitness.tamano, 1)));

      // El beneficio real buscado es rendimiento; sin perfil, el estimador
      // supone el que el estudiante promete.
      expect(estimadoFitness.beneficio, p.decisiones.beneficioPrometido);
      expect(estimadoFitness.pesoCalidad, isNot(fitness.pesoCalidad));
    });

    test('sin mystery shopper no se conoce el estado real de la competencia',
        () {
      final Partida p = partidaSinEstudios();
      final MercadoEstimado estimado = MercadoEstimado.construir(p, bebida);
      for (int i = 0; i < estimado.mercado.competidoresBase.length; i++) {
        final double estimadoPrecio =
            estimado.mercado.competidoresBase[i].decisiones.precio;
        expect(estimadoPrecio, p.decisiones.precio);
        expect(estimado.mercado.competidoresBase[i].estado.claridad,
            isNot(closeTo(bebida.competidoresBase[i].estado.claridad, 0.001)));
        expect(
            estimado.mercado.competidoresBase[i].estado.awareness['fitness'],
            isNot(closeTo(
                bebida.competidoresBase[i].estado.awareness['fitness']!,
                0.001)));
      }
    });

    test('ningun consejo menciona un dato oculto que no se haya comprado', () {
      final Partida p = partidaSinEstudios();
      final List<Consejo> consejos =
          AnalistaMarketing.analizar(p, MercadoEstimado.construir(p, bebida));
      final String texto = consejos
          .map((Consejo c) => '${c.titulo} ${c.mensaje} ${c.evidencia}')
          .join(' ');
      for (final Segmento s in bebida.segmentos) {
        expect(texto.contains(s.precioReferencia.toStringAsFixed(2)), isFalse,
            reason: 'filtro el precio de referencia de ${s.id}');
        expect(texto.contains(s.tamano.toStringAsFixed(0)), isFalse,
            reason: 'filtro el tamano de ${s.id}');
      }
    });

    test('la proyeccion cambia cuando el estudiante compra informacion', () {
      final Partida sin = partidaSinEstudios();
      final Proyeccion proyeccionSin = AnalistaMarketing.proyectar(
          sin, MercadoEstimado.construir(sin, bebida));

      final Partida con = partidaSinEstudios();
      for (final Estudio e in <Estudio>[
        CatalogoEstudios.tamano,
        CatalogoEstudios.mystery,
      ]) {
        con.hallazgos.add(Investigacion.ejecutar(
            estudio: e, mercado: bebida, partida: con, segmentoId: ''));
      }
      for (final Segmento s in bebida.segmentos) {
        for (final Estudio e in <Estudio>[
          CatalogoEstudios.perfil,
          CatalogoEstudios.precio,
          CatalogoEstudios.canales,
          CatalogoEstudios.medios,
        ]) {
          con.hallazgos.add(Investigacion.ejecutar(
              estudio: e, mercado: bebida, partida: con, segmentoId: s.id));
        }
      }
      final Proyeccion proyeccionCon = AnalistaMarketing.proyectar(
          con, MercadoEstimado.construir(con, bebida));

      expect(proyeccionSin.supuestos, isNotEmpty);
      expect(proyeccionCon.supuestos, isEmpty);
      expect(proyeccionCon.confiable, isTrue);
      expect(proyeccionCon.resultado.unidades,
          isNot(closeTo(proyeccionSin.resultado.unidades, 1)));
    });

    test('la proyeccion no altera el estado real de la partida', () {
      final Partida p = partidaJugada(
          bebida, Politicas.fija(Politicas.nichoPremiumBebida),
          periodos: 2);
      final double claridadAntes = p.estadoMarca.claridad;
      final double reputacionAntes = p.estadoMarca.reputacion;
      final double cajaAntes = p.caja;
      AnalistaMarketing.proyectar(p, MercadoEstimado.construir(p, bebida));
      expect(p.estadoMarca.claridad, claridadAntes);
      expect(p.estadoMarca.reputacion, reputacionAntes);
      expect(p.caja, cajaAntes);
      expect(p.historial.length, 2);
    });
  });

  group('Reglas', () {
    List<String> reglasDe(Partida p) => AnalistaMarketing
        .analizar(p, MercadoEstimado.construir(p, bebida))
        .map((Consejo c) => c.regla)
        .toList();

    test('R01 avisa cuando no hay perfil del segmento objetivo', () {
      expect(reglasDe(partidaSinEstudios()), contains('R01'));
    });

    test('R01 desaparece cuando se contrata el perfil', () {
      final Partida p = partidaSinEstudios();
      p.hallazgos.add(Investigacion.ejecutar(
          estudio: CatalogoEstudios.perfil,
          mercado: bebida,
          partida: p,
          segmentoId: p.decisiones.segmentoObjetivo));
      expect(reglasDe(p), isNot(contains('R01')));
    });

    test('R13 y R15 detectan la promesa que el producto no sostiene', () {
      final Partida p = partidaJugada(
        bebida,
        Politicas.fija(Politicas.promesaIncumplidaBebida),
      );
      final List<String> reglas = reglasDe(p);
      expect(reglas, contains('R13'));
      expect(reglas, contains('R15'));
    });

    test('R19 detecta la venta por debajo del costo', () {
      final Partida p = partidaJugada(
        bebida,
        Politicas.fija(Politicas.nichoPremiumBebida.copiarCon(precio: 0.5)),
      );
      expect(reglasDe(p), contains('R19'));
    });

    test('R26 detecta que no hay donde vender', () {
      final Partida p = partidaJugada(
        bebida,
        Politicas.fija(
            Politicas.nichoPremiumBebida.copiarCon(canales: <Canal>{})),
      );
      expect(reglasDe(p), contains('R26'));
    });

    test('R16 detecta que la promesa no es la que el objetivo busca', () {
      final Partida p = partidaJugada(
        bebida,
        Politicas.fija(Politicas.nichoPremiumBebida
            .copiarCon(beneficioPrometido: Beneficio.precio)),
      );
      p.hallazgos.add(Investigacion.ejecutar(
          estudio: CatalogoEstudios.perfil,
          mercado: bebida,
          partida: p,
          segmentoId: 'fitness'));
      expect(reglasDe(p), contains('R16'));
    });

    test('una mezcla coherente recibe una confirmacion, no solo criticas', () {
      final Partida p = partidaSinEstudios();
      p.hallazgos.add(Investigacion.ejecutar(
          estudio: CatalogoEstudios.perfil,
          mercado: bebida,
          partida: p,
          segmentoId: 'fitness'));
      expect(reglasDe(p), contains('R30'));
    });

    test('cada consejo trae fundamento y evidencia', () {
      final Partida p = partidaSinEstudios();
      final List<Consejo> consejos =
          AnalistaMarketing.analizar(p, MercadoEstimado.construir(p, bebida));
      expect(consejos, isNotEmpty);
      for (final Consejo c in consejos) {
        expect(c.fundamento.length, greaterThan(20));
        expect(c.evidencia.length, greaterThan(10));
        expect(c.regla, startsWith('R'));
      }
    });

    test('los consejos se ordenan de mas grave a menos grave', () {
      final Partida p = partidaSinEstudios();
      final List<Consejo> consejos =
          AnalistaMarketing.analizar(p, MercadoEstimado.construir(p, bebida));
      for (int i = 1; i < consejos.length; i++) {
        expect(consejos[i].severidad.index,
            greaterThanOrEqualTo(consejos[i - 1].severidad.index));
      }
    });
  });
}
