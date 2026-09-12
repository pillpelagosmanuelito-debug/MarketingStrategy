import 'dart:math' as math;

import '../models/canal.dart';
import '../models/decisiones.dart';
import '../models/estudio.dart';
import '../models/medio.dart';
import '../models/mercado.dart';
import '../models/partida.dart';
import '../models/resultado_periodo.dart';
import '../models/segmento.dart';
import 'estimador.dart';
import 'motor_simulacion.dart';

enum Severidad { critica, advertencia, observacion, confirmacion }

enum AreaConsejo {
  investigacion,
  segmentacion,
  posicionamiento,
  producto,
  precio,
  campanas,
  finanzas,
  proyeccion,
}

/// Una observación del analista. Siempre lleva tres cosas: qué ve, por qué lo
/// dice y con qué evidencia. Un consejo sin fundamento no se muestra.
class Consejo {
  const Consejo({
    required this.regla,
    required this.area,
    required this.severidad,
    required this.titulo,
    required this.mensaje,
    required this.fundamento,
    required this.evidencia,
  });

  /// Identificador de la regla que lo generó, para poder auditarlo.
  final String regla;
  final AreaConsejo area;
  final Severidad severidad;
  final String titulo;
  final String mensaje;

  /// Por qué esto importa desde el punto de vista de marketing.
  final String fundamento;

  /// De dónde salió el dato: qué estudio o qué resultado.
  final String evidencia;
}

/// Resultado de la proyección del analista sobre el mercado estimado.
class Proyeccion {
  const Proyeccion({
    required this.resultado,
    required this.supuestos,
    required this.confiable,
  });

  final ResultadoPeriodo resultado;
  final List<String> supuestos;

  /// Falso cuando la proyección descansa sobre demasiados supuestos.
  final bool confiable;
}

/// Analista de marketing: un sistema experto de reglas.
///
/// Regla de honestidad del simulador, y la razón por la que no es un modelo
/// generativo: **el analista solo puede leer lo que el estudiante ya sabe.**
/// Recibe la partida y un [MercadoEstimado] construido con los estudios
/// comprados; nunca recibe el mercado real. No puede, ni por error ni por
/// descuido, filtrar un parámetro oculto, porque no lo tiene en la mano.
///
/// Esa restricción está verificada en `test/analista_test.dart`: si alguien
/// cambia la firma para pasarle el mercado real, la prueba falla.
class AnalistaMarketing {
  const AnalistaMarketing._();

  /// Proyecta el periodo con los datos que el estudiante conoce.
  ///
  /// No es una predicción del resultado real: es la respuesta a la pregunta
  /// "¿qué pasaría si mis estimaciones fueran correctas?".
  static Proyeccion proyectar(Partida partida, MercadoEstimado estimado) {
    final Mercado mercado = estimado.mercado;
    final EstadoMercado estadoMercado = partida.estadoMercado.copia();
    final ResultadoPeriodo resultado = MotorSimulacion.simularPeriodo(
      mercado: mercado,
      estadoMercado: estadoMercado,
      decisiones: partida.decisiones,
      estado: partida.estadoMarca.copia(),
      competidores: mercado.clonarCompetidores(),
      periodo: partida.periodo,
      cajaPrevia: partida.caja,
    );
    return Proyeccion(
      resultado: resultado,
      supuestos: estimado.supuestos,
      confiable: estimado.supuestos.length <= 2,
    );
  }

  /// Analiza las decisiones del periodo en curso.
  static List<Consejo> analizar(Partida partida, MercadoEstimado estimado) {
    final List<Consejo> consejos = <Consejo>[];
    final Decisiones d = partida.decisiones;
    final Mercado est = estimado.mercado;
    final Segmento? objetivo = est.segmentoPorId(d.segmentoObjetivo);
    final ResultadoPeriodo? ultimo = partida.ultimoResultado;
    final Proyeccion proyeccion = proyectar(partida, estimado);

    void agregar(String regla, AreaConsejo area, Severidad sev, String titulo,
        String mensaje, String fundamento, String evidencia) {
      consejos.add(Consejo(
        regla: regla,
        area: area,
        severidad: sev,
        titulo: titulo,
        mensaje: mensaje,
        fundamento: fundamento,
        evidencia: evidencia,
      ));
    }

    // ------------------------------------------------- investigación (R01-R08)

    if (objetivo != null && !estimado.conoce('perfil:${objetivo.id}')) {
      agregar(
        'R01',
        AreaConsejo.investigacion,
        Severidad.critica,
        'Estás decidiendo a ciegas sobre tu objetivo',
        'Elegiste ${objetivo.nombre} como segmento objetivo, pero no has '
            'contratado el perfil de ese segmento. No sabes qué beneficio '
            'busca ni qué atributo pesa en su decisión.',
        'Toda la mezcla comercial se deduce del perfil del objetivo. Sin él, '
            'el producto, el precio y la campaña son suposiciones tuyas, no '
            'decisiones.',
        'No hay hallazgos del estudio "Perfil del segmento" para este segmento.',
      );
    }

    if (objetivo != null && !estimado.conoce('precio:${objetivo.id}')) {
      agregar(
        'R02',
        AreaConsejo.investigacion,
        Severidad.advertencia,
        'Precio fijado sin prueba de precio',
        'Pusiste S/ ${d.precio.toStringAsFixed(2)} sin saber cuál es el precio '
            'de referencia de tu objetivo.',
        'El precio no se juzga en soles absolutos sino contra lo que el '
            'segmento considera normal. El mismo precio puede ser caro para un '
            'segmento y barato para otro.',
        'No hay hallazgos del estudio "Prueba de precio" para este segmento.',
      );
    }

    if (objetivo != null &&
        d.canales.length >= 3 &&
        !estimado.conoce('canales:${objetivo.id}')) {
      agregar(
        'R03',
        AreaConsejo.investigacion,
        Severidad.advertencia,
        'Pagas ${d.canales.length} canales sin saber dónde compra tu objetivo',
        'Los canales activos cuestan S/ '
            '${d.costoFijoCanales.toStringAsFixed(0)} por periodo, estén o no '
            'en la ruta de compra de tu segmento.',
        'La cobertura no suma: dos canales que llegan al mismo público se '
            'solapan y solo duplican el costo fijo.',
        'No hay hallazgos del estudio "Auditoría de canales" para este segmento.',
      );
    }

    if (objetivo != null &&
        d.gastoMedios > 0 &&
        !estimado.conoce('medios:${objetivo.id}')) {
      agregar(
        'R04',
        AreaConsejo.investigacion,
        Severidad.advertencia,
        'Inviertes en medios sin conocer los hábitos del objetivo',
        'S/ ${d.gastoMedios.toStringAsFixed(0)} repartidos entre medios cuya '
            'afinidad con tu objetivo desconoces.',
        'Un medio con afinidad baja no produce recuerdo de marca: el dinero se '
            'gasta igual, pero el segmento no ve la campaña.',
        'No hay hallazgos del estudio "Hábitos de medios" para este segmento.',
      );
    }

    if (!estimado.conoce('tamano')) {
      agregar(
        'R05',
        AreaConsejo.investigacion,
        Severidad.observacion,
        'No sabes cuánta gente hay en cada segmento',
        'Sin el estudio de tamaño de mercado, no puedes saber si tu objetivo '
            'alcanza para cubrir S/ ${est.costoFijo.toStringAsFixed(0)} de '
            'costo fijo por periodo.',
        'Un segmento puede tener el perfil perfecto y aun así ser demasiado '
            'chico para sostener la estructura de costos.',
        'No hay hallazgos del estudio "Tamaño de mercado".',
      );
    }

    final double gastoTotal =
        d.gastoMedios + d.costoFijoCanales + d.investigacion;
    if (gastoTotal > 0 && d.investigacion / gastoTotal > 0.25) {
      agregar(
        'R06',
        AreaConsejo.investigacion,
        Severidad.advertencia,
        'Estás investigando más de lo que ejecutas',
        'La investigación se lleva '
            '${(d.investigacion / gastoTotal * 100).round()}% del gasto '
            'comercial del periodo.',
        'La investigación no vende: evita errores de puntería. Pasado cierto '
            'punto, un dato más preciso no cambia ninguna decisión y el dinero '
            'rinde más en ejecución.',
        'Gasto del periodo: investigación S/ ${d.investigacion.toStringAsFixed(0)} '
            'contra medios y canales S/ '
            '${(d.gastoMedios + d.costoFijoCanales).toStringAsFixed(0)}.',
      );
    }

    final int repetidos = _estudiosMuyRepetidos(partida);
    if (repetidos > 0) {
      agregar(
        'R07',
        AreaConsejo.investigacion,
        Severidad.observacion,
        'Estás repitiendo estudios más de dos veces',
        'Hay $repetidos estudio(s) contratado(s) tres veces o más. Cada '
            'repetición reduce el error a la mitad, pero cuesta lo mismo.',
        'La precisión tiene rendimientos decrecientes: pasar de ±16% a ±8% '
            'suele cambiar una decisión; pasar de ±4% a ±2%, casi nunca.',
        'Historial de estudios contratados en esta partida.',
      );
    }

    if (partida.periodo >= 2 && !estimado.conoce('mystery')) {
      agregar(
        'R08',
        AreaConsejo.investigacion,
        Severidad.observacion,
        'No sabes a qué precio vende tu competencia',
        'Llevas ${partida.periodo} periodos compitiendo sin haber levantado '
            'información de las marcas rivales.',
        'Tu precio se compara con el del competidor más parecido, no con tu '
            'hoja de costos.',
        'No hay hallazgos del estudio "Mystery shopper".',
      );
    }

    // ------------------------------------------------ segmentación (R09-R12)

    if (ultimo != null && ultimo.segmentos.isNotEmpty) {
      ResultadoSegmento mayor = ultimo.segmentos.first;
      for (final ResultadoSegmento s in ultimo.segmentos) {
        if (s.unidades > mayor.unidades) mayor = s;
      }
      if (mayor.segmentoId != d.segmentoObjetivo) {
        final Segmento? real = est.segmentoPorId(mayor.segmentoId);
        agregar(
          'R09',
          AreaConsejo.segmentacion,
          Severidad.advertencia,
          'Tu objetivo declarado no es tu cliente real',
          'Dices dirigirte a ${objetivo?.nombre ?? d.segmentoObjetivo}, pero el '
              'periodo pasado la mayoría de tus ventas vino de '
              '${real?.nombre ?? mayor.segmentoId}.',
          'O el objetivo está mal elegido, o la mezcla no le está hablando. '
              'Las dos cosas se corrigen, pero son correcciones distintas.',
          'Resultado del periodo ${ultimo.periodo + 1}, ventas por segmento.',
        );
      }

      final ResultadoSegmento? enObjetivo = ultimo.segmento(d.segmentoObjetivo);
      final double concentracion =
          ultimo.unidades > 0 && enObjetivo != null
              ? enObjetivo.unidades / ultimo.unidades
              : 0.0;
      if (ultimo.unidades > 0 && concentracion < 0.40) {
        agregar(
          'R10',
          AreaConsejo.segmentacion,
          Severidad.observacion,
          'Tus ventas están dispersas',
          'Solo ${(concentracion * 100).round()}% de tus unidades salieron del '
              'segmento objetivo.',
          'Vender disperso no es malo en sí, pero significa que estás pagando '
              'una campaña enfocada para un resultado que no lo es. O enfocas '
              'la mezcla, o reconoces que tu objetivo es otro.',
          'Resultado del periodo ${ultimo.periodo + 1}.',
        );
      }
    }

    if (objetivo != null && estimado.conoce('tamano')) {
      final double ingresoPotencial = objetivo.tamano * d.precio * 0.35;
      final double estructura =
          est.costoFijo + d.costoFijoCanales + d.gastoMedios;
      if (ingresoPotencial < estructura) {
        agregar(
          'R11',
          AreaConsejo.segmentacion,
          Severidad.critica,
          'El segmento no alcanza para tu estructura',
          'Aun quedándote con un tercio de ${objetivo.nombre} a tu precio '
              'actual, el ingreso no cubriría los S/ '
              '${estructura.toStringAsFixed(0)} de costo fijo, canales y '
              'medios de este periodo.',
          'Un segmento pequeño solo funciona con una estructura pequeña. Si no '
              'puedes bajar los costos fijos, el objetivo tiene que ser más '
              'grande o el precio más alto.',
          'Estudio de tamaño de mercado y decisiones del periodo.',
        );
      }
    }

    if (partida.estadoMarca.posicionPrevia.isNotEmpty &&
        partida.estadoMarca.posicionPrevia != d.firmaPosicionamiento) {
      agregar(
        'R12',
        AreaConsejo.posicionamiento,
        Severidad.advertencia,
        'Estás cambiando de posicionamiento',
        'Cambiar de objetivo, de beneficio prometido o de nivel de promesa '
            'reduce a poco más de la mitad la claridad de marca que habías '
            'construido.',
        'La claridad se acumula por repetición. El mercado tarda varios '
            'periodos en entender quién eres y lo olvida en uno.',
        'Posicionamiento anterior: ${partida.estadoMarca.posicionPrevia}.',
      );
    }

    // ------------------------------ producto y posicionamiento (R13-R18)

    final double brechaPromesa = d.nivelPromesa - d.calidad;
    if (brechaPromesa >= 1.0) {
      agregar(
        'R13',
        AreaConsejo.posicionamiento,
        Severidad.critica,
        'Prometes más de lo que entregas',
        'Tu promesa es nivel ${d.nivelPromesa.toStringAsFixed(1)} y tu producto '
            'es calidad ${d.calidad.toStringAsFixed(1)}. La diferencia la paga '
            'el cliente cuando abre el producto.',
        'La satisfacción es entrega menos expectativa. Una promesa alta sube '
            'la expectativa y, con el mismo producto, baja la satisfacción. '
            'Insatisfacción sostenida destruye reputación y acelera el olvido '
            'de marca.',
        'Decisiones del periodo: nivel de promesa contra calidad.',
      );
    } else if (brechaPromesa <= -1.2) {
      agregar(
        'R14',
        AreaConsejo.producto,
        Severidad.observacion,
        'Entregas más de lo que comunicas',
        'Tu producto es calidad ${d.calidad.toStringAsFixed(1)} pero lo '
            'presentas como nivel ${d.nivelPromesa.toStringAsFixed(1)}.',
        'La calidad que el cliente no percibe la pagas en costo unitario y no '
            'la cobras en precio ni en atractivo. O la comunicas, o la bajas.',
        'Decisiones del periodo: calidad contra nivel de promesa.',
      );
    }

    if (d.beneficioReal != d.beneficioPrometido) {
      agregar(
        'R15',
        AreaConsejo.posicionamiento,
        Severidad.critica,
        'Tu producto no entrega lo que tu campaña promete',
        'Prometes ${d.beneficioPrometido.etiqueta.toLowerCase()} y el producto '
            'está construido para ${d.beneficioReal.etiqueta.toLowerCase()}.',
        'La promesa atrae y el producto retiene. Si no coinciden, cada sol de '
            'publicidad compra un cliente que se va decepcionado y lo cuenta.',
        'Decisiones del periodo: beneficio prometido contra beneficio real.',
      );
    }

    if (objetivo != null && estimado.conoce('perfil:${objetivo.id}')) {
      if (objetivo.beneficio != d.beneficioPrometido) {
        agregar(
          'R16',
          AreaConsejo.posicionamiento,
          Severidad.critica,
          'Le prometes a tu objetivo algo que no está buscando',
          '${objetivo.nombre} busca '
              '${objetivo.beneficio.etiqueta.toLowerCase()} y tú comunicas '
              '${d.beneficioPrometido.etiqueta.toLowerCase()}.',
          'El posicionamiento es la intersección entre lo que el segmento '
              'busca y lo que tú puedes ofrecer. Fuera de esa intersección, la '
              'inversión publicitaria trabaja en contra.',
          'Perfil del segmento (error de muestreo ±'
              '${((partida.mejorHallazgo('perfil', objetivo.id)?.error ?? 0) * 100).round()}%).',
        );
      } else if (d.beneficioReal == d.beneficioPrometido &&
          brechaPromesa.abs() < 1.0) {
        agregar(
          'R30',
          AreaConsejo.posicionamiento,
          Severidad.confirmacion,
          'Promesa, producto y objetivo están alineados',
          'Le prometes a ${objetivo.nombre} exactamente lo que busca y el '
              'producto lo respalda.',
          'Esta coherencia es la que construye reputación y claridad periodo '
              'tras periodo. Sostenerla vale más que cualquier campaña grande.',
          'Perfil del segmento y decisiones del periodo.',
        );
      }
    }

    if (ultimo != null && ultimo.satisfaccion < 0.45) {
      agregar(
        'R17',
        AreaConsejo.posicionamiento,
        Severidad.critica,
        'Tus clientes quedaron insatisfechos',
        'La satisfacción del periodo pasado fue '
            '${(ultimo.satisfaccion * 100).round()}%.',
        'Por debajo de 45% el boca a boca se vuelve negativo: la marca se '
            'olvida más rápido de lo que la publicidad la instala. Es el único '
            'efecto del simulador que puede hacer que gastar más en medios '
            'empeore el resultado.',
        'Resultado del periodo ${ultimo.periodo + 1}.',
      );
    }

    if (partida.periodo >= 3 && partida.estadoMarca.claridad < 0.40) {
      agregar(
        'R18',
        AreaConsejo.posicionamiento,
        Severidad.advertencia,
        'Tu marca no es reconocible',
        'La claridad de posicionamiento está en '
            '${(partida.estadoMarca.claridad * 100).round()}% después de '
            '${partida.periodo} periodos.',
        'La claridad multiplica el peso de la marca en la decisión de compra. '
            'Sin ella, compites solo por precio y disponibilidad.',
        'Estado de marca de la partida.',
      );
    }

    // --------------------------------------------------------- precio (R19-R22)

    final double margenCanalPromedio = objetivo != null
        ? MotorSimulacion.margenCanal(objetivo, d.canales)
        : 0.20;
    final double costoUnitario = MotorSimulacion.costoUnitario(
        est, partida.estadoMercado, d, partida.estadoMarca.acumulado);
    final double ingresoUnitario = d.precio * (1.0 - margenCanalPromedio);

    if (ingresoUnitario <= costoUnitario) {
      agregar(
        'R19',
        AreaConsejo.precio,
        Severidad.critica,
        'Vendes por debajo del costo',
        'De cada ${est.unidad} recibes S/ '
            '${ingresoUnitario.toStringAsFixed(2)} después del margen del '
            'canal, y producirla cuesta S/ '
            '${costoUnitario.toStringAsFixed(2)}.',
        'Con contribución negativa, cada unidad vendida aumenta la pérdida. '
            'No hay volumen que lo arregle.',
        'Costo unitario del motor y margen promedio de tus canales.',
      );
    }

    if (objetivo != null && estimado.conoce('precio:${objetivo.id}')) {
      final double relativo = d.precio / objetivo.precioReferencia;
      if (relativo > 1.25) {
        agregar(
          'R20',
          AreaConsejo.precio,
          Severidad.advertencia,
          'Tu precio está muy por encima de la referencia',
          'Cobras ${((relativo - 1) * 100).round()}% más que el precio de '
              'referencia estimado de tu objetivo (S/ '
              '${objetivo.precioReferencia.toStringAsFixed(2)}).',
          'Un precio por encima de la referencia solo se sostiene si la '
              'promesa y la marca justifican la diferencia. Si no, el segmento '
              'simplemente compra otra cosa.',
          'Prueba de precio (error ±'
              '${((partida.mejorHallazgo('precio', objetivo.id)?.error ?? 0) * 100).round()}%).',
        );
      } else if (relativo < 0.72 && objetivo.sospechaPrecioBajo > 1.2) {
        agregar(
          'R21',
          AreaConsejo.precio,
          Severidad.advertencia,
          'Tu precio es tan bajo que genera desconfianza',
          'Estás ${((1 - relativo) * 100).round()}% por debajo de la '
              'referencia en un segmento que asocia precio con calidad.',
          'En segmentos de alto valor el precio es parte del mensaje. Bajarlo '
              'demasiado no atrae: contradice la promesa.',
          'Prueba de precio: este segmento desconfía de los precios bajos.',
        );
      }
    }

    if (objetivo != null && estimado.conoce('tamano')) {
      final double equilibrio = MotorSimulacion.puntoEquilibrio(
        est,
        partida.estadoMercado,
        d,
        partida.estadoMarca.acumulado,
        margenCanalPromedio,
      );
      if (equilibrio.isFinite && equilibrio > objetivo.tamano) {
        agregar(
          'R22',
          AreaConsejo.finanzas,
          Severidad.critica,
          'Tu punto de equilibrio es mayor que tu segmento',
          'Necesitas vender ${equilibrio.round()} ${est.unidad}s para no '
              'perder, y tu objetivo completo tiene ${objetivo.tamano.round()} '
              'compradores potenciales.',
          'Ni quedándote con el 100% del segmento llegarías. Hay que subir '
              'precio, bajar costos fijos o ampliar el objetivo.',
          'Punto de equilibrio calculado con tus decisiones y el tamaño '
              'estimado del segmento.',
        );
      }
    }

    // ------------------------------------------------------ campañas (R23-R26)

    if (objetivo != null && estimado.conoce('medios:${objetivo.id}')) {
      for (final Medio m in Medio.values) {
        final double gasto = d.gastoEn(m);
        if (gasto <= 0) continue;
        if (objetivo.afinidadDe(m) < 0.15) {
          agregar(
            'R23',
            AreaConsejo.campanas,
            Severidad.advertencia,
            'S/ ${gasto.toStringAsFixed(0)} en un medio que tu objetivo no consume',
            '${m.etiqueta} tiene una afinidad estimada de '
                '${(objetivo.afinidadDe(m) * 100).round()}% con '
                '${objetivo.nombre}.',
            'El alcance efectivo es inversión por eficiencia del medio por '
                'afinidad del segmento. Con afinidad baja, el producto de esa '
                'multiplicación es casi cero.',
            'Estudio de hábitos de medios del segmento objetivo.',
          );
        }
      }
    }

    for (final Medio m in Medio.values) {
      final double gasto = d.gastoEn(m);
      if (gasto > 0 && gasto < m.minimo) {
        agregar(
          'R24',
          AreaConsejo.campanas,
          Severidad.observacion,
          '${m.etiqueta}: inversión por debajo del mínimo útil',
          'Estás invirtiendo S/ ${gasto.toStringAsFixed(0)} cuando este medio '
              'necesita al menos S/ ${m.minimo.toStringAsFixed(0)} para rendir '
              'a plena eficiencia.',
          'Por debajo del mínimo, la inversión pierde hasta 55% de su alcance: '
              'se paga el medio pero no se compra frecuencia suficiente para '
              'ser recordado.',
          'Parámetros del medio.',
        );
      }
    }

    if (objetivo != null && estimado.conoce('canales:${objetivo.id}')) {
      for (final Canal c in d.canales) {
        if (objetivo.coberturaDe(c) < 0.12) {
          agregar(
            'R25',
            AreaConsejo.campanas,
            Severidad.advertencia,
            '${c.etiqueta} no llega a tu objetivo',
            'Pagas S/ ${c.costoFijo.toStringAsFixed(0)} por periodo por un '
                'canal que alcanza al ${(objetivo.coberturaDe(c) * 100).round()}% '
                'de ${objetivo.nombre}.',
            'El costo del canal es fijo: se paga por estar, se venda o no. '
                'Un canal que no cubre al objetivo es costo puro.',
            'Auditoría de canales del segmento objetivo.',
          );
        }
      }
    }

    if (d.canales.isEmpty) {
      agregar(
        'R26',
        AreaConsejo.campanas,
        Severidad.critica,
        'No tienes dónde vender',
        'Sin ningún canal activo, la cobertura es cero y no habrá ventas.',
        'La disponibilidad multiplica a todo lo demás: un producto excelente '
            'que nadie encuentra vende cero.',
        'Decisiones del periodo.',
      );
    }
    if (d.gastoMedios <= 0 && partida.estadoMarca.claridad < 0.6) {
      agregar(
        'R27',
        AreaConsejo.campanas,
        Severidad.advertencia,
        'Campaña en cero con marca poco conocida',
        'Sin inversión en medios, el recuerdo de marca cae 15% por periodo y '
            'la claridad no avanza.',
        'El recuerdo de marca se deprecia como un activo: sostenerlo cuesta '
            'todos los periodos, no solo el del lanzamiento.',
        'Estado de marca de la partida.',
      );
    }

    // ------------------------------------------------------ finanzas (R28)

    if (ultimo != null && ultimo.ingresos > 0) {
      final double margen = ultimo.margenPorcentaje;
      if (margen < 0.15) {
        agregar(
          'R28',
          AreaConsejo.finanzas,
          Severidad.advertencia,
          'Margen bruto demasiado delgado',
          'El periodo pasado el margen bruto fue '
              '${(margen * 100).round()}% del ingreso neto de canal.',
          'Con márgenes así, el costo fijo se come el resultado: cualquier '
              'alza de insumos o caída de volumen pasa directo a pérdida.',
          'Resultado del periodo ${ultimo.periodo + 1}.',
        );
      }
    }

    // ---------------------------------------------------- proyección (R29)

    final double cajaProyectada = proyeccion.resultado.cajaFinal;
    if (cajaProyectada < 0) {
      agregar(
        'R29',
        AreaConsejo.finanzas,
        Severidad.critica,
        'La proyección te deja en números rojos',
        'Con tus estimaciones actuales, el periodo cerraría con una caja de S/ '
            '${cajaProyectada.toStringAsFixed(0)}.',
        'El límite de sobregiro de este mercado es S/ '
            '${est.limiteSobregiro.toStringAsFixed(0)}. Pasarlo termina la '
            'partida por quiebra técnica.',
        'Proyección sobre el mercado estimado'
            '${proyeccion.confiable ? '' : ', con supuestos importantes sin verificar'}.',
      );
    }

    consejos.sort((Consejo a, Consejo b) =>
        a.severidad.index.compareTo(b.severidad.index));
    return consejos;
  }

  static int _estudiosMuyRepetidos(Partida partida) {
    final Map<String, int> cuenta = <String, int>{};
    for (final Hallazgo h in partida.hallazgos) {
      cuenta[h.clave] = (cuenta[h.clave] ?? 0) + 1;
    }
    int repetidos = 0;
    cuenta.forEach((String _, int veces) {
      if (veces >= 3) repetidos++;
    });
    return repetidos;
  }

  /// Resumen numérico para la cabecera del panel del analista.
  static Map<String, double> indicadores(Proyeccion p) {
    return <String, double>{
      'unidades': p.resultado.unidades,
      'utilidad': p.resultado.utilidad,
      'participacion': p.resultado.participacion,
      'satisfaccion': p.resultado.satisfaccion,
      'margen': p.resultado.margenPorcentaje,
      'caja': math.max(p.resultado.cajaFinal, -999999999.0),
    };
  }
}
