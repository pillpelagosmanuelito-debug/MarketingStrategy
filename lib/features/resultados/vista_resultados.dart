import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../core/widgets/metrica.dart';
import '../../core/widgets/tarjeta.dart';
import '../../domain/models/competidor.dart';
import '../../domain/models/resultado_periodo.dart';
import '../../domain/models/segmento.dart';
import '../panel/vm_partida.dart';

/// Resultado de un periodo cerrado.
///
/// El desglose por segmento es la parte importante: el total esconde el error
/// que se quiere enseñar. Un estudiante puede tener ventas correctas y estar
/// vendiéndole al segmento equivocado.
class VistaResultados extends StatelessWidget {
  const VistaResultados({super.key, required this.resultado});

  final ResultadoPeriodo resultado;

  @override
  Widget build(BuildContext context) {
    final VmPartida vm = AlcancePartida.de(context);
    final String unidad = vm.mercado!.unidad;

    return Scaffold(
      appBar: AppBar(title: Text('Resultados · periodo ${resultado.periodo + 1}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          if (resultado.eventos.isNotEmpty) ...<Widget>[
            Tarjeta(
              titulo: 'Lo que pasó en el mercado',
              hijo: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: resultado.eventos
                    .map((String e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text('· $e',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Tarjeta(
            titulo: 'Indicadores del periodo',
            hijo: Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Metrica(
                          etiqueta: 'Ventas',
                          valor: Formato.compacto(resultado.unidades),
                          nota: '${unidad}s'),
                    ),
                    Expanded(
                      child: Metrica(
                          etiqueta: 'Participación',
                          valor: Formato.porcentaje(resultado.participacion)),
                    ),
                    Expanded(
                      child: Metrica(
                        etiqueta: 'Satisfacción',
                        valor:
                            Formato.porcentajeCorto(resultado.satisfaccion),
                        color: resultado.satisfaccion < 0.45
                            ? Tema.critica
                            : Tema.confirmacion,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Metrica(
                          etiqueta: 'Reputación',
                          valor:
                              Formato.porcentajeCorto(resultado.reputacion)),
                    ),
                    Expanded(
                      child: Metrica(
                          etiqueta: 'Claridad de marca',
                          valor: Formato.porcentajeCorto(resultado.claridad)),
                    ),
                    Expanded(
                      child: Metrica(
                        etiqueta: 'Utilidad',
                        valor: Formato.compacto(resultado.utilidad),
                        color: resultado.utilidad < 0
                            ? Tema.critica
                            : Tema.confirmacion,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Tarjeta(
            titulo: 'Estado de resultados',
            subtitulo:
                'El ingreso ya está neto del margen que retienen los canales.',
            hijo: Column(
              children: <Widget>[
                _Fila('Ingreso neto de canal', resultado.ingresos),
                _Fila('Costo de producción', -resultado.costoVariable,
                    detalle:
                        '${Formato.compacto(resultado.unidades)} × ${Formato.solesExactos(resultado.costoUnitario)}'),
                _Fila('Costo fijo de operación', -resultado.costoFijo),
                _Fila('Costo fijo de canales', -resultado.costoCanales),
                _Fila('Inversión en medios', -resultado.gastoMedios),
                _Fila('Investigación de mercado', -resultado.gastoInvestigacion),
                _Fila('Impuesto', -resultado.impuesto),
                const Divider(height: 20),
                _Fila('Utilidad del periodo', resultado.utilidad,
                    destacado: true),
                _Fila('Caja al cierre', resultado.cajaFinal, destacado: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Tarjeta(
            titulo: 'Por segmento',
            subtitulo:
                'Dónde vendiste realmente. El objetivo declarado está marcado.',
            hijo: Column(
              children: resultado.segmentos.map((ResultadoSegmento s) {
                final Segmento? seg = vm.mercado!.segmentoPorId(s.segmentoId);
                final bool esObjetivo =
                    resultado.periodo < vm.partida!.decisionesTomadas.length &&
                        vm.partida!.decisionesTomadas[resultado.periodo]
                                .segmentoObjetivo ==
                            s.segmentoId;
                return BarraValor(
                  etiqueta:
                      '${seg?.nombre ?? s.segmentoId}${esObjetivo ? '  ·  objetivo' : ''}',
                  fraccion: resultado.unidades > 0
                      ? s.unidades / resultado.unidades
                      : 0,
                  textoValor:
                      '${Formato.compacto(s.unidades)} ${unidad}s',
                  color: esObjetivo ? Tema.cliente : Tema.primarioClaro,
                  detalle:
                      'Participación en el segmento ${Formato.porcentaje(s.participacion)} · '
                      'recuerdo de marca ${Formato.porcentajeCorto(s.awareness)} · '
                      'cobertura ${Formato.porcentajeCorto(s.cobertura)} · '
                      'satisfacción ${Formato.porcentajeCorto(s.satisfaccion)}',
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Tarjeta(
            titulo: 'Competencia',
            subtitulo: 'Unidades vendidas en todo el mercado.',
            hijo: Column(
              children: resultado.ventasCompetidores.entries.map(
                (MapEntry<String, double> e) {
                  final double total = resultado.ventasCompetidores.values
                      .fold(0.0, (double a, double b) => a + b);
                  String nombre = vm.partida!.marca;
                  if (e.key != 'jugador') {
                    for (final Competidor c in vm.partida!.competidores) {
                      if (c.id == e.key) nombre = c.nombre;
                    }
                  }
                  return BarraValor(
                    etiqueta: nombre,
                    fraccion: total > 0 ? e.value / total : 0,
                    textoValor: Formato.porcentaje(
                        total > 0 ? e.value / total : 0),
                    color: e.key == 'jugador' ? Tema.acento : Tema.textoSuave,
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver al tablero'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.monto, {this.detalle, this.destacado = false});

  final String etiqueta;
  final double monto;
  final String? detalle;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(etiqueta,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            destacado ? FontWeight.w700 : FontWeight.w400)),
                if (detalle != null)
                  Text(detalle!,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            Formato.soles(monto),
            style: TextStyle(
              fontSize: destacado ? 15 : 13.5,
              fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
              color: monto < 0 ? Tema.textoSuave : Tema.texto,
            ),
          ),
        ],
      ),
    );
  }
}
