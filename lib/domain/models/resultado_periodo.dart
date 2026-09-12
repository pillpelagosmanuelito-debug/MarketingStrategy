/// Resultado de un segmento dentro de un periodo.
class ResultadoSegmento {
  const ResultadoSegmento({
    required this.segmentoId,
    required this.unidades,
    required this.participacion,
    required this.satisfaccion,
    required this.awareness,
    required this.cobertura,
    required this.ingreso,
  });

  final String segmentoId;
  final double unidades;

  /// Participacion dentro del segmento (no del mercado total).
  final double participacion;
  final double satisfaccion;
  final double awareness;
  final double cobertura;
  final double ingreso;

  Map<String, dynamic> aJson() => <String, dynamic>{
        'segmentoId': segmentoId,
        'unidades': unidades,
        'participacion': participacion,
        'satisfaccion': satisfaccion,
        'awareness': awareness,
        'cobertura': cobertura,
        'ingreso': ingreso,
      };

  static ResultadoSegmento desdeJson(Map<String, dynamic> j) =>
      ResultadoSegmento(
        segmentoId: j['segmentoId'] as String,
        unidades: (j['unidades'] as num).toDouble(),
        participacion: (j['participacion'] as num).toDouble(),
        satisfaccion: (j['satisfaccion'] as num).toDouble(),
        awareness: (j['awareness'] as num).toDouble(),
        cobertura: (j['cobertura'] as num).toDouble(),
        ingreso: (j['ingreso'] as num).toDouble(),
      );
}

/// Todo lo que el estudiante ve despues de cerrar un periodo.
///
/// Es tambien todo lo que el analista puede leer: el analista no tiene acceso
/// a los parametros ocultos del mercado, solo a estos resultados y a los
/// estudios que el estudiante compro.
class ResultadoPeriodo {
  const ResultadoPeriodo({
    required this.periodo,
    required this.unidades,
    required this.ingresos,
    required this.costoUnitario,
    required this.costoVariable,
    required this.costoFijo,
    required this.costoCanales,
    required this.gastoMedios,
    required this.gastoInvestigacion,
    required this.impuesto,
    required this.utilidad,
    required this.satisfaccion,
    required this.participacion,
    required this.reputacion,
    required this.claridad,
    required this.cajaFinal,
    required this.segmentos,
    required this.ventasCompetidores,
    required this.eventos,
  });

  final int periodo;
  final double unidades;

  /// Ingreso neto del margen que retienen los canales.
  final double ingresos;
  final double costoUnitario;
  final double costoVariable;
  final double costoFijo;
  final double costoCanales;
  final double gastoMedios;
  final double gastoInvestigacion;
  final double impuesto;
  final double utilidad;

  /// Satisfaccion promedio ponderada por unidades vendidas.
  final double satisfaccion;

  /// Participacion en unidades sobre el total del mercado.
  final double participacion;
  final double reputacion;
  final double claridad;
  final double cajaFinal;
  final List<ResultadoSegmento> segmentos;
  final Map<String, double> ventasCompetidores;
  final List<String> eventos;

  double get costosTotales =>
      costoVariable + costoFijo + costoCanales + gastoMedios + gastoInvestigacion;

  double get margenBruto => ingresos - costoVariable;

  double get margenPorcentaje => ingresos > 0 ? margenBruto / ingresos : 0.0;

  ResultadoSegmento? segmento(String id) {
    for (final ResultadoSegmento s in segmentos) {
      if (s.segmentoId == id) return s;
    }
    return null;
  }

  Map<String, dynamic> aJson() => <String, dynamic>{
        'periodo': periodo,
        'unidades': unidades,
        'ingresos': ingresos,
        'costoUnitario': costoUnitario,
        'costoVariable': costoVariable,
        'costoFijo': costoFijo,
        'costoCanales': costoCanales,
        'gastoMedios': gastoMedios,
        'gastoInvestigacion': gastoInvestigacion,
        'impuesto': impuesto,
        'utilidad': utilidad,
        'satisfaccion': satisfaccion,
        'participacion': participacion,
        'reputacion': reputacion,
        'claridad': claridad,
        'cajaFinal': cajaFinal,
        'segmentos':
            segmentos.map((ResultadoSegmento s) => s.aJson()).toList(),
        'ventasCompetidores': ventasCompetidores,
        'eventos': eventos,
      };

  static ResultadoPeriodo desdeJson(Map<String, dynamic> j) {
    final Map<String, dynamic> ventas = Map<String, dynamic>.from(
        j['ventasCompetidores'] as Map<dynamic, dynamic>);
    return ResultadoPeriodo(
      periodo: (j['periodo'] as num).toInt(),
      unidades: (j['unidades'] as num).toDouble(),
      ingresos: (j['ingresos'] as num).toDouble(),
      costoUnitario: (j['costoUnitario'] as num).toDouble(),
      costoVariable: (j['costoVariable'] as num).toDouble(),
      costoFijo: (j['costoFijo'] as num).toDouble(),
      costoCanales: (j['costoCanales'] as num).toDouble(),
      gastoMedios: (j['gastoMedios'] as num).toDouble(),
      gastoInvestigacion: (j['gastoInvestigacion'] as num).toDouble(),
      impuesto: (j['impuesto'] as num).toDouble(),
      utilidad: (j['utilidad'] as num).toDouble(),
      satisfaccion: (j['satisfaccion'] as num).toDouble(),
      participacion: (j['participacion'] as num).toDouble(),
      reputacion: (j['reputacion'] as num).toDouble(),
      claridad: (j['claridad'] as num).toDouble(),
      cajaFinal: (j['cajaFinal'] as num).toDouble(),
      segmentos: (j['segmentos'] as List<dynamic>)
          .map((dynamic s) =>
              ResultadoSegmento.desdeJson(Map<String, dynamic>.from(s as Map<dynamic, dynamic>)))
          .toList(),
      ventasCompetidores: ventas.map((String k, dynamic v) =>
          MapEntry<String, double>(k, (v as num).toDouble())),
      eventos: (j['eventos'] as List<dynamic>)
          .map((dynamic e) => e as String)
          .toList(),
    );
  }
}
