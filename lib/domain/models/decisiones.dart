import 'beneficio.dart';
import 'canal.dart';
import 'medio.dart';

/// Las decisiones comerciales de un periodo.
///
/// Un solo objeto reune las cinco decisiones porque el motor las resuelve
/// juntas: el precio no significa nada sin la promesa, y la promesa no
/// significa nada sin el producto que la respalda.
class Decisiones {
  Decisiones({
    required this.segmentoObjetivo,
    required this.beneficioPrometido,
    required this.nivelPromesa,
    required this.calidad,
    required this.beneficioReal,
    required this.amplitud,
    required this.precio,
    required this.canales,
    required this.medios,
    this.investigacion = 0.0,
  });

  /// Segmento al que se dirige la marca (modulo Cliente).
  final String segmentoObjetivo;

  /// Beneficio que la comunicacion promete (modulo Cliente).
  final Beneficio beneficioPrometido;

  /// Que tan premium se declara la marca, de 1 a 5 (modulo Cliente).
  final double nivelPromesa;

  /// Calidad real del producto, de 1 a 5 (modulo Producto).
  final double calidad;

  /// Beneficio que el producto realmente entrega (modulo Producto).
  final Beneficio beneficioReal;

  /// Amplitud de linea: 1 a 3 presentaciones (modulo Producto).
  final int amplitud;

  /// Precio de venta al publico en soles (modulo Precio).
  final double precio;

  /// Canales en los que la marca esta presente (modulo Campanas).
  final Set<Canal> canales;

  /// Inversion por medio en soles (modulo Campanas).
  final Map<Medio, double> medios;

  /// Gasto en estudios de mercado del periodo (modulo Mercado).
  final double investigacion;

  double get gastoMedios =>
      medios.values.fold(0.0, (double a, double b) => a + b);

  double gastoEn(Medio m) => medios[m] ?? 0.0;

  double get costoFijoCanales =>
      canales.fold(0.0, (double a, Canal c) => a + c.costoFijo);

  /// Firma del posicionamiento. Si cambia entre periodos, la marca pierde
  /// claridad: el mercado deja de saber quien es.
  String get firmaPosicionamiento =>
      '$segmentoObjetivo|${beneficioPrometido.id}|${nivelPromesa.round()}';

  Decisiones copiarCon({
    String? segmentoObjetivo,
    Beneficio? beneficioPrometido,
    double? nivelPromesa,
    double? calidad,
    Beneficio? beneficioReal,
    int? amplitud,
    double? precio,
    Set<Canal>? canales,
    Map<Medio, double>? medios,
    double? investigacion,
  }) {
    return Decisiones(
      segmentoObjetivo: segmentoObjetivo ?? this.segmentoObjetivo,
      beneficioPrometido: beneficioPrometido ?? this.beneficioPrometido,
      nivelPromesa: nivelPromesa ?? this.nivelPromesa,
      calidad: calidad ?? this.calidad,
      beneficioReal: beneficioReal ?? this.beneficioReal,
      amplitud: amplitud ?? this.amplitud,
      precio: precio ?? this.precio,
      canales: canales ?? Set<Canal>.from(this.canales),
      medios: medios ?? Map<Medio, double>.from(this.medios),
      investigacion: investigacion ?? this.investigacion,
    );
  }

  Map<String, dynamic> aJson() => <String, dynamic>{
        'segmentoObjetivo': segmentoObjetivo,
        'beneficioPrometido': beneficioPrometido.id,
        'nivelPromesa': nivelPromesa,
        'calidad': calidad,
        'beneficioReal': beneficioReal.id,
        'amplitud': amplitud,
        'precio': precio,
        'canales': canales.map((Canal c) => c.id).toList(),
        'medios': medios.map(
            (Medio m, double v) => MapEntry<String, double>(m.id, v)),
        'investigacion': investigacion,
      };

  static Decisiones desdeJson(Map<String, dynamic> j) {
    final Map<Medio, double> medios = <Medio, double>{};
    final Map<String, dynamic> crudos =
        Map<String, dynamic>.from(j['medios'] as Map<dynamic, dynamic>);
    for (final MapEntry<String, dynamic> e in crudos.entries) {
      medios[Medio.desdeId(e.key)] = (e.value as num).toDouble();
    }
    final List<dynamic> canales = j['canales'] as List<dynamic>;
    return Decisiones(
      segmentoObjetivo: j['segmentoObjetivo'] as String,
      beneficioPrometido: Beneficio.desdeId(j['beneficioPrometido'] as String),
      nivelPromesa: (j['nivelPromesa'] as num).toDouble(),
      calidad: (j['calidad'] as num).toDouble(),
      beneficioReal: Beneficio.desdeId(j['beneficioReal'] as String),
      amplitud: (j['amplitud'] as num).toInt(),
      precio: (j['precio'] as num).toDouble(),
      canales: canales
          .map((dynamic c) => Canal.desdeId(c as String))
          .toSet(),
      medios: medios,
      investigacion: (j['investigacion'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
