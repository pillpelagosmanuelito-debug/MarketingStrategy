/// Generador pseudoaleatorio determinista.
///
/// Se usa solo para el error de muestreo de los estudios de mercado. Es
/// determinista a proposito: dos estudiantes que contraten el mismo estudio en
/// la misma partida obtienen el mismo dato, de modo que el aula pueda comparar
/// decisiones y no suerte.
class Aleatorio {
  Aleatorio(int semilla) : _estado = (semilla & 0x7FFFFFFF) | 1;

  int _estado;

  double siguiente() {
    _estado = (_estado * 1103515245 + 12345) & 0x7FFFFFFF;
    return _estado / 0x7FFFFFFF;
  }

  /// Valor entre -1 y 1.
  double centrado() => siguiente() * 2.0 - 1.0;

  /// Aproximacion a una normal por suma de uniformes (teorema central del
  /// limite con tres muestras). Evita los extremos absurdos de una uniforme.
  double normal() => (centrado() + centrado() + centrado()) / 3.0;

  static int hashCadena(String texto) {
    int h = 7;
    for (int i = 0; i < texto.length; i++) {
      h = (h * 31 + texto.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return h;
  }
}
