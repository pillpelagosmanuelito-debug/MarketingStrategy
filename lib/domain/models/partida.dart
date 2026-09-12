import 'competidor.dart';
import 'decisiones.dart';
import 'estado_marca.dart';
import 'estudio.dart';
import 'mercado.dart';
import 'resultado_periodo.dart';

/// El estado completo de una partida.
///
/// Todo lo que el estudiante ha hecho y visto. No contiene los parametros
/// ocultos del mercado: esos viven en el catalogo y se identifican por
/// [mercadoId], de modo que lo que se guarda en el telefono no permita
/// deducir las respuestas.
class Partida {
  Partida({
    required this.mercadoId,
    required this.marca,
    required this.periodo,
    required this.caja,
    required this.decisiones,
    required this.estadoMarca,
    required this.estadoMercado,
    required this.competidores,
    required this.historial,
    required this.decisionesTomadas,
    required this.hallazgos,
    required this.eventosVistos,
    this.terminada = false,
    this.quiebra = false,
  });

  final String mercadoId;

  /// Nombre que el estudiante le puso a su marca.
  final String marca;

  /// Periodo en curso (0 = primero).
  int periodo;
  double caja;

  /// Decisiones del periodo en curso, aun no cerradas.
  Decisiones decisiones;
  EstadoMarca estadoMarca;
  EstadoMercado estadoMercado;
  List<Competidor> competidores;
  final List<ResultadoPeriodo> historial;

  /// Decisiones con las que se cerró cada periodo. Es lo que permite evaluar
  /// el proceso y no solo el resultado.
  final List<Decisiones> decisionesTomadas;
  final List<Hallazgo> hallazgos;

  /// Titulos de los eventos ya mostrados, para no repetirlos.
  final List<String> eventosVistos;

  bool terminada;
  bool quiebra;

  double get utilidadAcumulada =>
      historial.fold(0.0, (double a, ResultadoPeriodo r) => a + r.utilidad);

  double get gastoInvestigacionAcumulado =>
      historial.fold(
          0.0, (double a, ResultadoPeriodo r) => a + r.gastoInvestigacion) +
      decisiones.investigacion;

  ResultadoPeriodo? get ultimoResultado =>
      historial.isEmpty ? null : historial.last;

  /// Cuantas veces se contrato un estudio (para un segmento, si aplica).
  int repeticionesDe(String estudioId, String segmentoId) {
    return hallazgos
        .where((Hallazgo h) =>
            h.estudioId == estudioId && h.segmentoId == segmentoId)
        .length;
  }

  /// El hallazgo mas preciso disponible para un estudio y segmento.
  Hallazgo? mejorHallazgo(String estudioId, String segmentoId) {
    Hallazgo? mejor;
    for (final Hallazgo h in hallazgos) {
      if (h.estudioId != estudioId || h.segmentoId != segmentoId) continue;
      if (mejor == null || h.error < mejor.error) mejor = h;
    }
    return mejor;
  }

  bool conoce(String estudioId, String segmentoId) =>
      mejorHallazgo(estudioId, segmentoId) != null;

  Map<String, dynamic> aJson() => <String, dynamic>{
        'mercadoId': mercadoId,
        'marca': marca,
        'periodo': periodo,
        'caja': caja,
        'decisiones': decisiones.aJson(),
        'estadoMarca': estadoMarca.aJson(),
        'estadoMercado': estadoMercado.aJson(),
        'competidores':
            competidores.map((Competidor c) => c.aJson()).toList(),
        'historial': historial.map((ResultadoPeriodo r) => r.aJson()).toList(),
        'decisionesTomadas':
            decisionesTomadas.map((Decisiones x) => x.aJson()).toList(),
        'hallazgos': hallazgos.map((Hallazgo h) => h.aJson()).toList(),
        'eventosVistos': eventosVistos,
        'terminada': terminada,
        'quiebra': quiebra,
      };

  /// Reconstruye la partida. Los competidores se reconstruyen desde el
  /// catalogo (para no guardar la definicion del escenario) y se les restaura
  /// unicamente el estado que cambio durante el juego.
  static Partida desdeJson(Map<String, dynamic> j, Mercado mercado) {
    final List<Competidor> base = mercado.clonarCompetidores();
    final List<dynamic> guardados = j['competidores'] as List<dynamic>;
    for (final dynamic crudo in guardados) {
      final Map<String, dynamic> mapa =
          Map<String, dynamic>.from(crudo as Map<dynamic, dynamic>);
      for (final Competidor c in base) {
        if (c.id != mapa['id']) continue;
        c.decisiones = Decisiones.desdeJson(
            Map<String, dynamic>.from(mapa['decisiones'] as Map<dynamic, dynamic>));
        c.estado = EstadoMarca.desdeJson(
            Map<String, dynamic>.from(mapa['estado'] as Map<dynamic, dynamic>));
      }
    }
    return Partida(
      mercadoId: j['mercadoId'] as String,
      marca: j['marca'] as String,
      periodo: (j['periodo'] as num).toInt(),
      caja: (j['caja'] as num).toDouble(),
      decisiones: Decisiones.desdeJson(
          Map<String, dynamic>.from(j['decisiones'] as Map<dynamic, dynamic>)),
      estadoMarca: EstadoMarca.desdeJson(
          Map<String, dynamic>.from(j['estadoMarca'] as Map<dynamic, dynamic>)),
      estadoMercado: EstadoMercado.desdeJson(
          Map<String, dynamic>.from(j['estadoMercado'] as Map<dynamic, dynamic>)),
      competidores: base,
      historial: (j['historial'] as List<dynamic>)
          .map((dynamic r) => ResultadoPeriodo.desdeJson(
              Map<String, dynamic>.from(r as Map<dynamic, dynamic>)))
          .toList(),
      decisionesTomadas: ((j['decisionesTomadas'] as List<dynamic>?) ??
              <dynamic>[])
          .map((dynamic x) => Decisiones.desdeJson(
              Map<String, dynamic>.from(x as Map<dynamic, dynamic>)))
          .toList(),
      hallazgos: (j['hallazgos'] as List<dynamic>)
          .map((dynamic h) => Hallazgo.desdeJson(
              Map<String, dynamic>.from(h as Map<dynamic, dynamic>)))
          .toList(),
      eventosVistos: (j['eventosVistos'] as List<dynamic>)
          .map((dynamic e) => e as String)
          .toList(),
      terminada: j['terminada'] as bool? ?? false,
      quiebra: j['quiebra'] as bool? ?? false,
    );
  }
}
