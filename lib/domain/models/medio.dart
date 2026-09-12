/// Medios de comunicacion disponibles para las campanas.
///
/// Cada medio tiene una eficiencia (alcance por sol invertido) y un monto
/// minimo por debajo del cual la inversion pierde efectividad: una pauta de
/// television de S/ 5,000 no compra television, compra ruido.
enum Medio {
  tv('tv', 'Television', 0.85, 40000, 'Alcance masivo, costo de entrada alto.'),
  radio('radio', 'Radio', 1.05, 8000,
      'Buen alcance en provincias y en publico adulto; costo bajo.'),
  digital('digital', 'Digital y redes', 1.20, 3000,
      'El medio mas eficiente por sol, pero se satura rapido.'),
  influencers('influencers', 'Influencers', 1.10, 5000,
      'Construye imagen de marca; depende mucho de la afinidad del segmento.'),
  puntoVenta('punto_venta', 'Punto de venta', 0.95, 4000,
      'Activaciones y material en tienda; actua cerca de la decision de compra.');

  const Medio(this.id, this.etiqueta, this.eficiencia, this.minimo, this.nota);

  final String id;
  final String etiqueta;

  /// Alcance relativo por sol invertido.
  final double eficiencia;

  /// Inversion minima para que el medio rinda a plena eficiencia.
  final double minimo;
  final String nota;

  static Medio desdeId(String id) {
    return Medio.values.firstWhere((m) => m.id == id, orElse: () => Medio.digital);
  }
}
