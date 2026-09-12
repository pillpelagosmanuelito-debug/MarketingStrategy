/// Un hecho del mercado que ocurre en un periodo determinado.
///
/// Los eventos son deterministas por mercado: toda el aula enfrenta lo mismo
/// en el mismo periodo, de modo que las decisiones sean comparables entre
/// estudiantes. Lo que cambia entre partidas es la respuesta, no el escenario.
class Evento {
  const Evento({
    required this.periodo,
    required this.titulo,
    required this.descripcion,
    this.competidor = '',
    this.cambioPrecio = 1.0,
    this.cambioMedios = 1.0,
    this.cambioCalidad = 0.0,
    this.factorCosto = 1.0,
    this.segmento = '',
    this.factorTamano = 1.0,
  });

  /// Indice de periodo (0 = primer periodo).
  final int periodo;
  final String titulo;
  final String descripcion;

  /// Competidor afectado, si el evento es un movimiento de la competencia.
  final String competidor;
  final double cambioPrecio;
  final double cambioMedios;
  final double cambioCalidad;

  /// Multiplicador del costo base de la categoria.
  final double factorCosto;

  /// Segmento afectado, si el evento cambia el tamano de la demanda.
  final String segmento;
  final double factorTamano;
}
