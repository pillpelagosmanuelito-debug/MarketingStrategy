/// Canales de distribucion.
///
/// Cada canal cobra un costo fijo por periodo (por estar presente) y se queda
/// con un margen sobre el precio de venta. Estar en todos los canales no es
/// gratis: es la forma mas comun de perder plata en el simulador.
enum Canal {
  retail('retail', 'Retail moderno', 38000, 0.28,
      'Supermercados y cadenas. Alta visibilidad, margen alto para el canal.'),
  bodegas('bodegas', 'Bodegas y tradicional', 22000, 0.18,
      'Cobertura capilar. Margen bajo, pero exige reposicion constante.'),
  marketplace('marketplace', 'Marketplace', 9000, 0.20,
      'Bajo costo de entrada, comision por venta, alcance nacional.'),
  propio('propio', 'Canal propio', 16000, 0.06,
      'Tienda o plataforma propia. Margen casi completo, cobertura limitada.'),
  mayorista('mayorista', 'Distribuidor mayorista', 12000, 0.32,
      'Llega lejos y rapido, pero se lleva el margen mas alto.');

  const Canal(this.id, this.etiqueta, this.costoFijo, this.margen, this.nota);

  final String id;
  final String etiqueta;

  /// Costo fijo por periodo por estar presente en el canal.
  final double costoFijo;

  /// Porcentaje del precio de venta que retiene el canal.
  final double margen;
  final String nota;

  static Canal desdeId(String id) {
    return Canal.values.firstWhere((c) => c.id == id, orElse: () => Canal.propio);
  }
}
