import 'dart:math' as math;

import '../models/canal.dart';
import '../models/decisiones.dart';
import '../models/estudio.dart';
import '../models/medio.dart';
import '../models/mercado.dart';
import '../models/partida.dart';
import '../models/resultado_periodo.dart';
import '../models/segmento.dart';

/// Un componente medido dentro de una competencia.
class Componente {
  const Componente({
    required this.etiqueta,
    required this.puntaje,
    required this.peso,
    required this.detalle,
  });

  final String etiqueta;

  /// De 0 a 100.
  final double puntaje;
  final double peso;
  final String detalle;
}

/// La nota de una competencia profesional.
class NotaCompetencia {
  const NotaCompetencia({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.puntaje,
    required this.componentes,
    required this.comentario,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final double puntaje;
  final List<Componente> componentes;
  final String comentario;

  String get nivel {
    if (puntaje >= 85) return 'Destacado';
    if (puntaje >= 70) return 'Competente';
    if (puntaje >= 50) return 'En proceso';
    return 'Inicial';
  }
}

/// Informe de cierre de la partida.
class Evaluacion {
  const Evaluacion({
    required this.competencias,
    required this.puntajeGlobal,
    required this.resumen,
    required this.leccion,
  });

  final List<NotaCompetencia> competencias;
  final double puntajeGlobal;
  final String resumen;

  /// Lo que el escenario estaba diseñado para enseñar. Se revela al final.
  final String leccion;
}

/// Evalúa la partida por competencias, no por resultado.
///
/// Una partida puede terminar con mucha utilidad por haber elegido el mercado
/// fácil, y con poca utilidad habiendo tomado buenas decisiones frente a un
/// competidor agresivo. Por eso el resultado pesa menos de la mitad: lo que se
/// califica es el proceso comercial.
class Evaluador {
  const Evaluador._();

  static Evaluacion evaluar(Partida partida, Mercado mercado) {
    final List<NotaCompetencia> competencias = <NotaCompetencia>[
      _segmentacion(partida, mercado),
      _investigacion(partida, mercado),
      _estrategia(partida, mercado),
      _posicionamiento(partida, mercado),
    ];
    double global = 0.0;
    for (final NotaCompetencia c in competencias) {
      global += c.puntaje * 0.25;
    }
    return Evaluacion(
      competencias: competencias,
      puntajeGlobal: global,
      resumen: _resumen(partida, mercado, global),
      leccion: mercado.leccion,
    );
  }

  // ------------------------------------------------------------ utilidades

  static double _limitar(double v, double min, double max) =>
      math.max(min, math.min(max, v));

  static double _promedio(List<double> valores) {
    if (valores.isEmpty) return 0.0;
    double suma = 0.0;
    for (final double v in valores) {
      suma += v;
    }
    return suma / valores.length;
  }

  static double _ponderar(List<Componente> cs) {
    double total = 0.0;
    double pesos = 0.0;
    for (final Componente c in cs) {
      total += c.puntaje * c.peso;
      pesos += c.peso;
    }
    return pesos > 0 ? total / pesos : 0.0;
  }

  // --------------------------------------------------------- segmentación

  static NotaCompetencia _segmentacion(Partida partida, Mercado mercado) {
    final List<double> focos = <double>[];
    for (int i = 0; i < partida.historial.length; i++) {
      final ResultadoPeriodo r = partida.historial[i];
      if (r.unidades <= 0) continue;
      final Decisiones? d = i < partida.decisionesTomadas.length
          ? partida.decisionesTomadas[i]
          : null;
      if (d == null) continue;
      final ResultadoSegmento? objetivo = r.segmento(d.segmentoObjetivo);
      focos.add(objetivo == null ? 0.0 : objetivo.unidades / r.unidades);
    }
    final double foco = _promedio(focos);

    int cambios = 0;
    for (int i = 1; i < partida.decisionesTomadas.length; i++) {
      if (partida.decisionesTomadas[i].segmentoObjetivo !=
          partida.decisionesTomadas[i - 1].segmentoObjetivo) {
        cambios++;
      }
    }
    final int transiciones = math.max(1, partida.decisionesTomadas.length - 1);
    final double estabilidad = 1.0 - cambios / transiciones;

    int viables = 0;
    for (int i = 0; i < partida.historial.length; i++) {
      final ResultadoPeriodo r = partida.historial[i];
      final Decisiones? d = i < partida.decisionesTomadas.length
          ? partida.decisionesTomadas[i]
          : null;
      if (d == null) continue;
      final ResultadoSegmento? objetivo = r.segmento(d.segmentoObjetivo);
      final double estructura =
          mercado.costoFijo + d.costoFijoCanales + d.gastoMedios;
      if (objetivo != null && objetivo.ingreso >= estructura * 0.6) viables++;
    }
    final double viabilidad = partida.historial.isEmpty
        ? 0.0
        : viables / partida.historial.length;

    final List<Componente> componentes = <Componente>[
      Componente(
        etiqueta: 'Foco en el objetivo',
        puntaje: _limitar(foco / 0.60 * 100, 0, 100),
        peso: 0.40,
        detalle:
            '${(foco * 100).round()}% de tus unidades salieron del segmento '
            'que declaraste como objetivo.',
      ),
      Componente(
        etiqueta: 'Estabilidad del objetivo',
        puntaje: _limitar(estabilidad * 100, 0, 100),
        peso: 0.25,
        detalle: cambios == 0
            ? 'Mantuviste el mismo segmento objetivo toda la partida.'
            : 'Cambiaste de segmento objetivo $cambios vez/veces.',
      ),
      Componente(
        etiqueta: 'Viabilidad del segmento elegido',
        puntaje: _limitar(viabilidad * 100, 0, 100),
        peso: 0.35,
        detalle:
            'En $viables de ${partida.historial.length} periodos, el ingreso '
            'del segmento objetivo alcanzó para sostener tu estructura de '
            'costos.',
      ),
    ];
    final double puntaje = _ponderar(componentes);

    String comentario;
    if (foco < 0.35) {
      comentario =
          'Declaraste un objetivo pero tu mezcla comercial le habló a todo el '
          'mercado. Segmentar no es escribir un nombre en una pantalla: es '
          'aceptar renunciar a los demás segmentos.';
    } else if (estabilidad < 0.7) {
      comentario =
          'Elegiste bien pero cambiaste de objetivo en el camino. Cada cambio '
          'reinicia el reconocimiento de marca que habías comprado.';
    } else if (viabilidad < 0.5) {
      comentario =
          'Sostuviste el foco, pero el segmento elegido no daba el volumen '
          'necesario para tu estructura de costos. Un buen perfil no compensa '
          'un tamaño insuficiente.';
    } else {
      comentario =
          'Elegiste un segmento viable, lo sostuviste y la mezcla efectivamente '
          'le habló a ese segmento. Eso es segmentar.';
    }
    return NotaCompetencia(
      id: 'segmentacion',
      nombre: 'Segmentación',
      descripcion:
          'Elegir un grupo de clientes y renunciar conscientemente al resto.',
      puntaje: puntaje,
      componentes: componentes,
      comentario: comentario,
    );
  }

  // ------------------------------------------------------- investigación

  static NotaCompetencia _investigacion(Partida partida, Mercado mercado) {
    final String objetivoFinal = partida.decisionesTomadas.isNotEmpty
        ? partida.decisionesTomadas.last.segmentoObjetivo
        : partida.decisiones.segmentoObjetivo;

    int cubiertos = 0;
    for (final String id in <String>['perfil', 'precio', 'canales', 'medios']) {
      final bool temprano = partida.hallazgos.any((Hallazgo h) =>
          h.estudioId == id && h.segmentoId == objetivoFinal && h.periodo <= 2);
      if (temprano) cubiertos++;
    }
    final double cobertura = cubiertos / 4.0;

    double gastoComercial = 0.0;
    double gastoInvestigacion = 0.0;
    for (final ResultadoPeriodo r in partida.historial) {
      gastoComercial += r.gastoMedios + r.costoCanales;
      gastoInvestigacion += r.gastoInvestigacion;
    }
    final double proporcion =
        gastoComercial > 0 ? gastoInvestigacion / gastoComercial : 0.0;
    double eficiencia;
    if (proporcion < 0.03) {
      eficiencia = proporcion / 0.03 * 0.6;
    } else if (proporcion <= 0.20) {
      eficiencia = 1.0;
    } else {
      eficiencia = math.max(0.0, 1.0 - (proporcion - 0.20) / 0.30);
    }

    int decisionesContraEvidencia = 0;
    int decisionesEvaluadas = 0;
    final Segmento? objetivoReal = mercado.segmentoPorId(objetivoFinal);
    for (final Decisiones d in partida.decisionesTomadas) {
      if (objetivoReal == null) continue;
      if (partida.conoce('medios', objetivoFinal)) {
        for (final Medio m in Medio.values) {
          if (d.gastoEn(m) > 0) {
            decisionesEvaluadas++;
            if (objetivoReal.afinidadDe(m) < 0.15) decisionesContraEvidencia++;
          }
        }
      }
      if (partida.conoce('canales', objetivoFinal)) {
        for (final Canal c in d.canales) {
          decisionesEvaluadas++;
          if (objetivoReal.coberturaDe(c) < 0.12) decisionesContraEvidencia++;
        }
      }
    }
    final double coherencia = decisionesEvaluadas == 0
        ? 0.5
        : 1.0 - decisionesContraEvidencia / decisionesEvaluadas;

    final List<Componente> componentes = <Componente>[
      Componente(
        etiqueta: 'Evidencia antes de decidir',
        puntaje: _limitar(cobertura * 100, 0, 100),
        peso: 0.40,
        detalle:
            'Contrataste $cubiertos de los 4 estudios clave de tu objetivo '
            'dentro de los tres primeros periodos.',
      ),
      Componente(
        etiqueta: 'Eficiencia de la inversión en información',
        puntaje: _limitar(eficiencia * 100, 0, 100),
        peso: 0.30,
        detalle:
            'La investigación representó ${(proporcion * 100).toStringAsFixed(1)}% '
            'de tu gasto comercial. El rango razonable está entre 3% y 20%.',
      ),
      Componente(
        etiqueta: 'Coherencia con la evidencia',
        puntaje: _limitar(coherencia * 100, 0, 100),
        peso: 0.30,
        detalle: decisionesEvaluadas == 0
            ? 'No hubo datos suficientes para verificar si tus decisiones '
                'seguían la evidencia.'
            : '$decisionesContraEvidencia de $decisionesEvaluadas decisiones de '
                'medios y canales contradijeron un estudio que ya habías '
                'pagado.',
      ),
    ];

    String comentario;
    if (cobertura < 0.5) {
      comentario =
          'Decidiste antes de saber. Investigar después de haber fijado el '
          'precio y la campaña sirve para justificar, no para decidir.';
    } else if (coherencia < 0.7) {
      comentario =
          'Compraste la información y luego decidiste en contra de ella. Es el '
          'error más caro de los dos: pagaste el estudio y además el error.';
    } else if (proporcion > 0.25) {
      comentario =
          'Investigaste de más. Pasado cierto punto, un dato más preciso ya no '
          'cambia ninguna decisión y ese dinero rinde más en ejecución.';
    } else {
      comentario =
          'Compraste la información que cambiaba decisiones, en el momento en '
          'que todavía podía cambiarlas, y decidiste en consecuencia.';
    }
    return NotaCompetencia(
      id: 'investigacion',
      nombre: 'Investigación de mercado',
      descripcion:
          'Comprar información cuando reduce incertidumbre y usarla al decidir.',
      puntaje: _ponderar(componentes),
      componentes: componentes,
      comentario: comentario,
    );
  }

  // -------------------------------------------------------- estrategia

  static NotaCompetencia _estrategia(Partida partida, Mercado mercado) {
    final double utilidad = partida.utilidadAcumulada;
    final double resultado =
        _limitar(utilidad / mercado.utilidadReferencia, 0.0, 1.0);

    final List<double> participaciones = partida.historial
        .map((ResultadoPeriodo r) => r.participacion)
        .toList();
    final double participacion = _promedio(participaciones);

    int periodosConMargen = 0;
    for (final ResultadoPeriodo r in partida.historial) {
      if (r.margenPorcentaje >= 0.20) periodosConMargen++;
    }
    double sostenibilidad = partida.historial.isEmpty
        ? 0.0
        : periodosConMargen / partida.historial.length;
    if (partida.quiebra) sostenibilidad = 0.0;
    if (partida.caja < mercado.cajaInicial) {
      sostenibilidad = sostenibilidad * 0.7;
    }

    final List<Componente> componentes = <Componente>[
      Componente(
        etiqueta: 'Resultado económico',
        puntaje: _limitar(resultado * 100, 0, 100),
        peso: 0.45,
        detalle:
            'Utilidad acumulada de S/ ${utilidad.toStringAsFixed(0)} frente a '
            'S/ ${mercado.utilidadReferencia.toStringAsFixed(0)} de la mejor '
            'estrategia verificada en este escenario.',
      ),
      Componente(
        etiqueta: 'Participación de mercado',
        puntaje: _limitar(participacion / 0.35 * 100, 0, 100),
        peso: 0.25,
        detalle:
            'Participación promedio de ${(participacion * 100).toStringAsFixed(1)}% '
            'en unidades.',
      ),
      Componente(
        etiqueta: 'Sostenibilidad',
        puntaje: _limitar(sostenibilidad * 100, 0, 100),
        peso: 0.30,
        detalle: partida.quiebra
            ? 'La partida terminó en quiebra técnica.'
            : 'Margen bruto sobre 20% en $periodosConMargen de '
                '${partida.historial.length} periodos.',
      ),
    ];

    String comentario;
    if (partida.quiebra) {
      comentario =
          'La partida terminó antes de tiempo. Participación comprada con '
          'margen negativo no es participación: es financiar al cliente.';
    } else if (resultado > 0.7 && sostenibilidad > 0.6) {
      comentario =
          'Resultado sólido y sostenible: creciste sin comprometer el margen.';
    } else if (participacion > 0.30 && resultado < 0.4) {
      comentario =
          'Ganaste volumen pero no utilidad. Revisa el precio y el margen que '
          'se quedan tus canales: estás vendiendo mucho y ganando poco.';
    } else {
      comentario =
          'El resultado quedó por debajo de lo que este mercado permite. '
          'Compara tu estrategia con la lección del escenario, más abajo.';
    }
    return NotaCompetencia(
      id: 'estrategia',
      nombre: 'Estrategia comercial',
      descripcion:
          'Convertir decisiones de mezcla en resultados sostenibles en el tiempo.',
      puntaje: _ponderar(componentes),
      componentes: componentes,
      comentario: comentario,
    );
  }

  // ----------------------------------------------------- posicionamiento

  static NotaCompetencia _posicionamiento(Partida partida, Mercado mercado) {
    final List<double> coherencias = <double>[];
    for (final Decisiones d in partida.decisionesTomadas) {
      final double brecha = (d.nivelPromesa - d.calidad).abs();
      double c = 1.0 - brecha / 4.0;
      if (d.beneficioReal != d.beneficioPrometido) c -= 0.35;
      coherencias.add(_limitar(c, 0.0, 1.0));
    }
    final double coherencia = _promedio(coherencias);

    final List<double> satisfacciones = partida.historial
        .where((ResultadoPeriodo r) => r.unidades > 0)
        .map((ResultadoPeriodo r) => r.satisfaccion)
        .toList();
    final double satisfaccion = _promedio(satisfacciones);

    final double claridad = partida.estadoMarca.claridad;

    final List<Componente> componentes = <Componente>[
      Componente(
        etiqueta: 'Coherencia entre promesa y producto',
        puntaje: _limitar(coherencia * 100, 0, 100),
        peso: 0.40,
        detalle:
            'Distancia promedio entre lo que comunicaste y lo que el producto '
            'entregaba.',
      ),
      Componente(
        etiqueta: 'Satisfacción del cliente',
        puntaje: _limitar((satisfaccion - 0.30) / 0.50 * 100, 0, 100),
        peso: 0.35,
        detalle:
            'Satisfacción promedio de ${(satisfaccion * 100).round()}% a lo '
            'largo de la partida.',
      ),
      Componente(
        etiqueta: 'Claridad de marca alcanzada',
        puntaje: _limitar(claridad / 0.90 * 100, 0, 100),
        peso: 0.25,
        detalle:
            'Claridad final de ${(claridad * 100).round()}%. Se construye '
            'repitiendo el mismo posicionamiento con inversión sostenida.',
      ),
    ];

    String comentario;
    if (coherencia < 0.6) {
      comentario =
          'Tu campaña y tu producto contaban historias distintas. La promesa '
          'atrae una sola vez; el producto es el que retiene.';
    } else if (satisfaccion < 0.5) {
      comentario =
          'La expectativa que generaste fue mayor que lo que entregaste. La '
          'satisfacción no mide calidad absoluta: mide entrega menos promesa.';
    } else if (claridad < 0.55) {
      comentario =
          'Fuiste coherente pero no constante. El mercado necesita varios '
          'periodos de repetición para reconocer una marca.';
    } else {
      comentario =
          'Construiste una posición clara y la respaldaste con el producto. '
          'Eso es lo que hace que la publicidad del periodo siete valga más '
          'que la del periodo uno.';
    }
    return NotaCompetencia(
      id: 'posicionamiento',
      nombre: 'Posicionamiento',
      descripcion:
          'Ocupar un lugar reconocible en la mente del segmento y sostenerlo.',
      puntaje: _ponderar(componentes),
      componentes: componentes,
      comentario: comentario,
    );
  }

  static String _resumen(Partida partida, Mercado mercado, double global) {
    final String desempeno = global >= 85
        ? 'Manejaste la marca como se maneja una marca real.'
        : global >= 70
            ? 'Tomaste decisiones comerciales sólidas con puntos concretos por '
                'corregir.'
            : global >= 50
                ? 'Hay una estrategia reconocible, pero la ejecución la '
                    'contradice en varios puntos.'
                : 'Las decisiones se tomaron sueltas, sin una estrategia que '
                    'las ordenara.';
    return 'Cerraste ${partida.historial.length} de ${mercado.periodos} '
        'periodos en ${mercado.nombre} con una utilidad acumulada de S/ '
        '${partida.utilidadAcumulada.toStringAsFixed(0)} y una participación '
        'final de '
        '${((partida.ultimoResultado?.participacion ?? 0) * 100).toStringAsFixed(1)}%. '
        '$desempeno';
  }
}
