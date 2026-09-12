/// Tipos de estudio de mercado que el estudiante puede contratar.
enum TipoEstudio {
  tamanoMercado,
  perfilSegmento,
  pruebaPrecio,
  auditoriaCanales,
  habitosMedios,
  mysteryShopper,
  satisfaccionMarca,
}

/// Un estudio de mercado disponible para contratar.
///
/// Ningun estudio devuelve la verdad: todos devuelven una estimacion con error
/// de muestreo. Repetir el mismo estudio reduce el error a la mitad, pero
/// cuesta lo mismo cada vez, asi que la tercera repeticion casi nunca se paga.
class Estudio {
  const Estudio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.costo,
    required this.tipo,
    required this.porSegmento,
    required this.errorBase,
    this.desdePeriodo = 0,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final double costo;
  final TipoEstudio tipo;

  /// Si es true, el estudio se contrata para un segmento especifico.
  final bool porSegmento;

  /// Error relativo de la primera medicion (0.18 = mas o menos 18%).
  final double errorBase;

  /// Periodo a partir del cual el estudio tiene sentido.
  final int desdePeriodo;
}

/// Lo que un estudio devolvio. Es la unica fuente de datos numericos que el
/// estudiante —y el analista— tienen sobre el mercado.
class Hallazgo {
  const Hallazgo({
    required this.estudioId,
    required this.segmentoId,
    required this.periodo,
    required this.repeticion,
    required this.error,
    required this.datos,
    required this.notas,
  });

  final String estudioId;

  /// Vacio si el estudio no es por segmento.
  final String segmentoId;
  final int periodo;

  /// 1 = primera vez que se contrata, 2 = segunda, etc.
  final int repeticion;

  /// Error relativo de esta medicion.
  final double error;

  /// Valores estimados, ya con el error aplicado.
  final Map<String, double> datos;
  final List<String> notas;

  String get clave => segmentoId.isEmpty ? estudioId : '$estudioId:$segmentoId';

  double? valor(String campo) => datos[campo];

  Map<String, dynamic> aJson() => <String, dynamic>{
        'estudioId': estudioId,
        'segmentoId': segmentoId,
        'periodo': periodo,
        'repeticion': repeticion,
        'error': error,
        'datos': datos,
        'notas': notas,
      };

  static Hallazgo desdeJson(Map<String, dynamic> j) {
    final Map<String, dynamic> crudo =
        Map<String, dynamic>.from(j['datos'] as Map<dynamic, dynamic>);
    return Hallazgo(
      estudioId: j['estudioId'] as String,
      segmentoId: j['segmentoId'] as String,
      periodo: (j['periodo'] as num).toInt(),
      repeticion: (j['repeticion'] as num).toInt(),
      error: (j['error'] as num).toDouble(),
      datos: crudo.map((String k, dynamic v) =>
          MapEntry<String, double>(k, (v as num).toDouble())),
      notas: (j['notas'] as List<dynamic>)
          .map((dynamic n) => n as String)
          .toList(),
    );
  }
}
