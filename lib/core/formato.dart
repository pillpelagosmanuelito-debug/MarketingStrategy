/// Formato de numeros para la interfaz.
///
/// Todos los montos del simulador estan en soles y todas las cantidades en
/// unidades vendidas. Se centraliza aqui para que ninguna pantalla invente su
/// propio formato.
class Formato {
  const Formato._();

  /// Separador de miles: 1234567 -> 1,234,567
  static String miles(num valor) {
    final bool negativo = valor < 0;
    final String entero = valor.abs().round().toString();
    final StringBuffer salida = StringBuffer();
    for (int i = 0; i < entero.length; i++) {
      if (i > 0 && (entero.length - i) % 3 == 0) salida.write(',');
      salida.write(entero[i]);
    }
    return '${negativo ? '-' : ''}$salida';
  }

  /// S/ 1,234,567
  static String soles(num valor) => 'S/ ${miles(valor)}';

  /// S/ 6.80
  static String solesExactos(num valor) =>
      'S/ ${valor < 0 ? '-' : ''}${valor.abs().toStringAsFixed(2)}';

  /// 34.5%
  static String porcentaje(num fraccion, {int decimales = 1}) =>
      '${(fraccion * 100).toStringAsFixed(decimales)}%';

  /// 35%
  static String porcentajeCorto(num fraccion) =>
      '${(fraccion * 100).round()}%';

  /// 1.2 M / 340 mil / 850
  static String compacto(num valor) {
    final double v = valor.toDouble();
    if (v.abs() >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)} M';
    }
    if (v.abs() >= 10000) {
      return '${(v / 1000).toStringAsFixed(0)} mil';
    }
    return miles(v);
  }

  /// Periodo 3 de 8
  static String periodo(int indice, int total) => 'Periodo ${indice + 1} de $total';
}
