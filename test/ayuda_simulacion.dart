import 'package:marketing_strategy_lab/domain/engine/motor_simulacion.dart';
import 'package:marketing_strategy_lab/domain/models/beneficio.dart';
import 'package:marketing_strategy_lab/domain/models/canal.dart';
import 'package:marketing_strategy_lab/domain/models/competidor.dart';
import 'package:marketing_strategy_lab/domain/models/decisiones.dart';
import 'package:marketing_strategy_lab/domain/models/estado_marca.dart';
import 'package:marketing_strategy_lab/domain/models/estudio.dart';
import 'package:marketing_strategy_lab/domain/models/partida.dart';
import 'package:marketing_strategy_lab/domain/models/medio.dart';
import 'package:marketing_strategy_lab/domain/models/mercado.dart';
import 'package:marketing_strategy_lab/domain/models/resultado_periodo.dart';
import 'package:marketing_strategy_lab/domain/models/segmento.dart';

/// Resultado de jugar una partida completa con una politica fija.
class Corrida {
  const Corrida({
    required this.historial,
    required this.caja,
    required this.utilidadAcumulada,
    required this.quiebra,
  });

  final List<ResultadoPeriodo> historial;
  final double caja;
  final double utilidadAcumulada;
  final bool quiebra;

  double get satisfaccionPromedio {
    if (historial.isEmpty) return 0;
    double s = 0;
    for (final ResultadoPeriodo r in historial) {
      s += r.satisfaccion;
    }
    return s / historial.length;
  }

  double get participacionFinal =>
      historial.isEmpty ? 0 : historial.last.participacion;

  double get unidadesTotales {
    double u = 0;
    for (final ResultadoPeriodo r in historial) {
      u += r.unidades;
    }
    return u;
  }
}

/// Construye un juego de decisiones completo en una linea.
Decisiones decisiones({
  required String objetivo,
  required Beneficio promesa,
  required double nivel,
  required double calidad,
  required Beneficio real,
  required int amplitud,
  required double precio,
  required Set<Canal> canales,
  required Map<Medio, double> medios,
  double investigacion = 0.0,
}) {
  final Map<Medio, double> completos = <Medio, double>{
    for (final Medio m in Medio.values) m: 0.0
  };
  completos.addAll(medios);
  return Decisiones(
    segmentoObjetivo: objetivo,
    beneficioPrometido: promesa,
    nivelPromesa: nivel,
    calidad: calidad,
    beneficioReal: real,
    amplitud: amplitud,
    precio: precio,
    canales: canales,
    medios: completos,
    investigacion: investigacion,
  );
}

/// Juega una partida completa aplicando la misma politica todos los periodos.
///
/// Es la herramienta de las pruebas de calibracion: no verifica funciones,
/// verifica que el escenario premie lo que dice premiar.
Corrida jugar(
  Mercado mercado,
  Decisiones Function(int periodo) politica, {
  int? periodos,
}) {
  final EstadoMercado estadoMercado = EstadoMercado();
  final List<Competidor> competidores = mercado.clonarCompetidores();
  final EstadoMarca estado = EstadoMarca(
    awareness: <String, double>{
      for (final Segmento s in mercado.segmentos) s.id: 0.04
    },
  );
  final List<ResultadoPeriodo> historial = <ResultadoPeriodo>[];
  double caja = mercado.cajaInicial;
  double acumulada = 0;
  bool quiebra = false;
  final int total = periodos ?? mercado.periodos;

  for (int p = 0; p < total; p++) {
    MotorSimulacion.aplicarEventos(mercado, estadoMercado, competidores, p);
    final Decisiones d = politica(p);
    final ResultadoPeriodo r = MotorSimulacion.simularPeriodo(
      mercado: mercado,
      estadoMercado: estadoMercado,
      decisiones: d,
      estado: estado,
      competidores: competidores,
      periodo: p,
      cajaPrevia: caja,
    );
    caja = r.cajaFinal;
    acumulada += r.utilidad;
    historial.add(r);
    if (caja < -mercado.limiteSobregiro) {
      quiebra = true;
      break;
    }
  }
  return Corrida(
    historial: historial,
    caja: caja,
    utilidadAcumulada: acumulada,
    quiebra: quiebra,
  );
}

/// Construye una partida de dominio (la que usa la aplicacion) jugada con una
/// politica fija. Sirve para probar el analista y el evaluador, que trabajan
/// sobre la partida completa y no sobre resultados sueltos.
Partida partidaJugada(
  Mercado mercado,
  Decisiones Function(int periodo) politica, {
  int periodos = 0,
  List<Hallazgo> hallazgos = const <Hallazgo>[],
}) {
  final Partida partida = Partida(
    mercadoId: mercado.id,
    marca: 'Marca de prueba',
    periodo: 0,
    caja: mercado.cajaInicial,
    decisiones: politica(0),
    estadoMarca: EstadoMarca(
      awareness: <String, double>{
        for (final Segmento s in mercado.segmentos) s.id: 0.04
      },
    ),
    estadoMercado: EstadoMercado(),
    competidores: mercado.clonarCompetidores(),
    historial: <ResultadoPeriodo>[],
    decisionesTomadas: <Decisiones>[],
    hallazgos: List<Hallazgo>.from(hallazgos),
    eventosVistos: <String>[],
  );
  for (int p = 0; p < periodos; p++) {
    MotorSimulacion.aplicarEventos(
        mercado, partida.estadoMercado, partida.competidores, p);
    partida.decisiones = politica(p);
    final ResultadoPeriodo r = MotorSimulacion.simularPeriodo(
      mercado: mercado,
      estadoMercado: partida.estadoMercado,
      decisiones: partida.decisiones,
      estado: partida.estadoMarca,
      competidores: partida.competidores,
      periodo: p,
      cajaPrevia: partida.caja,
    );
    partida.historial.add(r);
    partida.decisionesTomadas.add(partida.decisiones);
    partida.caja = r.cajaFinal;
    partida.periodo = p + 1;
  }
  if (periodos >= mercado.periodos) partida.terminada = true;
  return partida;
}
