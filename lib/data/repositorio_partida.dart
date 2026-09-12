import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/mercado.dart';
import '../domain/models/partida.dart';
import 'catalogo_mercados.dart';

/// Resumen de una partida terminada, para la lista de partidas anteriores.
class ResumenPartida {
  const ResumenPartida({
    required this.mercadoId,
    required this.mercadoNombre,
    required this.marca,
    required this.fecha,
    required this.utilidad,
    required this.puntaje,
    required this.quiebra,
  });

  final String mercadoId;
  final String mercadoNombre;
  final String marca;
  final DateTime fecha;
  final double utilidad;
  final double puntaje;
  final bool quiebra;

  Map<String, dynamic> aJson() => <String, dynamic>{
        'mercadoId': mercadoId,
        'mercadoNombre': mercadoNombre,
        'marca': marca,
        'fecha': fecha.toIso8601String(),
        'utilidad': utilidad,
        'puntaje': puntaje,
        'quiebra': quiebra,
      };

  static ResumenPartida desdeJson(Map<String, dynamic> j) => ResumenPartida(
        mercadoId: j['mercadoId'] as String,
        mercadoNombre: j['mercadoNombre'] as String,
        marca: j['marca'] as String,
        fecha: DateTime.parse(j['fecha'] as String),
        utilidad: (j['utilidad'] as num).toDouble(),
        puntaje: (j['puntaje'] as num).toDouble(),
        quiebra: j['quiebra'] as bool,
      );
}

/// Persistencia local de la partida.
///
/// Es la unica frontera de almacenamiento de la aplicacion. Toda la interfaz
/// habla con el repositorio, nunca con `SharedPreferences` directamente: si
/// manana la partida se guarda en un servidor para que el docente vea el aula
/// completa, solo cambia esta clase.
class RepositorioPartida {
  static const String _claveActual = 'msl_partida_actual';
  static const String _claveHistorial = 'msl_historial';

  Future<void> guardar(Partida partida) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveActual, jsonEncode(partida.aJson()));
  }

  Future<Partida?> cargar() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? crudo = prefs.getString(_claveActual);
    if (crudo == null || crudo.isEmpty) return null;
    try {
      final Map<String, dynamic> json =
          Map<String, dynamic>.from(jsonDecode(crudo) as Map<dynamic, dynamic>);
      final Mercado? mercado =
          CatalogoMercados.porId(json['mercadoId'] as String);
      if (mercado == null) return null;
      return Partida.desdeJson(json, mercado);
    } catch (_) {
      // Una partida guardada con una version anterior del formato no debe
      // impedir abrir la aplicacion: se descarta y se empieza de nuevo.
      await prefs.remove(_claveActual);
      return null;
    }
  }

  Future<void> borrar() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveActual);
  }

  Future<List<ResumenPartida>> historial() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> crudos = prefs.getStringList(_claveHistorial) ?? <String>[];
    final List<ResumenPartida> lista = <ResumenPartida>[];
    for (final String c in crudos) {
      try {
        lista.add(ResumenPartida.desdeJson(
            Map<String, dynamic>.from(jsonDecode(c) as Map<dynamic, dynamic>)));
      } catch (_) {
        continue;
      }
    }
    lista.sort((ResumenPartida a, ResumenPartida b) =>
        b.fecha.compareTo(a.fecha));
    return lista;
  }

  Future<void> registrar(ResumenPartida resumen) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> crudos =
        prefs.getStringList(_claveHistorial) ?? <String>[];
    crudos.add(jsonEncode(resumen.aJson()));
    // Se conservan las ultimas 20 partidas: mas que eso no aporta al
    // estudiante y hace pesada la lectura del almacenamiento.
    final List<String> recortados =
        crudos.length > 20 ? crudos.sublist(crudos.length - 20) : crudos;
    await prefs.setStringList(_claveHistorial, recortados);
  }
}
