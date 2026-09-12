import 'decisiones.dart';
import 'estado_marca.dart';

/// Como reacciona un competidor a lo que hace el estudiante.
enum PoliticaCompetidor {
  /// Defiende volumen: si el estudiante le quita participacion, baja precio
  /// y sube presion publicitaria.
  liderMasivo,

  /// Defiende imagen: responde subiendo calidad e inversion digital.
  premium,

  /// Sigue al precio: se alinea con quien este por debajo.
  retador,
}

/// Una marca rival. Sus decisiones no son un guion fijo: responden al
/// desempeno del estudiante, por eso la misma jugada no siempre da el mismo
/// resultado.
class Competidor {
  Competidor({
    required this.id,
    required this.nombre,
    required this.decisiones,
    required this.estado,
    required this.politica,
  });

  final String id;
  final String nombre;
  Decisiones decisiones;
  EstadoMarca estado;
  final PoliticaCompetidor politica;

  Competidor copia() => Competidor(
        id: id,
        nombre: nombre,
        decisiones: decisiones.copiarCon(),
        estado: estado.copia(),
        politica: politica,
      );

  Map<String, dynamic> aJson() => <String, dynamic>{
        'id': id,
        'decisiones': decisiones.aJson(),
        'estado': estado.aJson(),
      };
}
