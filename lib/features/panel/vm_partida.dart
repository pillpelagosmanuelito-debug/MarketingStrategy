import 'package:flutter/foundation.dart';

import '../../data/catalogo_estudios.dart';
import '../../data/catalogo_mercados.dart';
import '../../data/repositorio_partida.dart';
import '../../domain/engine/analista.dart';
import '../../domain/engine/estimador.dart';
import '../../domain/engine/evaluador.dart';
import '../../domain/engine/investigacion.dart';
import '../../domain/engine/motor_simulacion.dart';
import '../../domain/models/beneficio.dart';
import '../../domain/models/canal.dart';
import '../../domain/models/decisiones.dart';
import '../../domain/models/estado_marca.dart';
import '../../domain/models/estudio.dart';
import '../../domain/models/evento.dart';
import '../../domain/models/medio.dart';
import '../../domain/models/mercado.dart';
import '../../domain/models/partida.dart';
import '../../domain/models/resultado_periodo.dart';
import '../../domain/models/segmento.dart';

/// ViewModel central de la partida.
///
/// Es el unico objeto que la interfaz conoce. Las vistas leen de aqui y
/// escriben decisiones aqui; ninguna pantalla toca el motor, el repositorio ni
/// el catalogo directamente. Esa frontera es lo que permitiria mover la
/// simulacion a un servidor sin reescribir la interfaz.
class VmPartida extends ChangeNotifier {
  VmPartida({RepositorioPartida? repositorio})
      : _repositorio = repositorio ?? RepositorioPartida();

  final RepositorioPartida _repositorio;

  Partida? _partida;
  Mercado? _mercado;
  bool _cargando = true;
  List<Evento> _eventosDelPeriodo = <Evento>[];

  bool get cargando => _cargando;
  Partida? get partida => _partida;
  Mercado? get mercado => _mercado;
  bool get hayPartida => _partida != null && _mercado != null;
  List<Evento> get eventosDelPeriodo => _eventosDelPeriodo;

  Decisiones get decisiones => _partida!.decisiones;
  int get periodo => _partida!.periodo;
  int get totalPeriodos => _mercado!.periodos;
  double get caja => _partida!.caja;
  ResultadoPeriodo? get ultimoResultado => _partida!.ultimoResultado;

  Segmento? get segmentoObjetivo =>
      _mercado?.segmentoPorId(_partida?.decisiones.segmentoObjetivo ?? '');

  // ------------------------------------------------------------ ciclo de vida

  Future<void> iniciar() async {
    _cargando = true;
    notifyListeners();
    final Partida? guardada = await _repositorio.cargar();
    if (guardada != null) {
      _partida = guardada;
      _mercado = CatalogoMercados.porId(guardada.mercadoId);
      _eventosDelPeriodo = _mercado?.eventosDe(guardada.periodo) ?? <Evento>[];
    }
    _cargando = false;
    notifyListeners();
  }

  Future<void> nuevaPartida(Mercado mercado, String marca) async {
    final Partida nueva = Partida(
      mercadoId: mercado.id,
      marca: marca.trim().isEmpty ? 'Mi marca' : marca.trim(),
      periodo: 0,
      caja: mercado.cajaInicial,
      decisiones: decisionesIniciales(mercado),
      estadoMarca: EstadoMarca(
        awareness: <String, double>{
          for (final Segmento s in mercado.segmentos) s.id: 0.04
        },
      ),
      estadoMercado: EstadoMercado(),
      competidores: mercado.clonarCompetidores(),
      historial: <ResultadoPeriodo>[],
      decisionesTomadas: <Decisiones>[],
      hallazgos: <Hallazgo>[],
      eventosVistos: <String>[],
    );
    _partida = nueva;
    _mercado = mercado;
    _prepararPeriodo();
    await _guardar();
    notifyListeners();
  }

  /// Decisiones de arranque. El precio sugerido sale del costo propio, que la
  /// empresa si conoce, y no de ningun dato oculto del mercado.
  static Decisiones decisionesIniciales(Mercado mercado) {
    return Decisiones(
      segmentoObjetivo: mercado.segmentos.first.id,
      beneficioPrometido: Beneficio.precio,
      nivelPromesa: 3,
      calidad: 3,
      beneficioReal: Beneficio.precio,
      amplitud: 2,
      precio: double.parse((mercado.costoBase * 3.2).toStringAsFixed(2)),
      canales: <Canal>{Canal.propio},
      medios: <Medio, double>{for (final Medio m in Medio.values) m: 0.0},
    );
  }

  Future<void> abandonar() async {
    await _repositorio.borrar();
    _partida = null;
    _mercado = null;
    _eventosDelPeriodo = <Evento>[];
    notifyListeners();
  }

  Future<List<ResumenPartida>> historialPartidas() => _repositorio.historial();

  // ------------------------------------------------------------- decisiones

  void actualizar(Decisiones nuevas) {
    _partida!.decisiones = nuevas;
    _guardar();
    notifyListeners();
  }

  void fijarObjetivo(String segmentoId) =>
      actualizar(decisiones.copiarCon(segmentoObjetivo: segmentoId));

  void fijarPromesa(Beneficio beneficio, double nivel) =>
      actualizar(decisiones.copiarCon(
          beneficioPrometido: beneficio, nivelPromesa: nivel));

  void fijarProducto(double calidad, Beneficio real, int amplitud) =>
      actualizar(decisiones.copiarCon(
          calidad: calidad, beneficioReal: real, amplitud: amplitud));

  void fijarPrecio(double precio) =>
      actualizar(decisiones.copiarCon(precio: precio));

  void alternarCanal(Canal canal) {
    final Set<Canal> canales = Set<Canal>.from(decisiones.canales);
    if (!canales.remove(canal)) canales.add(canal);
    actualizar(decisiones.copiarCon(canales: canales));
  }

  void fijarMedio(Medio medio, double monto) {
    final Map<Medio, double> medios = Map<Medio, double>.from(decisiones.medios);
    medios[medio] = monto < 0 ? 0 : monto;
    actualizar(decisiones.copiarCon(medios: medios));
  }

  // ---------------------------------------------------------- investigacion

  /// Presupuesto disponible para gastar este periodo sin entrar en sobregiro.
  double get disponible =>
      caja - decisiones.gastoMedios - decisiones.costoFijoCanales -
      decisiones.investigacion;

  bool puedeContratar(Estudio estudio) =>
      disponible >= estudio.costo && periodo >= estudio.desdePeriodo;

  /// Contrata un estudio. El costo se suma al gasto del periodo en curso: se
  /// paga aunque el resultado no guste.
  Hallazgo contratar(Estudio estudio, String segmentoId) {
    final Hallazgo hallazgo = Investigacion.ejecutar(
      estudio: estudio,
      mercado: _mercado!,
      partida: _partida!,
      segmentoId: estudio.porSegmento ? segmentoId : '',
    );
    _partida!.hallazgos.add(hallazgo);
    _partida!.decisiones = decisiones.copiarCon(
        investigacion: decisiones.investigacion + estudio.costo);
    _guardar();
    notifyListeners();
    return hallazgo;
  }

  List<Hallazgo> hallazgosDe(String estudioId, String segmentoId) => _partida!
      .hallazgos
      .where((Hallazgo h) =>
          h.estudioId == estudioId && h.segmentoId == segmentoId)
      .toList();

  List<Estudio> get estudiosDisponibles => CatalogoEstudios.todos
      .where((Estudio e) => periodo >= e.desdePeriodo)
      .toList();

  // -------------------------------------------------------------- analista

  MercadoEstimado get mercadoEstimado =>
      MercadoEstimado.construir(_partida!, _mercado!);

  List<Consejo> get consejos =>
      AnalistaMarketing.analizar(_partida!, mercadoEstimado);

  Proyeccion get proyeccion =>
      AnalistaMarketing.proyectar(_partida!, mercadoEstimado);

  // ---------------------------------------------------------------- periodo

  void _prepararPeriodo() {
    final Partida p = _partida!;
    final Mercado m = _mercado!;
    _eventosDelPeriodo = MotorSimulacion.aplicarEventos(
        m, p.estadoMercado, p.competidores, p.periodo);
    for (final Evento e in _eventosDelPeriodo) {
      p.eventosVistos.add('${p.periodo}:${e.titulo}');
    }
  }

  /// Cierra el periodo: resuelve la simulacion, guarda el resultado y prepara
  /// el siguiente. Devuelve el resultado para que la vista lo muestre.
  Future<ResultadoPeriodo> cerrarPeriodo() async {
    final Partida p = _partida!;
    final Mercado m = _mercado!;
    final ResultadoPeriodo resultado = MotorSimulacion.simularPeriodo(
      mercado: m,
      estadoMercado: p.estadoMercado,
      decisiones: p.decisiones,
      estado: p.estadoMarca,
      competidores: p.competidores,
      periodo: p.periodo,
      cajaPrevia: p.caja,
      eventos: _eventosDelPeriodo.map((Evento e) => e.titulo).toList(),
    );
    p.historial.add(resultado);
    p.decisionesTomadas.add(p.decisiones);
    p.caja = resultado.cajaFinal;
    p.periodo = p.periodo + 1;
    // La investigacion ya se pago: no se arrastra al periodo siguiente.
    p.decisiones = p.decisiones.copiarCon(investigacion: 0.0);

    if (p.caja < -m.limiteSobregiro) {
      p.quiebra = true;
      p.terminada = true;
    } else if (p.periodo >= m.periodos) {
      p.terminada = true;
    } else {
      _prepararPeriodo();
    }

    if (p.terminada) {
      final Evaluacion evaluacion = Evaluador.evaluar(p, m);
      await _repositorio.registrar(ResumenPartida(
        mercadoId: m.id,
        mercadoNombre: m.nombre,
        marca: p.marca,
        fecha: DateTime.now(),
        utilidad: p.utilidadAcumulada,
        puntaje: evaluacion.puntajeGlobal,
        quiebra: p.quiebra,
      ));
    }
    await _guardar();
    notifyListeners();
    return resultado;
  }

  Evaluacion get evaluacion => Evaluador.evaluar(_partida!, _mercado!);

  // ----------------------------------------------------------------- apoyo

  /// Costo unitario del producto con las decisiones actuales.
  double get costoUnitario => MotorSimulacion.costoUnitario(
      _mercado!, _partida!.estadoMercado, decisiones, _partida!.estadoMarca.acumulado);

  /// Margen promedio que retienen los canales elegidos, visto desde el
  /// segmento objetivo.
  double get margenCanalObjetivo {
    final Segmento? s = segmentoObjetivo;
    if (s == null) return 0.0;
    return MotorSimulacion.margenCanal(s, decisiones.canales);
  }

  double get contribucionUnitaria =>
      decisiones.precio * (1.0 - margenCanalObjetivo) - costoUnitario;

  double get puntoEquilibrio => MotorSimulacion.puntoEquilibrio(
        _mercado!,
        _partida!.estadoMercado,
        decisiones,
        _partida!.estadoMarca.acumulado,
        margenCanalObjetivo,
      );

  double get gastoComprometido =>
      decisiones.gastoMedios + decisiones.costoFijoCanales + decisiones.investigacion;

  Future<void> _guardar() => _repositorio.guardar(_partida!);
}
