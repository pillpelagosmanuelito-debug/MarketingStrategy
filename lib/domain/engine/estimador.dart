import '../models/beneficio.dart';
import '../models/canal.dart';
import '../models/competidor.dart';
import '../models/decisiones.dart';
import '../models/estudio.dart';
import '../models/estado_marca.dart';
import '../models/evento.dart';
import '../models/medio.dart';
import '../models/mercado.dart';
import '../models/partida.dart';
import '../models/segmento.dart';

/// Construye el mercado **tal como el estudiante lo conoce**.
///
/// Esta clase es la frontera de honestidad del simulador. El analista de
/// marketing no recibe nunca el mercado real: recibe lo que devuelve este
/// estimador, armado unicamente con los estudios que el estudiante pago y con
/// los resultados que ya vio. Donde no hay evidencia, se usa un supuesto
/// neutral y se deja constancia en [supuestos], para que el analista pueda
/// decir "esto lo estoy suponiendo" en vez de afirmarlo.
class MercadoEstimado {
  MercadoEstimado({
    required this.mercado,
    required this.supuestos,
    required this.camposConocidos,
  });

  /// Mercado reconstruido con los datos estimados. Se puede pasar al motor
  /// para proyectar un periodo.
  final Mercado mercado;

  /// Que se tuvo que suponer por falta de estudios.
  final List<String> supuestos;

  /// Claves de los datos que si estan respaldados por un estudio.
  final Set<String> camposConocidos;

  bool conoce(String campo) => camposConocidos.contains(campo);

  static const double _pesoNeutro = 0.25;
  static const double _sensibilidadNeutra = 3.0;
  static const double _exigenciaNeutra = 3.0;
  static const double _lealtadNeutra = 0.40;
  static const double _sospechaNeutra = 1.0;
  static const double _afinidadNeutra = 0.30;
  static const double _awarenessNeutra = 0.45;
  static const double _reputacionNeutra = 0.55;
  static const double _claridadNeutra = 0.60;

  /// Arma la vista estimada del mercado a partir de la partida.
  static MercadoEstimado construir(Partida partida, Mercado real) {
    final List<String> supuestos = <String>[];
    final Set<String> conocidos = <String>{};

    final Hallazgo? tamanos = partida.mejorHallazgo('tamano', '');
    final double tamanoNeutro = real.tamanoDeclarado / real.segmentos.length;
    if (tamanos == null) {
      supuestos.add('No hay estudio de tamaño de mercado: se supone que los '
          'segmentos son de igual tamaño.');
    } else {
      conocidos.add('tamano');
    }

    final List<Segmento> segmentos = <Segmento>[];
    for (final Segmento s in real.segmentos) {
      final Hallazgo? perfil = partida.mejorHallazgo('perfil', s.id);
      final Hallazgo? precio = partida.mejorHallazgo('precio', s.id);
      final Hallazgo? canales = partida.mejorHallazgo('canales', s.id);
      final Hallazgo? medios = partida.mejorHallazgo('medios', s.id);

      if (perfil != null) conocidos.add('perfil:${s.id}');
      if (precio != null) conocidos.add('precio:${s.id}');
      if (canales != null) conocidos.add('canales:${s.id}');
      if (medios != null) conocidos.add('medios:${s.id}');

      final Map<Medio, double> afinidadMedio = <Medio, double>{};
      for (final Medio m in Medio.values) {
        afinidadMedio[m] =
            medios?.valor('medio:${m.id}') ?? _afinidadNeutra;
      }
      final Map<Canal, double> afinidadCanal = <Canal, double>{};
      for (final Canal c in Canal.values) {
        afinidadCanal[c] =
            canales?.valor('canal:${c.id}') ?? _afinidadNeutra;
      }

      Beneficio beneficio = partida.decisiones.beneficioPrometido;
      if (perfil != null) {
        final double? indice = perfil.valor('beneficio');
        if (indice != null) {
          beneficio = Beneficio.values[indice.round()];
        }
      } else {
        supuestos.add('Sin perfil de ${s.nombre}: se supone que busca el '
            'mismo beneficio que tú prometes.');
      }
      if (precio == null) {
        supuestos.add('Sin prueba de precio en ${s.nombre}: se supone que tu '
            'precio actual es el precio de referencia.');
      }

      segmentos.add(Segmento(
        id: s.id,
        nombre: s.nombre,
        descripcion: s.descripcion,
        tamano: tamanos?.valor('tamano:${s.id}') ?? tamanoNeutro,
        precioReferencia:
            precio?.valor('precioReferencia') ?? partida.decisiones.precio,
        sensibilidad: precio?.valor('sensibilidad') ?? _sensibilidadNeutra,
        pesoCalidad: perfil?.valor('pesoCalidad') ?? _pesoNeutro,
        pesoBeneficio: perfil?.valor('pesoBeneficio') ?? _pesoNeutro,
        pesoMarca: perfil?.valor('pesoMarca') ?? _pesoNeutro,
        pesoVariedad: perfil?.valor('pesoVariedad') ?? _pesoNeutro,
        beneficio: beneficio,
        exigencia: perfil?.valor('exigencia') ?? _exigenciaNeutra,
        lealtad: perfil?.valor('lealtad') ?? _lealtadNeutra,
        sospechaPrecioBajo:
            precio?.valor('sospechaPrecioBajo') ?? _sospechaNeutra,
        afinidadMedio: afinidadMedio,
        afinidadCanal: afinidadCanal,
      ));
    }

    final Hallazgo? mystery = partida.mejorHallazgo('mystery', '');
    if (mystery != null) {
      conocidos.add('mystery');
    } else {
      supuestos.add('Sin mystery shopper: se supone que los competidores '
          'venden al mismo precio que tú, con calidad media y en tus mismos '
          'canales.');
    }

    final List<Competidor> competidores = <Competidor>[];
    for (final Competidor c in partida.competidores) {
      final double precioEstimado =
          mystery?.valor('precio:${c.id}') ?? partida.decisiones.precio;
      final double calidadEstimada = mystery?.valor('calidad:${c.id}') ?? 3.0;
      final double? indicePromesa = mystery?.valor('promesa:${c.id}');
      final Beneficio promesa = indicePromesa != null
          ? Beneficio.values[indicePromesa.round()]
          : Beneficio.precio;

      Set<Canal> canalesEstimados;
      Map<Medio, double> mediosEstimados;
      if (mystery != null) {
        canalesEstimados = <Canal>{};
        for (final Canal canal in Canal.values) {
          if ((mystery.valor('canal:${canal.id}:${c.id}') ?? 0.0) > 0.5) {
            canalesEstimados.add(canal);
          }
        }
        mediosEstimados = <Medio, double>{};
        for (final Medio medio in Medio.values) {
          mediosEstimados[medio] =
              mystery.valor('medio:${medio.id}:${c.id}') ?? 0.0;
        }
      } else {
        canalesEstimados = Set<Canal>.from(partida.decisiones.canales);
        mediosEstimados = Map<Medio, double>.from(partida.decisiones.medios);
      }

      // El estudiante no puede observar el recuerdo de marca ni la reputacion
      // de un competidor: se usan valores neutrales, nunca los reales.
      final Map<String, double> awarenessNeutro = <String, double>{
        for (final Segmento s in real.segmentos) s.id: _awarenessNeutra
      };

      competidores.add(Competidor(
        id: c.id,
        nombre: c.nombre,
        politica: c.politica,
        decisiones: Decisiones(
          segmentoObjetivo: '',
          beneficioPrometido: promesa,
          nivelPromesa: mystery?.valor('nivel:${c.id}') ?? 3.0,
          calidad: calidadEstimada,
          beneficioReal: promesa,
          amplitud: 2,
          precio: precioEstimado,
          canales: canalesEstimados,
          medios: mediosEstimados,
        ),
        estado: EstadoMarca(
          awareness: awarenessNeutro,
          reputacion: _reputacionNeutra,
          claridad: _claridadNeutra,
        ),
      ));
    }

    final Hallazgo? marca = partida.mejorHallazgo('marca', '');
    if (marca != null) conocidos.add('marca');

    return MercadoEstimado(
      mercado: Mercado(
        id: real.id,
        nombre: real.nombre,
        categoria: real.categoria,
        contexto: real.contexto,
        unidad: real.unidad,
        tamanoDeclarado: real.tamanoDeclarado,
        segmentos: segmentos,
        costoBase: real.costoBase,
        costoFijo: real.costoFijo,
        utilidadReferencia: real.utilidadReferencia,
        cajaInicial: real.cajaInicial,
        limiteSobregiro: real.limiteSobregiro,
        periodos: real.periodos,
        competidoresBase: competidores,
        eventos: const <Evento>[],
        leccion: '',
      ),
      supuestos: supuestos,
      camposConocidos: conocidos,
    );
  }
}
