import 'dart:math' as math;

import '../models/canal.dart';
import '../models/competidor.dart';
import '../models/decisiones.dart';
import '../models/estado_marca.dart';
import '../models/evento.dart';
import '../models/medio.dart';
import '../models/mercado.dart';
import '../models/resultado_periodo.dart';
import '../models/segmento.dart';
import 'parametros.dart';

/// Motor de simulacion comercial.
///
/// Es una funcion pura: no conoce Flutter, no guarda estado global y no hace
/// entrada/salida. Se le entrega el mercado, las decisiones y la memoria de
/// las marcas, y devuelve el resultado del periodo. Esa pureza es lo que
/// permite correrlo miles de veces en las pruebas de calibracion y lo que
/// permitira, en una version futura, moverlo a un servidor sin tocar la
/// interfaz.
class MotorSimulacion {
  const MotorSimulacion._();

  // ------------------------------------------------------------- eventos

  /// Aplica los eventos del periodo sobre el estado del mercado y sobre las
  /// decisiones de los competidores. Devuelve los eventos aplicados para que
  /// la interfaz los muestre antes de que el estudiante decida.
  static List<Evento> aplicarEventos(
    Mercado mercado,
    EstadoMercado estadoMercado,
    List<Competidor> competidores,
    int periodo,
  ) {
    final List<Evento> activos = mercado.eventosDe(periodo);
    for (final Evento e in activos) {
      if (e.factorCosto != 1.0) {
        estadoMercado.factorCosto = estadoMercado.factorCosto * e.factorCosto;
      }
      if (e.segmento.isNotEmpty) {
        final double previo = estadoMercado.factorTamano[e.segmento] ?? 1.0;
        estadoMercado.factorTamano[e.segmento] = previo * e.factorTamano;
      }
      if (e.competidor.isNotEmpty) {
        for (final Competidor c in competidores) {
          if (c.id != e.competidor) continue;
          final Map<Medio, double> medios = <Medio, double>{};
          c.decisiones.medios.forEach((Medio m, double v) {
            medios[m] = v * e.cambioMedios;
          });
          c.decisiones = c.decisiones.copiarCon(
            precio: c.decisiones.precio * e.cambioPrecio,
            calidad: math.min(5.0, c.decisiones.calidad + e.cambioCalidad),
            medios: medios,
          );
        }
      }
    }
    return activos;
  }

  // ------------------------------------------------------------- costos

  /// Costo de producir una unidad. Sube con la calidad y con la amplitud de
  /// linea, y baja con el volumen acumulado (curva de experiencia), nunca por
  /// debajo del piso.
  static double costoUnitario(
    Mercado mercado,
    EstadoMercado estadoMercado,
    Decisiones d,
    double acumulado,
  ) {
    double base = estadoMercado.costoBase(mercado) *
        (Parametros.costoBaseCalidad + Parametros.costoPorCalidad * d.calidad);
    base = base * (1.0 + Parametros.costoPorAmplitud * (d.amplitud - 1));
    double factor = 1.0;
    if (acumulado > Parametros.volumenInicialExperiencia) {
      final double pasos =
          math.log(acumulado / Parametros.volumenInicialExperiencia) /
              math.log(2.0);
      factor = math.max(
        Parametros.pisoExperiencia,
        math.pow(Parametros.factorExperiencia, pasos).toDouble(),
      );
    }
    return base * factor;
  }

  // ---------------------------------------------------------- distribucion

  /// Probabilidad de que el segmento encuentre la marca disponible.
  ///
  /// Los canales se combinan como eventos independientes: dos canales que
  /// llegan al mismo segmento no suman, se solapan.
  static double cobertura(Segmento seg, Set<Canal> canales) {
    double libre = 1.0;
    for (final Canal c in canales) {
      libre = libre * (1.0 - seg.coberturaDe(c));
    }
    return math.min(Parametros.techoCobertura, 1.0 - libre);
  }

  /// Margen promedio que retienen los canales por los que este segmento compra.
  static double margenCanal(Segmento seg, Set<Canal> canales) {
    double peso = 0.0;
    double acumulado = 0.0;
    for (final Canal c in canales) {
      final double a = seg.coberturaDe(c);
      peso = peso + a;
      acumulado = acumulado + a * c.margen;
    }
    if (peso <= 0.0) return 0.0;
    return acumulado / peso;
  }

  // ------------------------------------------------------------- medios

  /// Nuevo nivel de recuerdo de marca en un segmento.
  static double actualizarAwareness(
    Segmento seg,
    double awareness,
    Map<Medio, double> medios,
    double satisfaccionPrevia,
  ) {
    double efectiva = 0.0;
    medios.forEach((Medio m, double monto) {
      if (monto <= 0.0) return;
      final double penalizacion = monto >= m.minimo
          ? 1.0
          : 0.45 + 0.55 * (monto / m.minimo);
      efectiva = efectiva + monto * m.eficiencia * seg.afinidadDe(m) * penalizacion;
    });
    double ganancia = 0.0;
    if (efectiva > 0.0) {
      ganancia = (Parametros.techoAwareness - awareness) *
          (efectiva / (efectiva + Parametros.kSaturacionMedios));
    }
    double decaimiento = Parametros.decaimientoAwareness;
    if (satisfaccionPrevia < Parametros.umbralBocaABoca) {
      decaimiento = decaimiento +
          Parametros.castigoBocaABoca *
              (Parametros.umbralBocaABoca - satisfaccionPrevia);
    } else if (satisfaccionPrevia > Parametros.umbralBocaABocaAlto) {
      ganancia = ganancia +
          (Parametros.techoAwareness - awareness) *
              Parametros.premioBocaABoca *
              (satisfaccionPrevia - Parametros.umbralBocaABocaAlto);
    }
    decaimiento = math.min(Parametros.decaimientoMaximo, decaimiento);
    final double nuevo = awareness * (1.0 - decaimiento) + ganancia;
    return math.max(
      Parametros.pisoAwareness,
      math.min(Parametros.techoAwareness, nuevo),
    );
  }

  // ----------------------------------------------------------- atractivo

  /// Que tan atractiva resulta la marca para el segmento, antes del precio.
  ///
  /// Se construye con lo que el segmento **cree**: la promesa, no el producto.
  /// El producto entra despues, por la via de la satisfaccion.
  static double atractivo(Segmento seg, Decisiones d, EstadoMarca est) {
    final double fitPromesa =
        Parametros.similitud(d.beneficioPrometido, seg.beneficio);
    final double nivel = d.nivelPromesa / 5.0;
    double calidadCreida = nivel * (0.45 + 0.55 * est.claridad) +
        (d.calidad / 5.0) * (0.55 * est.claridad);
    calidadCreida = math.min(1.0, calidadCreida);
    double v = seg.pesoCalidad * calidadCreida +
        seg.pesoBeneficio * fitPromesa +
        seg.pesoMarca * (est.claridad * fitPromesa) +
        seg.pesoVariedad * (d.amplitud / 3.0);
    v = v * (1.0 + Parametros.pesoReputacion * (est.reputacion - 0.5));
    return math.max(0.01, v);
  }

  /// Utilidad de la marca para el segmento, ya con el precio dentro.
  static double utilidad(Segmento seg, Decisiones d, EstadoMarca est) {
    final double relativo = d.precio / seg.precioReferencia;
    double u = Parametros.lambdaLogit * atractivo(seg, d, est) -
        seg.sensibilidad * (relativo - 1.0);
    if (relativo < Parametros.umbralSospecha) {
      u = u -
          seg.sospechaPrecioBajo *
              (Parametros.umbralSospecha - relativo) *
              Parametros.pesoSospecha;
    }
    return u;
  }

  // -------------------------------------------------------- satisfaccion

  /// Satisfaccion del segmento: lo entregado contra lo prometido.
  ///
  /// Es el unico lugar donde entra el producto real. Un producto excelente
  /// vendido con una promesa desmedida deja al cliente insatisfecho; un
  /// producto modesto con una promesa modesta, no.
  static double satisfaccion(Segmento seg, Decisiones d) {
    final double fitReal = Parametros.similitud(d.beneficioReal, seg.beneficio);
    final double fitPromesa =
        Parametros.similitud(d.beneficioPrometido, seg.beneficio);
    final double entregado =
        Parametros.pesoCalidadEntrega * (d.calidad / 5.0) +
            Parametros.pesoBeneficioEntrega * fitReal;
    double esperado = Parametros.pesoCalidadEntrega * (d.nivelPromesa / 5.0) +
        Parametros.pesoBeneficioEntrega * fitPromesa;
    esperado = esperado *
        (1.0 +
            Parametros.pesoPrecioExpectativa *
                (d.precio / seg.precioReferencia - 1.0));
    esperado = esperado * (0.94 + Parametros.pesoExigencia * (seg.exigencia - 3.0));
    final double s = Parametros.baseSatisfaccion +
        Parametros.pendienteSatisfaccion * (entregado - esperado);
    return math.max(
      Parametros.pisoSatisfaccion,
      math.min(Parametros.techoSatisfaccion, s),
    );
  }

  // ------------------------------------------------------------ periodo

  /// Resuelve un periodo completo. Muta [estado] y [competidores]: esa es la
  /// memoria del mercado que pasa al periodo siguiente.
  static ResultadoPeriodo simularPeriodo({
    required Mercado mercado,
    required EstadoMercado estadoMercado,
    required Decisiones decisiones,
    required EstadoMarca estado,
    required List<Competidor> competidores,
    required int periodo,
    required double cajaPrevia,
    List<String> eventos = const <String>[],
  }) {
    final List<_Marca> marcas = <_Marca>[
      _Marca('jugador', decisiones, estado),
      ...competidores.map((Competidor c) => _Marca(c.id, c.decisiones, c.estado)),
    ];

    for (final Segmento seg in mercado.segmentos) {
      for (final _Marca m in marcas) {
        m.estado.awareness[seg.id] = actualizarAwareness(
          seg,
          m.estado.awareness[seg.id] ?? 0.05,
          m.decisiones.medios,
          m.estado.satisfaccionPrevia,
        );
      }
    }

    final Map<String, double> ventas = <String, double>{
      for (final _Marca m in marcas) m.id: 0.0
    };
    double ingresos = 0.0;
    double satisfaccionPonderada = 0.0;
    final List<ResultadoSegmento> detalle = <ResultadoSegmento>[];

    for (final Segmento seg in mercado.segmentos) {
      final Map<String, double> pesos = <String, double>{};
      for (final _Marca m in marcas) {
        final double cob = cobertura(seg, m.decisiones.canales);
        final double aw = m.estado.awareness[seg.id] ?? 0.0;
        if (cob <= 0.0 || aw <= 0.0) {
          pesos[m.id] = 0.0;
          continue;
        }
        pesos[m.id] = cob * aw * math.exp(utilidad(seg, m.decisiones, m.estado));
      }
      double total = math.exp(Parametros.utilidadNoCompra);
      pesos.forEach((String _, double v) => total = total + v);

      final Map<String, double> participaciones = <String, double>{};
      final double inercia = Parametros.inerciaBase * seg.lealtad;
      for (final _Marca m in marcas) {
        double share = pesos[m.id]! / total;
        final double? previa = m.estado.participacionPrevia[seg.id];
        if (previa != null) {
          share = (1.0 - inercia) * share + inercia * previa;
        }
        participaciones[m.id] = share;
      }
      for (final _Marca m in marcas) {
        m.estado.participacionPrevia[seg.id] = participaciones[m.id]!;
      }

      final double tamano = estadoMercado.tamano(seg);
      for (final _Marca m in marcas) {
        final double unidades = tamano * participaciones[m.id]!;
        ventas[m.id] = (ventas[m.id] ?? 0.0) + unidades;
        if (m.id != 'jugador') continue;
        final double margen = margenCanal(seg, m.decisiones.canales);
        final double ingreso = unidades * m.decisiones.precio * (1.0 - margen);
        ingresos = ingresos + ingreso;
        final double sat = satisfaccion(seg, m.decisiones);
        satisfaccionPonderada = satisfaccionPonderada + sat * unidades;
        detalle.add(ResultadoSegmento(
          segmentoId: seg.id,
          unidades: unidades,
          participacion: participaciones[m.id]!,
          satisfaccion: sat,
          awareness: m.estado.awareness[seg.id] ?? 0.0,
          cobertura: cobertura(seg, m.decisiones.canales),
          ingreso: ingreso,
        ));
      }
    }

    final double unidades = ventas['jugador'] ?? 0.0;
    final double satisfaccionGlobal =
        unidades > 0 ? satisfaccionPonderada / unidades : 0.5;

    final double cu =
        costoUnitario(mercado, estadoMercado, decisiones, estado.acumulado);
    final double costoVariable = unidades * cu;
    final double costoCanales = decisiones.costoFijoCanales;
    final double gastoMedios = decisiones.gastoMedios;
    final double costos = costoVariable +
        mercado.costoFijo +
        costoCanales +
        gastoMedios +
        decisiones.investigacion;
    final double utilidadBruta = ingresos - costos;
    final double impuesto =
        utilidadBruta > 0 ? utilidadBruta * Parametros.tasaImpuesto : 0.0;
    final double utilidadNeta = utilidadBruta - impuesto;

    final double velocidad = satisfaccionGlobal < estado.reputacion
        ? Parametros.caidaReputacion
        : Parametros.subidaReputacion;
    estado.reputacion = math.max(
      Parametros.pisoReputacion,
      math.min(
        Parametros.techoReputacion,
        estado.reputacion * (1.0 - velocidad) + velocidad * satisfaccionGlobal,
      ),
    );
    estado.satisfaccionPrevia = satisfaccionGlobal;

    final String firma = decisiones.firmaPosicionamiento;
    if (estado.posicionPrevia.isNotEmpty && estado.posicionPrevia != firma) {
      estado.claridad = estado.claridad * Parametros.castigoCambioPosicion;
    } else {
      final double inversionRelativa =
          math.min(1.0, gastoMedios / Parametros.inversionClaridadPlena);
      estado.claridad = math.min(
        Parametros.techoClaridad,
        estado.claridad +
            (Parametros.techoClaridad - estado.claridad) *
                Parametros.recuperacionClaridad *
                inversionRelativa,
      );
    }
    estado.posicionPrevia = firma;
    estado.acumulado = estado.acumulado + unidades;

    double totalMercado = 0.0;
    ventas.forEach((String _, double v) => totalMercado = totalMercado + v);
    final double participacion =
        totalMercado > 0 ? unidades / totalMercado : 0.0;

    for (final Competidor c in competidores) {
      _reaccionar(c, participacion, decisiones.precio, mercado, estadoMercado);
      c.estado.acumulado = c.estado.acumulado + (ventas[c.id] ?? 0.0);
      c.estado.reputacion = math.max(
        Parametros.pisoReputacion,
        math.min(
            Parametros.techoReputacion, c.estado.reputacion * 0.9 + 0.1 * 0.55),
      );
      c.estado.claridad = math.min(0.90, c.estado.claridad + 0.05);
    }

    return ResultadoPeriodo(
      periodo: periodo,
      unidades: unidades,
      ingresos: ingresos,
      costoUnitario: cu,
      costoVariable: costoVariable,
      costoFijo: mercado.costoFijo,
      costoCanales: costoCanales,
      gastoMedios: gastoMedios,
      gastoInvestigacion: decisiones.investigacion,
      impuesto: impuesto,
      utilidad: utilidadNeta,
      satisfaccion: satisfaccionGlobal,
      participacion: participacion,
      reputacion: estado.reputacion,
      claridad: estado.claridad,
      cajaFinal: cajaPrevia + utilidadNeta,
      segmentos: detalle,
      ventasCompetidores: ventas,
      eventos: eventos,
    );
  }

  static void _reaccionar(
    Competidor c,
    double participacionJugador,
    double precioJugador,
    Mercado mercado,
    EstadoMercado estadoMercado,
  ) {
    final Decisiones d = c.decisiones;
    switch (c.politica) {
      case PoliticaCompetidor.liderMasivo:
        if (participacionJugador > 0.22) {
          final Map<Medio, double> medios = <Medio, double>{};
          d.medios.forEach((Medio m, double v) => medios[m] = v * 1.06);
          c.decisiones = d.copiarCon(
            precio: math.max(
                estadoMercado.costoBase(mercado) * 1.35, d.precio * 0.96),
            medios: medios,
          );
        }
        break;
      case PoliticaCompetidor.premium:
        if (participacionJugador > 0.18) {
          final Map<Medio, double> medios = Map<Medio, double>.from(d.medios);
          medios[Medio.digital] = (medios[Medio.digital] ?? 0.0) * 1.08 + 2000.0;
          c.decisiones = d.copiarCon(
            calidad: math.min(5.0, d.calidad + 0.15),
            medios: medios,
          );
        }
        break;
      case PoliticaCompetidor.retador:
        if (precioJugador < d.precio) {
          c.decisiones = d.copiarCon(
            precio: math.max(
                estadoMercado.costoBase(mercado) * 1.25, d.precio * 0.97),
          );
        } else {
          c.decisiones = d.copiarCon(precio: d.precio * 1.01);
        }
        break;
    }
  }

  /// Punto de equilibrio en unidades para las decisiones dadas.
  static double puntoEquilibrio(
    Mercado mercado,
    EstadoMercado estadoMercado,
    Decisiones d,
    double acumulado,
    double margenCanalPromedio,
  ) {
    final double ingresoUnitario = d.precio * (1.0 - margenCanalPromedio);
    final double cu = costoUnitario(mercado, estadoMercado, d, acumulado);
    final double contribucion = ingresoUnitario - cu;
    if (contribucion <= 0.0) return double.infinity;
    final double fijos = mercado.costoFijo +
        d.costoFijoCanales +
        d.gastoMedios +
        d.investigacion;
    return fijos / contribucion;
  }
}

class _Marca {
  _Marca(this.id, this.decisiones, this.estado);

  final String id;
  final Decisiones decisiones;
  final EstadoMarca estado;
}
