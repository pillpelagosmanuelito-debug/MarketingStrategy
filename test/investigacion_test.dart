import 'package:flutter_test/flutter_test.dart';
import 'package:marketing_strategy_lab/data/catalogo_estudios.dart';
import 'package:marketing_strategy_lab/data/catalogo_mercados.dart';
import 'package:marketing_strategy_lab/domain/engine/investigacion.dart';
import 'package:marketing_strategy_lab/domain/models/canal.dart';
import 'package:marketing_strategy_lab/domain/models/estudio.dart';
import 'package:marketing_strategy_lab/domain/models/mercado.dart';
import 'package:marketing_strategy_lab/domain/models/partida.dart';
import 'package:marketing_strategy_lab/domain/models/segmento.dart';

import 'ayuda_simulacion.dart';
import 'politicas.dart';

/// Pruebas de la investigacion de mercado.
///
/// Dos propiedades sostienen todo el modulo: los estudios nunca devuelven el
/// valor exacto, y devuelven siempre lo mismo para la misma partida. Lo
/// primero es lo que hace que investigar sea una decision y no un boton de
/// "ver respuestas"; lo segundo es lo que permite comparar decisiones entre
/// estudiantes de un aula.
void main() {
  final Mercado bebida = CatalogoMercados.bebida;
  final Segmento fitness = bebida.segmentoPorId('fitness')!;

  Partida nueva() =>
      partidaJugada(bebida, Politicas.fija(Politicas.nichoPremiumBebida));

  test('el estudio no devuelve el valor exacto', () {
    final Partida p = nueva();
    final Hallazgo h = Investigacion.ejecutar(
      estudio: CatalogoEstudios.precio,
      mercado: bebida,
      partida: p,
      segmentoId: 'fitness',
    );
    final double estimado = h.valor('precioReferencia')!;
    expect(estimado, isNot(closeTo(fitness.precioReferencia, 0.0001)));
    expect(estimado,
        closeTo(fitness.precioReferencia, fitness.precioReferencia * 0.5));
  });

  test('la misma partida devuelve siempre la misma medicion', () {
    final Hallazgo a = Investigacion.ejecutar(
      estudio: CatalogoEstudios.perfil,
      mercado: bebida,
      partida: nueva(),
      segmentoId: 'fitness',
    );
    final Hallazgo b = Investigacion.ejecutar(
      estudio: CatalogoEstudios.perfil,
      mercado: bebida,
      partida: nueva(),
      segmentoId: 'fitness',
    );
    expect(a.valor('pesoCalidad'), b.valor('pesoCalidad'));
    expect(a.valor('exigencia'), b.valor('exigencia'));
  });

  test('repetir el estudio reduce el error a la mitad', () {
    final Partida p = nueva();
    final Hallazgo primera = Investigacion.ejecutar(
      estudio: CatalogoEstudios.precio,
      mercado: bebida,
      partida: p,
      segmentoId: 'fitness',
    );
    p.hallazgos.add(primera);
    final Hallazgo segunda = Investigacion.ejecutar(
      estudio: CatalogoEstudios.precio,
      mercado: bebida,
      partida: p,
      segmentoId: 'fitness',
    );
    p.hallazgos.add(segunda);
    final Hallazgo tercera = Investigacion.ejecutar(
      estudio: CatalogoEstudios.precio,
      mercado: bebida,
      partida: p,
      segmentoId: 'fitness',
    );
    expect(primera.error, CatalogoEstudios.precio.errorBase);
    expect(segunda.error, closeTo(primera.error / 2, 0.0001));
    expect(tercera.error, closeTo(primera.error / 4, 0.0001));
    expect(segunda.repeticion, 2);
    expect(tercera.repeticion, 3);
  });

  test('la mejor medicion disponible es la de menor error', () {
    final Partida p = nueva();
    for (int i = 0; i < 3; i++) {
      p.hallazgos.add(Investigacion.ejecutar(
        estudio: CatalogoEstudios.precio,
        mercado: bebida,
        partida: p,
        segmentoId: 'fitness',
      ));
    }
    final Hallazgo mejor = p.mejorHallazgo('precio', 'fitness')!;
    expect(mejor.repeticion, 3);
    expect(mejor.error, closeTo(CatalogoEstudios.precio.errorBase / 4, 0.0001));
  });

  test('el beneficio buscado se identifica sin error de muestreo', () {
    final Hallazgo h = Investigacion.ejecutar(
      estudio: CatalogoEstudios.perfil,
      mercado: bebida,
      partida: nueva(),
      segmentoId: 'fitness',
    );
    expect(h.valor('beneficio')!.round(), fitness.beneficio.index);
  });

  test('la auditoria de canales cubre los cinco canales', () {
    final Hallazgo h = Investigacion.ejecutar(
      estudio: CatalogoEstudios.canales,
      mercado: bebida,
      partida: nueva(),
      segmentoId: 'fitness',
    );
    for (final Canal c in Canal.values) {
      expect(h.valor('canal:${c.id}'), isNotNull);
    }
  });

  test('el mystery shopper observa a todos los competidores', () {
    final Partida p = nueva();
    final Hallazgo h = Investigacion.ejecutar(
      estudio: CatalogoEstudios.mystery,
      mercado: bebida,
      partida: p,
      segmentoId: '',
    );
    for (final dynamic c in p.competidores) {
      expect(h.valor('precio:${c.id}'), isNotNull);
      expect(h.valor('calidad:${c.id}'), isNotNull);
    }
    expect(h.notas.length, greaterThanOrEqualTo(p.competidores.length));
  });

  test('el estudio de marca solo esta disponible despues del primer periodo',
      () {
    expect(CatalogoEstudios.marca.desdePeriodo, 1);
    expect(CatalogoEstudios.tamano.desdePeriodo, 0);
  });

  test('todos los estudios del catalogo tienen costo y error declarados', () {
    for (final Estudio e in CatalogoEstudios.todos) {
      expect(e.costo, greaterThan(0));
      expect(e.errorBase, greaterThan(0));
      expect(e.errorBase, lessThan(0.5));
      expect(e.descripcion.length, greaterThan(40));
    }
  });
}
