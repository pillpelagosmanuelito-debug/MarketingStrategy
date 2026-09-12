import 'package:flutter_test/flutter_test.dart';
import 'package:marketing_strategy_lab/data/catalogo_mercados.dart';
import 'package:marketing_strategy_lab/domain/models/canal.dart';
import 'package:marketing_strategy_lab/domain/models/competidor.dart';
import 'package:marketing_strategy_lab/domain/models/evento.dart';
import 'package:marketing_strategy_lab/domain/models/medio.dart';
import 'package:marketing_strategy_lab/domain/models/mercado.dart';
import 'package:marketing_strategy_lab/domain/models/segmento.dart';

/// Integridad del catalogo de escenarios.
///
/// El catalogo se genera desde el prototipo de calibracion; estas pruebas
/// existen para que una edicion manual del archivo generado no pase
/// desapercibida.
void main() {
  group('Cada mercado esta bien formado', () {
    for (final Mercado m in CatalogoMercados.todos) {
      test('${m.nombre}: estructura basica', () {
        expect(m.segmentos.length, greaterThanOrEqualTo(3));
        expect(m.competidoresBase.length, greaterThanOrEqualTo(2));
        expect(m.periodos, greaterThanOrEqualTo(6));
        expect(m.cajaInicial, greaterThan(0));
        expect(m.limiteSobregiro, greaterThan(0));
        expect(m.costoBase, greaterThan(0));
        expect(m.costoFijo, greaterThan(0));
        expect(m.utilidadReferencia, greaterThan(0));
        expect(m.contexto.length, greaterThan(200));
        expect(m.leccion.length, greaterThan(200));
        expect(m.unidad, isNotEmpty);
      });

      test('${m.nombre}: los identificadores de segmento son unicos', () {
        final Set<String> ids =
            m.segmentos.map((Segmento s) => s.id).toSet();
        expect(ids.length, m.segmentos.length);
      });

      test('${m.nombre}: los pesos de decision suman aproximadamente 1', () {
        for (final Segmento s in m.segmentos) {
          final double suma = s.pesoCalidad +
              s.pesoBeneficio +
              s.pesoMarca +
              s.pesoVariedad;
          expect(suma, closeTo(1.0, 0.06), reason: 'segmento ${s.id}');
        }
      });

      test('${m.nombre}: los parametros de segmento son plausibles', () {
        for (final Segmento s in m.segmentos) {
          expect(s.tamano, greaterThan(0), reason: s.id);
          expect(s.precioReferencia, greaterThan(m.costoBase),
              reason: 'el segmento ${s.id} no pagaria ni el costo');
          expect(s.sensibilidad, greaterThan(0), reason: s.id);
          expect(s.exigencia, inInclusiveRange(1, 5), reason: s.id);
          expect(s.lealtad, inInclusiveRange(0, 1), reason: s.id);
          expect(s.descripcion.length, greaterThan(80), reason: s.id);
          for (final Medio med in Medio.values) {
            expect(s.afinidadDe(med), inInclusiveRange(0, 1));
          }
          for (final Canal c in Canal.values) {
            expect(s.coberturaDe(c), inInclusiveRange(0, 1));
          }
        }
      });

      test('${m.nombre}: el tamano declarado es del orden del real', () {
        double real = 0;
        for (final Segmento s in m.segmentos) {
          real += s.tamano;
        }
        expect(m.tamanoDeclarado, greaterThan(real * 0.7));
        expect(m.tamanoDeclarado, lessThan(real * 1.4));
      });

      test('${m.nombre}: los competidores parten de una posicion coherente',
          () {
        for (final Competidor c in m.competidoresBase) {
          expect(c.decisiones.precio, greaterThan(m.costoBase));
          expect(c.decisiones.calidad, inInclusiveRange(1, 5));
          expect(c.decisiones.canales, isNotEmpty);
          expect(c.decisiones.gastoMedios, greaterThan(0));
          expect(c.estado.reputacion, inInclusiveRange(0, 1));
          for (final Segmento s in m.segmentos) {
            expect(c.estado.awareness[s.id], isNotNull,
                reason: '${c.id} sin recuerdo inicial en ${s.id}');
          }
        }
      });

      test('${m.nombre}: los eventos apuntan a algo que existe', () {
        for (final Evento e in m.eventos) {
          expect(e.periodo, inInclusiveRange(0, m.periodos - 1));
          expect(e.titulo, isNotEmpty);
          expect(e.descripcion.length, greaterThan(30));
          if (e.segmento.isNotEmpty) {
            expect(m.segmentoPorId(e.segmento), isNotNull,
                reason: 'evento sobre segmento inexistente ${e.segmento}');
          }
          if (e.competidor.isNotEmpty) {
            expect(
              m.competidoresBase
                  .any((Competidor c) => c.id == e.competidor),
              isTrue,
              reason: 'evento sobre competidor inexistente ${e.competidor}',
            );
          }
        }
      });

      test('${m.nombre}: hay al menos un segmento por debajo y uno por encima '
          'del precio medio', () {
        double suma = 0;
        for (final Segmento s in m.segmentos) {
          suma += s.precioReferencia;
        }
        final double medio = suma / m.segmentos.length;
        expect(m.segmentos.any((Segmento s) => s.precioReferencia < medio),
            isTrue);
        expect(m.segmentos.any((Segmento s) => s.precioReferencia > medio),
            isTrue);
      });
    }
  });

  group('El catalogo completo', () {
    test('los mercados tienen identificadores unicos', () {
      final Set<String> ids =
          CatalogoMercados.todos.map((Mercado m) => m.id).toSet();
      expect(ids.length, CatalogoMercados.todos.length);
    });

    test('porId devuelve el mercado correcto y null si no existe', () {
      expect(CatalogoMercados.porId('bebida'), CatalogoMercados.bebida);
      expect(CatalogoMercados.porId('inexistente'), isNull);
    });

    test('los tres escenarios ensenan lecciones distintas', () {
      final Set<String> lecciones =
          CatalogoMercados.todos.map((Mercado m) => m.leccion).toSet();
      expect(lecciones.length, 3);
    });

    test('clonarCompetidores no comparte estado con el catalogo', () {
      final Mercado m = CatalogoMercados.bebida;
      final List<Competidor> copia = m.clonarCompetidores();
      final double precioOriginal = m.competidoresBase.first.decisiones.precio;
      copia.first.decisiones =
          copia.first.decisiones.copiarCon(precio: 999);
      copia.first.estado.reputacion = 0.11;
      expect(m.competidoresBase.first.decisiones.precio, precioOriginal);
      expect(m.competidoresBase.first.estado.reputacion, isNot(0.11));
    });
  });
}
