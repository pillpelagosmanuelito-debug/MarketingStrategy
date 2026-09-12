import 'package:flutter_test/flutter_test.dart';
import 'package:marketing_strategy_lab/data/catalogo_estudios.dart';
import 'package:marketing_strategy_lab/data/catalogo_mercados.dart';
import 'package:marketing_strategy_lab/domain/engine/evaluador.dart';
import 'package:marketing_strategy_lab/domain/engine/investigacion.dart';
import 'package:marketing_strategy_lab/domain/models/estudio.dart';
import 'package:marketing_strategy_lab/domain/models/mercado.dart';
import 'package:marketing_strategy_lab/domain/models/partida.dart';
import 'package:marketing_strategy_lab/domain/models/segmento.dart';

import 'ayuda_simulacion.dart';
import 'politicas.dart';

/// Pruebas del evaluador por competencias.
///
/// Lo que se verifica no es que el puntaje sea "alto" o "bajo", sino que
/// ordene correctamente: una partida coherente tiene que puntuar por encima de
/// una incoherente en la competencia que mide exactamente esa diferencia.
void main() {
  final Mercado bebida = CatalogoMercados.bebida;

  NotaCompetencia nota(Evaluacion e, String id) =>
      e.competencias.firstWhere((NotaCompetencia c) => c.id == id);

  group('Estructura del informe', () {
    test('siempre trae las cuatro competencias y el puntaje ponderado', () {
      final Partida p = partidaJugada(
          bebida, Politicas.fija(Politicas.nichoPremiumBebida),
          periodos: 8);
      final Evaluacion e = Evaluador.evaluar(p, bebida);
      expect(e.competencias.length, 4);
      expect(
        e.competencias.map((NotaCompetencia c) => c.id).toList(),
        <String>['segmentacion', 'investigacion', 'estrategia', 'posicionamiento'],
      );
      double esperado = 0;
      for (final NotaCompetencia c in e.competencias) {
        esperado += c.puntaje * 0.25;
        expect(c.puntaje, inInclusiveRange(0, 100));
        expect(c.componentes, isNotEmpty);
        expect(c.comentario.length, greaterThan(30));
      }
      expect(e.puntajeGlobal, closeTo(esperado, 0.001));
      expect(e.leccion, bebida.leccion);
    });
  });

  group('Posicionamiento', () {
    test('la mezcla coherente puntua mas que la promesa incumplida', () {
      final Evaluacion coherente = Evaluador.evaluar(
        partidaJugada(bebida, Politicas.fija(Politicas.nichoPremiumBebida),
            periodos: 8),
        bebida,
      );
      final Evaluacion incoherente = Evaluador.evaluar(
        partidaJugada(
            bebida, Politicas.fija(Politicas.promesaIncumplidaBebida),
            periodos: 8),
        bebida,
      );
      expect(nota(coherente, 'posicionamiento').puntaje,
          greaterThan(nota(incoherente, 'posicionamiento').puntaje + 20));
    });

    test('cambiar de posicionamiento todos los periodos castiga la claridad',
        () {
      final Partida inestable = partidaJugada(
        bebida,
        (int periodo) => periodo.isEven
            ? Politicas.nichoPremiumBebida
            : Politicas.imagenJovenBebida,
        periodos: 8,
      );
      final Partida estable = partidaJugada(
          bebida, Politicas.fija(Politicas.nichoPremiumBebida),
          periodos: 8);
      expect(inestable.estadoMarca.claridad,
          lessThan(estable.estadoMarca.claridad));
      expect(
        nota(Evaluador.evaluar(inestable, bebida), 'posicionamiento').puntaje,
        lessThan(
            nota(Evaluador.evaluar(estable, bebida), 'posicionamiento')
                .puntaje),
      );
    });
  });

  group('Segmentacion', () {
    test('mantener el objetivo puntua mas que cambiarlo cada periodo', () {
      final Partida estable = partidaJugada(
          bebida, Politicas.fija(Politicas.nichoPremiumBebida),
          periodos: 8);
      final Partida saltarina = partidaJugada(
        bebida,
        (int periodo) => periodo.isEven
            ? Politicas.nichoPremiumBebida
            : Politicas.masivoBaratoBebida,
        periodos: 8,
      );
      expect(
        nota(Evaluador.evaluar(estable, bebida), 'segmentacion').puntaje,
        greaterThan(
            nota(Evaluador.evaluar(saltarina, bebida), 'segmentacion')
                .puntaje),
      );
    });
  });

  group('Investigacion de mercado', () {
    test('investigar temprano el objetivo puntua mas que no investigar', () {
      final Partida sin = partidaJugada(
          bebida, Politicas.fija(Politicas.nichoPremiumBebida),
          periodos: 8);

      final Partida con = partidaJugada(
          bebida, Politicas.fija(Politicas.nichoPremiumBebida));
      for (final Estudio e in <Estudio>[
        CatalogoEstudios.perfil,
        CatalogoEstudios.precio,
        CatalogoEstudios.canales,
        CatalogoEstudios.medios,
      ]) {
        con.hallazgos.add(Investigacion.ejecutar(
            estudio: e,
            mercado: bebida,
            partida: con,
            segmentoId: 'fitness'));
      }
      final Partida conJugada = partidaJugada(
        bebida,
        Politicas.fija(Politicas.nichoPremiumBebida),
        periodos: 8,
        hallazgos: con.hallazgos,
      );

      expect(
        nota(Evaluador.evaluar(conJugada, bebida), 'investigacion').puntaje,
        greaterThan(
            nota(Evaluador.evaluar(sin, bebida), 'investigacion').puntaje),
      );
    });
  });

  group('Estrategia comercial', () {
    test('la quiebra anula la sostenibilidad', () {
      final Partida quebrada = partidaJugada(
          bebida, Politicas.fija(Politicas.regaladoBebida),
          periodos: 8);
      quebrada.quiebra = true;
      final NotaCompetencia n =
          nota(Evaluador.evaluar(quebrada, bebida), 'estrategia');
      final Componente sostenibilidad = n.componentes
          .firstWhere((Componente c) => c.etiqueta == 'Sostenibilidad');
      expect(sostenibilidad.puntaje, 0);
    });

    test('el resultado se mide contra la referencia calibrada del mercado', () {
      final Partida buena = partidaJugada(
          bebida, Politicas.fija(Politicas.imagenJovenBebida),
          periodos: 8);
      final NotaCompetencia n =
          nota(Evaluador.evaluar(buena, bebida), 'estrategia');
      final Componente resultado = n.componentes
          .firstWhere((Componente c) => c.etiqueta == 'Resultado económico');
      expect(resultado.puntaje, greaterThan(80));
      expect(resultado.detalle,
          contains(bebida.utilidadReferencia.toStringAsFixed(0)));
    });
  });

  group('El informe distingue mercados', () {
    test('cada escenario devuelve su propia leccion', () {
      final Set<String> lecciones = <String>{};
      for (final Mercado m in CatalogoMercados.todos) {
        final Segmento objetivo = m.segmentos.first;
        final Partida p = partidaJugada(
          m,
          Politicas.fija(Politicas.nichoPremiumBebida
              .copiarCon(segmentoObjetivo: objetivo.id)),
          periodos: 2,
        );
        lecciones.add(Evaluador.evaluar(p, m).leccion);
      }
      expect(lecciones.length, 3);
    });
  });
}
