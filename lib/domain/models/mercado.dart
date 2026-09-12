import 'competidor.dart';
import 'evento.dart';
import 'segmento.dart';

/// Un mercado completo: segmentos, competidores, estructura de costos y
/// calendario de eventos.
///
/// El mercado es inmutable. Todo lo que cambia durante la partida (el costo de
/// los insumos, el tamano de un segmento tras un evento) vive en
/// [EstadoMercado], para que la definicion del escenario siga siendo la misma
/// para toda el aula.
class Mercado {
  const Mercado({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.contexto,
    required this.unidad,
    required this.tamanoDeclarado,
    required this.segmentos,
    required this.costoBase,
    required this.costoFijo,
    required this.cajaInicial,
    required this.limiteSobregiro,
    required this.periodos,
    required this.competidoresBase,
    required this.eventos,
    required this.leccion,
    required this.utilidadReferencia,
  });

  final String id;
  final String nombre;
  final String categoria;

  /// Briefing que el estudiante lee antes de decidir.
  final String contexto;

  /// Nombre de la unidad vendida ("botella", "mochila", "matricula").
  final String unidad;

  /// Tamaño total aproximado de la categoría, en unidades por periodo. Es
  /// información pública: aparece en el briefing y no requiere estudio. El
  /// reparto entre segmentos, en cambio, hay que investigarlo.
  final double tamanoDeclarado;

  final List<Segmento> segmentos;

  /// Costo base de una unidad de calidad media, antes de ajustes.
  final double costoBase;

  /// Costo fijo de operacion por periodo, independiente del volumen.
  final double costoFijo;

  final double cajaInicial;

  /// Deuda maxima tolerada antes de la quiebra tecnica.
  final double limiteSobregiro;

  final int periodos;
  final List<Competidor> competidoresBase;
  final List<Evento> eventos;

  /// Utilidad acumulada que alcanza la mejor estrategia conocida en este
  /// escenario, medida en la calibración. Sirve de referencia para evaluar al
  /// estudiante contra algo verificado y no contra una opinión.
  final double utilidadReferencia;

  /// Lo que este escenario esta disenado para ensenar. Se muestra recien al
  /// cerrar la partida, nunca antes.
  final String leccion;

  Segmento? segmentoPorId(String id) {
    for (final Segmento s in segmentos) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<Evento> eventosDe(int periodo) =>
      eventos.where((Evento e) => e.periodo == periodo).toList();

  List<Competidor> clonarCompetidores() =>
      competidoresBase.map((Competidor c) => c.copia()).toList();
}

/// Lo que el mercado acumula a lo largo de la partida por efecto de los
/// eventos. Se guarda con la partida, no con el mercado.
class EstadoMercado {
  EstadoMercado({this.factorCosto = 1.0, Map<String, double>? factorTamano})
      : factorTamano = factorTamano ?? <String, double>{};

  double factorCosto;
  final Map<String, double> factorTamano;

  double costoBase(Mercado m) => m.costoBase * factorCosto;

  double tamano(Segmento s) => s.tamano * (factorTamano[s.id] ?? 1.0);

  EstadoMercado copia() => EstadoMercado(
        factorCosto: factorCosto,
        factorTamano: Map<String, double>.from(factorTamano),
      );

  Map<String, dynamic> aJson() => <String, dynamic>{
        'factorCosto': factorCosto,
        'factorTamano': factorTamano,
      };

  static EstadoMercado desdeJson(Map<String, dynamic> j) {
    final Map<String, dynamic> crudo =
        Map<String, dynamic>.from(j['factorTamano'] as Map<dynamic, dynamic>);
    return EstadoMercado(
      factorCosto: (j['factorCosto'] as num).toDouble(),
      factorTamano: crudo.map((String k, dynamic v) =>
          MapEntry<String, double>(k, (v as num).toDouble())),
    );
  }
}
