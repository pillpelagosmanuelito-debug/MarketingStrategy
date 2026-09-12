import '../models/beneficio.dart';

/// Parametros del modelo de simulacion.
///
/// Cada constante de este archivo existe tambien en `tool/calibracion.py`, el
/// prototipo con el que se calibro el motor. Si se cambia un valor aqui sin
/// volver a correr la calibracion, las pruebas de `test/calibracion_test.dart`
/// deben fallar: son la red de seguridad pedagogica del simulador.
class Parametros {
  const Parametros._();

  /// Sensibilidad del modelo logit a la utilidad percibida.
  static const double lambdaLogit = 3.0;

  /// Utilidad de no comprar nada. Sin esto, el mercado compraria siempre el
  /// 100% de su tamano, sin importar lo malo que fuera lo ofrecido.
  static const double utilidadNoCompra = 0.95;

  /// Saturacion de la inversion en medios: a partir de este monto, cada sol
  /// adicional compra menos recuerdo que el anterior.
  static const double kSaturacionMedios = 55000.0;

  static const double decaimientoAwareness = 0.15;
  static const double techoAwareness = 0.92;
  static const double pisoAwareness = 0.02;
  static const double techoCobertura = 0.95;

  /// Inercia maxima de compra (se multiplica por la lealtad del segmento).
  static const double inerciaBase = 0.30;

  static const double tasaImpuesto = 0.295;

  /// Curva de experiencia: el costo unitario cae este factor cada vez que se
  /// duplica el volumen acumulado, con un piso.
  static const double factorExperiencia = 0.965;
  static const double pisoExperiencia = 0.80;
  static const double volumenInicialExperiencia = 1000.0;

  /// Peso de la reputacion sobre el atractivo de la marca.
  static const double pesoReputacion = 1.30;

  /// La reputacion cae mas rapido de lo que sube.
  static const double caidaReputacion = 0.42;
  static const double subidaReputacion = 0.22;

  /// Boca a boca: debajo de este nivel de satisfaccion, la marca se olvida
  /// mas rapido; por encima de 0.72, se recuerda sola.
  static const double umbralBocaABoca = 0.45;
  static const double castigoBocaABoca = 0.55;
  static const double premioBocaABoca = 0.30;
  static const double umbralBocaABocaAlto = 0.72;
  static const double decaimientoMaximo = 0.70;

  static const double pisoSatisfaccion = 0.03;
  static const double techoSatisfaccion = 0.97;
  static const double baseSatisfaccion = 0.62;
  static const double pendienteSatisfaccion = 1.30;

  static const double pisoReputacion = 0.05;
  static const double techoReputacion = 0.95;

  /// Claridad de marca: cuanto se recupera por periodo de consistencia y
  /// cuanto se pierde al cambiar de posicionamiento.
  static const double recuperacionClaridad = 0.30;
  static const double castigoCambioPosicion = 0.55;
  static const double techoClaridad = 0.95;
  static const double inversionClaridadPlena = 60000.0;

  /// Umbral de precio por debajo del cual un segmento exigente sospecha de la
  /// calidad del producto.
  static const double umbralSospecha = 0.72;
  static const double pesoSospecha = 3.0;

  /// Componentes del costo unitario segun la calidad elegida.
  static const double costoBaseCalidad = 0.55;
  static const double costoPorCalidad = 0.18;
  static const double costoPorAmplitud = 0.05;

  /// Ponderaciones de la brecha promesa-entrega.
  static const double pesoCalidadEntrega = 0.55;
  static const double pesoBeneficioEntrega = 0.45;
  static const double pesoPrecioExpectativa = 0.15;
  static const double pesoExigencia = 0.03;

  static const double pisoSimilitud = 0.18;

  /// Similitud entre beneficios: que tan bien un beneficio cubre la necesidad
  /// de otro. No es simetrica por casualidad: se definio una sola vez y se
  /// consulta en ambos sentidos.
  static const Map<String, double> similitudes = <String, double>{
    'salud|rendimiento': 0.60,
    'salud|energia': 0.45,
    'energia|rendimiento': 0.55,
    'estatus|salud': 0.30,
    'estatus|rendimiento': 0.30,
    'precio|flexibilidad': 0.35,
    'flexibilidad|rendimiento': 0.30,
    'energia|flexibilidad': 0.25,
  };

  /// Que tanto cubre [a] la necesidad de [b].
  static double similitud(Beneficio a, Beneficio b) {
    if (a == b) return 1.0;
    final double? directa = similitudes['${a.id}|${b.id}'];
    if (directa != null) return directa;
    final double? inversa = similitudes['${b.id}|${a.id}'];
    if (inversa != null) return inversa;
    return pisoSimilitud;
  }
}
