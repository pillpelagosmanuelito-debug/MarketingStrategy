import '../../core/aleatorio.dart';
import '../models/canal.dart';
import '../models/competidor.dart';
import '../models/estudio.dart';
import '../models/medio.dart';
import '../models/mercado.dart';
import '../models/partida.dart';
import '../models/segmento.dart';

/// Servicio de investigacion de mercado.
///
/// Traduce la verdad oculta del mercado en estimaciones con error. Es el unico
/// punto del sistema autorizado a leer los parametros ocultos de los
/// segmentos, y siempre devuelve datos deteriorados: nunca entrega el valor
/// exacto.
class Investigacion {
  const Investigacion._();

  /// Error de la medicion numero [repeticion]: cada repeticion lo reduce a la
  /// mitad. La primera vale mucho, la tercera casi nada.
  static double errorDe(Estudio estudio, int repeticion) {
    double error = estudio.errorBase;
    for (int i = 1; i < repeticion; i++) {
      error = error / 2.0;
    }
    return error;
  }

  static double _ruido(Aleatorio r, double valor, double error) {
    final double desviado = valor * (1.0 + r.normal() * error);
    return desviado < 0.0 ? 0.0 : desviado;
  }

  /// Contrata un estudio y devuelve lo que arrojo.
  static Hallazgo ejecutar({
    required Estudio estudio,
    required Mercado mercado,
    required Partida partida,
    required String segmentoId,
  }) {
    final int repeticion = partida.repeticionesDe(estudio.id, segmentoId) + 1;
    final double error = errorDe(estudio, repeticion);
    final Aleatorio r = Aleatorio(Aleatorio.hashCadena(
        '${mercado.id}|${estudio.id}|$segmentoId|$repeticion'));
    final Map<String, double> datos = <String, double>{};
    final List<String> notas = <String>[];
    final Segmento? seg = mercado.segmentoPorId(segmentoId);

    switch (estudio.tipo) {
      case TipoEstudio.tamanoMercado:
        double total = 0.0;
        for (final Segmento s in mercado.segmentos) {
          final double t =
              _ruido(r, partida.estadoMercado.tamano(s), error);
          datos['tamano:${s.id}'] = t;
          total += t;
        }
        datos['total'] = total;
        notas.add('Estimacion del numero de compradores potenciales por '
            'periodo en cada segmento, con un error de muestreo de mas o '
            'menos ${(error * 100).round()}%.');
        break;

      case TipoEstudio.perfilSegmento:
        if (seg == null) break;
        datos['pesoCalidad'] = _ruido(r, seg.pesoCalidad, error);
        datos['pesoBeneficio'] = _ruido(r, seg.pesoBeneficio, error);
        datos['pesoMarca'] = _ruido(r, seg.pesoMarca, error);
        datos['pesoVariedad'] = _ruido(r, seg.pesoVariedad, error);
        datos['exigencia'] = _ruido(r, seg.exigencia, error);
        datos['lealtad'] = _ruido(r, seg.lealtad, error);
        datos['beneficio'] = seg.beneficio.index.toDouble();
        notas.add('Beneficio que este segmento declara buscar: '
            '${seg.beneficio.etiqueta}.');
        notas.add('Los pesos indican cuanto influye cada atributo en su '
            'decision. Suman aproximadamente 1.');
        break;

      case TipoEstudio.pruebaPrecio:
        if (seg == null) break;
        datos['precioReferencia'] = _ruido(r, seg.precioReferencia, error);
        datos['sensibilidad'] = _ruido(r, seg.sensibilidad, error);
        datos['sospechaPrecioBajo'] = _ruido(r, seg.sospechaPrecioBajo, error);
        notas.add('El precio de referencia es lo que el segmento considera '
            'normal para la categoria. La sensibilidad indica cuanto castiga '
            'alejarse de ese precio.');
        if (seg.sospechaPrecioBajo > 1.2) {
          notas.add('Atencion: este segmento desconfia de los precios '
              'demasiado bajos.');
        }
        break;

      case TipoEstudio.auditoriaCanales:
        if (seg == null) break;
        for (final Canal c in Canal.values) {
          datos['canal:${c.id}'] = _ruido(r, seg.coberturaDe(c), error);
        }
        notas.add('Proporcion del segmento a la que llega cada canal. Dos '
            'canales que llegan al mismo publico no suman: se solapan.');
        break;

      case TipoEstudio.habitosMedios:
        if (seg == null) break;
        for (final Medio m in Medio.values) {
          datos['medio:${m.id}'] = _ruido(r, seg.afinidadDe(m), error);
        }
        notas.add('Afinidad del segmento con cada medio. Invertir en un medio '
            'con afinidad baja es gastar sin ser visto.');
        break;

      case TipoEstudio.mysteryShopper:
        for (final Competidor c in partida.competidores) {
          datos['precio:${c.id}'] = _ruido(r, c.decisiones.precio, error);
          datos['calidad:${c.id}'] = _ruido(r, c.decisiones.calidad, error);
          datos['promesa:${c.id}'] =
              c.decisiones.beneficioPrometido.index.toDouble();
          datos['nivel:${c.id}'] = c.decisiones.nivelPromesa;
          for (final Canal canal in Canal.values) {
            datos['canal:${canal.id}:${c.id}'] =
                c.decisiones.canales.contains(canal) ? 1.0 : 0.0;
          }
          for (final Medio medio in Medio.values) {
            datos['medio:${medio.id}:${c.id}'] =
                _ruido(r, c.decisiones.gastoEn(medio), error);
          }
          notas.add('${c.nombre}: promete '
              '${c.decisiones.beneficioPrometido.etiqueta.toLowerCase()} a un '
              'nivel ${c.decisiones.nivelPromesa.round()} de 5.');
        }
        notas.add('El mystery shopper tambien observa en que canales se vende '
            'cada competidor y estima su presion publicitaria por medio.');
        break;

      case TipoEstudio.satisfaccionMarca:
        for (final Segmento s in mercado.segmentos) {
          datos['awareness:${s.id}'] =
              _ruido(r, partida.estadoMarca.awareness[s.id] ?? 0.0, error);
        }
        datos['reputacion'] = _ruido(r, partida.estadoMarca.reputacion, error);
        datos['claridad'] = _ruido(r, partida.estadoMarca.claridad, error);
        notas.add('Recuerdo de marca por segmento, reputacion (satisfaccion '
            'acumulada de quienes compraron) y claridad del posicionamiento.');
        break;
    }

    return Hallazgo(
      estudioId: estudio.id,
      segmentoId: segmentoId,
      periodo: partida.periodo,
      repeticion: repeticion,
      error: error,
      datos: datos,
      notas: notas,
    );
  }
}
