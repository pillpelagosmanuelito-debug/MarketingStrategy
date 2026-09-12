import 'beneficio.dart';
import 'canal.dart';
import 'medio.dart';

/// Un segmento de mercado: un grupo de personas con la misma forma de decidir.
///
/// Todos los campos numericos son **ocultos** para el estudiante al empezar la
/// partida. Solo se conocen comprando estudios de investigacion, y siempre con
/// error de muestreo. Esa es la diferencia entre este simulador y una hoja de
/// calculo: aqui la informacion cuesta y no es exacta.
class Segmento {
  const Segmento({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tamano,
    required this.precioReferencia,
    required this.sensibilidad,
    required this.pesoCalidad,
    required this.pesoBeneficio,
    required this.pesoMarca,
    required this.pesoVariedad,
    required this.beneficio,
    required this.exigencia,
    required this.lealtad,
    required this.sospechaPrecioBajo,
    required this.afinidadMedio,
    required this.afinidadCanal,
  });

  final String id;
  final String nombre;

  /// Descripcion cualitativa: es lo unico publico antes de investigar.
  final String descripcion;

  /// Compradores potenciales por periodo.
  final double tamano;

  /// Precio que el segmento considera "normal" para la categoria.
  final double precioReferencia;

  /// Castigo en utilidad por cada punto de precio relativo sobre la referencia.
  final double sensibilidad;

  final double pesoCalidad;
  final double pesoBeneficio;
  final double pesoMarca;
  final double pesoVariedad;

  /// Beneficio que este segmento busca.
  final Beneficio beneficio;

  /// Nivel de calidad que el segmento da por descontado (1 a 5).
  final double exigencia;

  /// Inercia de compra: que tanto sostiene su eleccion anterior.
  final double lealtad;

  /// Castigo por precio demasiado bajo (senal de baja calidad).
  final double sospechaPrecioBajo;

  final Map<Medio, double> afinidadMedio;
  final Map<Canal, double> afinidadCanal;

  double afinidadDe(Medio m) => afinidadMedio[m] ?? 0.0;

  double coberturaDe(Canal c) => afinidadCanal[c] ?? 0.0;

  /// Ingreso potencial del segmento si se le vendiera a su precio de referencia.
  double get valorPotencial => tamano * precioReferencia;
}
