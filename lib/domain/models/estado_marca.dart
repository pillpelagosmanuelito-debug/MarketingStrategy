/// Lo que una marca arrastra de un periodo al siguiente.
///
/// Es la memoria del mercado sobre la marca. No se decide: se construye o se
/// destruye con las decisiones de periodos anteriores.
class EstadoMarca {
  EstadoMarca({
    required this.awareness,
    this.reputacion = 0.50,
    this.claridad = 0.35,
    this.satisfaccionPrevia = 0.55,
    Map<String, double>? participacionPrevia,
    this.acumulado = 0.0,
    this.posicionPrevia = '',
  }) : participacionPrevia = participacionPrevia ?? <String, double>{};

  /// Recuerdo de marca por segmento (0 a 1).
  final Map<String, double> awareness;

  /// Reputacion: satisfaccion acumulada de los compradores (0 a 1).
  double reputacion;

  /// Claridad del posicionamiento: que tan nitida es la marca (0 a 1).
  double claridad;

  /// Satisfaccion del periodo anterior, motor del boca a boca.
  double satisfaccionPrevia;

  /// Participacion lograda en cada segmento el periodo anterior (inercia).
  final Map<String, double> participacionPrevia;

  /// Unidades acumuladas: alimenta la curva de experiencia en costos.
  double acumulado;

  /// Firma del posicionamiento del periodo anterior.
  String posicionPrevia;

  EstadoMarca copia() => EstadoMarca(
        awareness: Map<String, double>.from(awareness),
        reputacion: reputacion,
        claridad: claridad,
        satisfaccionPrevia: satisfaccionPrevia,
        participacionPrevia: Map<String, double>.from(participacionPrevia),
        acumulado: acumulado,
        posicionPrevia: posicionPrevia,
      );

  Map<String, dynamic> aJson() => <String, dynamic>{
        'awareness': awareness,
        'reputacion': reputacion,
        'claridad': claridad,
        'satisfaccionPrevia': satisfaccionPrevia,
        'participacionPrevia': participacionPrevia,
        'acumulado': acumulado,
        'posicionPrevia': posicionPrevia,
      };

  static EstadoMarca desdeJson(Map<String, dynamic> j) {
    Map<String, double> mapa(String clave) {
      final Map<String, dynamic> crudo =
          Map<String, dynamic>.from(j[clave] as Map<dynamic, dynamic>);
      return crudo.map((String k, dynamic v) =>
          MapEntry<String, double>(k, (v as num).toDouble()));
    }

    return EstadoMarca(
      awareness: mapa('awareness'),
      reputacion: (j['reputacion'] as num).toDouble(),
      claridad: (j['claridad'] as num).toDouble(),
      satisfaccionPrevia: (j['satisfaccionPrevia'] as num).toDouble(),
      participacionPrevia: mapa('participacionPrevia'),
      acumulado: (j['acumulado'] as num).toDouble(),
      posicionPrevia: j['posicionPrevia'] as String,
    );
  }
}
