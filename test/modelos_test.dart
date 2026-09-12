import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:marketing_strategy_lab/data/catalogo_estudios.dart';
import 'package:marketing_strategy_lab/data/catalogo_mercados.dart';
import 'package:marketing_strategy_lab/domain/engine/investigacion.dart';
import 'package:marketing_strategy_lab/domain/models/beneficio.dart';
import 'package:marketing_strategy_lab/domain/models/canal.dart';
import 'package:marketing_strategy_lab/domain/models/decisiones.dart';
import 'package:marketing_strategy_lab/domain/models/medio.dart';
import 'package:marketing_strategy_lab/domain/models/mercado.dart';
import 'package:marketing_strategy_lab/domain/models/partida.dart';
import 'package:marketing_strategy_lab/domain/models/resultado_periodo.dart';

import 'ayuda_simulacion.dart';
import 'politicas.dart';

/// Serializacion de la partida.
///
/// Importa mas de lo que parece: el estudiante juega en varias sesiones y una
/// partida que no sobrevive al cierre de la aplicacion no sirve para un curso.
void main() {
  final Mercado bebida = CatalogoMercados.bebida;

  test('las decisiones sobreviven a una ida y vuelta por JSON', () {
    final Decisiones original = Politicas.nichoPremiumBebida;
    final Decisiones copia = Decisiones.desdeJson(
        jsonDecode(jsonEncode(original.aJson())) as Map<String, dynamic>);
    expect(copia.segmentoObjetivo, original.segmentoObjetivo);
    expect(copia.beneficioPrometido, original.beneficioPrometido);
    expect(copia.beneficioReal, original.beneficioReal);
    expect(copia.nivelPromesa, original.nivelPromesa);
    expect(copia.calidad, original.calidad);
    expect(copia.amplitud, original.amplitud);
    expect(copia.precio, original.precio);
    expect(copia.canales, original.canales);
    for (final Medio m in Medio.values) {
      expect(copia.gastoEn(m), original.gastoEn(m));
    }
  });

  test('una partida jugada se reconstruye identica', () {
    final Partida original = partidaJugada(
        bebida, Politicas.fija(Politicas.nichoPremiumBebida),
        periodos: 3);
    original.hallazgos.add(Investigacion.ejecutar(
      estudio: CatalogoEstudios.perfil,
      mercado: bebida,
      partida: original,
      segmentoId: 'fitness',
    ));

    final String texto = jsonEncode(original.aJson());
    final Partida copia = Partida.desdeJson(
        jsonDecode(texto) as Map<String, dynamic>, bebida);

    expect(copia.mercadoId, original.mercadoId);
    expect(copia.marca, original.marca);
    expect(copia.periodo, original.periodo);
    expect(copia.caja, closeTo(original.caja, 0.0001));
    expect(copia.historial.length, original.historial.length);
    expect(copia.decisionesTomadas.length, original.decisionesTomadas.length);
    expect(copia.hallazgos.length, 1);
    expect(copia.hallazgos.first.valor('pesoCalidad'),
        original.hallazgos.first.valor('pesoCalidad'));
    expect(copia.estadoMarca.claridad,
        closeTo(original.estadoMarca.claridad, 0.0001));
    expect(copia.estadoMarca.reputacion,
        closeTo(original.estadoMarca.reputacion, 0.0001));
    expect(copia.competidores.length, original.competidores.length);
    for (int i = 0; i < copia.competidores.length; i++) {
      expect(copia.competidores[i].decisiones.precio,
          closeTo(original.competidores[i].decisiones.precio, 0.0001));
      expect(copia.competidores[i].estado.awareness['fitness'],
          closeTo(original.competidores[i].estado.awareness['fitness']!,
              0.0001));
    }
  });

  test('el resultado de un periodo conserva el detalle por segmento', () {
    final Partida p = partidaJugada(
        bebida, Politicas.fija(Politicas.nichoPremiumBebida),
        periodos: 1);
    final ResultadoPeriodo original = p.historial.first;
    final ResultadoPeriodo copia = ResultadoPeriodo.desdeJson(
        jsonDecode(jsonEncode(original.aJson())) as Map<String, dynamic>);
    expect(copia.segmentos.length, original.segmentos.length);
    expect(copia.unidades, closeTo(original.unidades, 0.0001));
    expect(copia.utilidad, closeTo(original.utilidad, 0.0001));
    expect(copia.segmento('fitness')!.satisfaccion,
        closeTo(original.segmento('fitness')!.satisfaccion, 0.0001));
    expect(copia.ventasCompetidores.keys.toSet(),
        original.ventasCompetidores.keys.toSet());
  });

  test('los identificadores de enumerados son estables', () {
    for (final Beneficio b in Beneficio.values) {
      expect(Beneficio.desdeId(b.id), b);
    }
    for (final Canal c in Canal.values) {
      expect(Canal.desdeId(c.id), c);
    }
    for (final Medio m in Medio.values) {
      expect(Medio.desdeId(m.id), m);
    }
  });

  test('la partida guardada no contiene los parametros ocultos del mercado',
      () {
    final Partida p = partidaJugada(
        bebida, Politicas.fija(Politicas.nichoPremiumBebida),
        periodos: 2);
    final String texto = jsonEncode(p.aJson());
    // Lo que se guarda identifica al mercado por id: la definicion del
    // escenario (pesos de decision, precios de referencia, sensibilidades)
    // vive en el catalogo y no viaja al almacenamiento. Lo unico con datos de
    // mercado que si se guarda son los hallazgos que el estudiante pago, que
    // son sus propias estimaciones con error.
    expect(texto.contains('pesoCalidad'), isFalse);
    expect(texto.contains('precioReferencia'), isFalse);
    expect(texto.contains('sensibilidad'), isFalse);
    expect(texto.contains('"mercadoId":"bebida"'), isTrue);
  });
}
