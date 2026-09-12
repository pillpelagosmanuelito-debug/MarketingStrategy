import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../core/widgets/grafico_evolucion.dart';
import '../../core/widgets/tarjeta.dart';
import '../../domain/models/resultado_periodo.dart';
import '../panel/vm_partida.dart';

/// Evolución de la partida periodo a periodo.
///
/// Las cuatro series son las que el simulador dice medir: ventas,
/// satisfacción, participación y caja. Ver las cuatro juntas es lo que deja al
/// descubierto los intercambios: participación que sube mientras la caja baja,
/// ventas que suben mientras la satisfacción cae.
class VistaHistorial extends StatelessWidget {
  const VistaHistorial({super.key});

  @override
  Widget build(BuildContext context) {
    final VmPartida vm = AlcancePartida.de(context);
    final List<ResultadoPeriodo> historial = vm.partida!.historial;

    if (historial.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Evolución')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
                'Todavía no has cerrado ningún periodo. Aquí aparecerá la '
                'evolución de tus indicadores.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      );
    }

    List<double> serie(double Function(ResultadoPeriodo) f) =>
        historial.map(f).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Evolución')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Tarjeta(
            titulo: 'Ventas y participación',
            hijo: Column(
              children: <Widget>[
                GraficoEvolucion(
                  series: <Serie>[
                    Serie(
                      nombre: 'Unidades vendidas',
                      valores: serie((ResultadoPeriodo r) => r.unidades),
                      color: Tema.primario,
                    ),
                  ],
                  formatoEje: Formato.compacto,
                ),
                const SizedBox(height: 18),
                GraficoEvolucion(
                  series: <Serie>[
                    Serie(
                      nombre: 'Participación de mercado',
                      valores: serie(
                          (ResultadoPeriodo r) => r.participacion * 100),
                      color: Tema.acento,
                    ),
                  ],
                  minimoForzado: 0,
                  formatoEje: (double v) => '${v.toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Tarjeta(
            titulo: 'Satisfacción, reputación y claridad',
            subtitulo:
                'Los tres activos que no se compran con dinero en un solo '
                'periodo.',
            hijo: GraficoEvolucion(
              series: <Serie>[
                Serie(
                  nombre: 'Satisfacción',
                  valores:
                      serie((ResultadoPeriodo r) => r.satisfaccion * 100),
                  color: Tema.confirmacion,
                ),
                Serie(
                  nombre: 'Reputación',
                  valores: serie((ResultadoPeriodo r) => r.reputacion * 100),
                  color: Tema.cliente,
                ),
                Serie(
                  nombre: 'Claridad de marca',
                  valores: serie((ResultadoPeriodo r) => r.claridad * 100),
                  color: Tema.advertencia,
                ),
              ],
              minimoForzado: 0,
              formatoEje: (double v) => '${v.toStringAsFixed(0)}%',
            ),
          ),
          const SizedBox(height: 12),
          Tarjeta(
            titulo: 'Caja y utilidad',
            hijo: GraficoEvolucion(
              series: <Serie>[
                Serie(
                  nombre: 'Caja al cierre',
                  valores: serie((ResultadoPeriodo r) => r.cajaFinal),
                  color: Tema.primario,
                ),
                Serie(
                  nombre: 'Utilidad del periodo',
                  valores: serie((ResultadoPeriodo r) => r.utilidad),
                  color: Tema.precio,
                ),
              ],
              minimoForzado: 0,
              formatoEje: Formato.compacto,
            ),
          ),
          const SizedBox(height: 12),
          Tarjeta(
            titulo: 'Tabla de periodos',
            hijo: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 22,
                headingTextStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
                dataTextStyle: const TextStyle(fontSize: 12.5),
                columns: const <DataColumn>[
                  DataColumn(label: Text('P')),
                  DataColumn(label: Text('Ventas')),
                  DataColumn(label: Text('Part.')),
                  DataColumn(label: Text('Satisf.')),
                  DataColumn(label: Text('Utilidad')),
                  DataColumn(label: Text('Caja')),
                ],
                rows: historial
                    .map((ResultadoPeriodo r) => DataRow(
                          cells: <DataCell>[
                            DataCell(Text('${r.periodo + 1}')),
                            DataCell(Text(Formato.compacto(r.unidades))),
                            DataCell(
                                Text(Formato.porcentaje(r.participacion))),
                            DataCell(Text(
                                Formato.porcentajeCorto(r.satisfaccion))),
                            DataCell(Text(Formato.compacto(r.utilidad))),
                            DataCell(Text(Formato.compacto(r.cajaFinal))),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
