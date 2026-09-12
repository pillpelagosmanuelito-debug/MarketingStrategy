import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../core/widgets/metrica.dart';
import '../../core/widgets/tarjeta.dart';
import '../../domain/models/canal.dart';
import '../../domain/models/estudio.dart';
import '../../domain/models/medio.dart';
import '../../domain/models/segmento.dart';
import '../panel/vm_partida.dart';

/// Módulo 5 · Campañas.
///
/// Reúne las dos decisiones de llegada al cliente: los medios (cómo se entera)
/// y los canales (dónde compra). Están juntas porque en el motor se
/// multiplican: el recuerdo de marca sin disponibilidad no vende, y la
/// disponibilidad sin recuerdo tampoco.
class VistaCampanas extends StatelessWidget {
  const VistaCampanas({super.key});

  @override
  Widget build(BuildContext context) {
    final VmPartida vm = AlcancePartida.de(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('5 · Campañas'),
          backgroundColor: Tema.campanas,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFCDE7E2),
            tabs: <Widget>[
              Tab(text: 'Medios'),
              Tab(text: 'Canales'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _PestanaMedios(vm: vm),
            _PestanaCanales(vm: vm),
          ],
        ),
      ),
    );
  }
}

class _PestanaMedios extends StatelessWidget {
  const _PestanaMedios({required this.vm});

  final VmPartida vm;

  @override
  Widget build(BuildContext context) {
    final Segmento? objetivo = vm.segmentoObjetivo;
    final Hallazgo? habitos = objetivo == null
        ? null
        : vm.partida!.mejorHallazgo('medios', objetivo.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        const NotaConcepto(
          titulo: 'Alcance = inversión × eficiencia del medio × afinidad',
          texto:
              'Los tres factores se multiplican: si la afinidad del segmento '
              'con el medio es baja, no importa cuánto inviertas. Además cada '
              'medio tiene un mínimo por debajo del cual pierde hasta 55% de '
              'su alcance, y el recuerdo de marca se satura: duplicar la '
              'inversión no duplica las ventas.',
        ),
        const SizedBox(height: 14),
        Tarjeta(
          hijo: Row(
            children: <Widget>[
              Expanded(
                child: Metrica(
                    etiqueta: 'Inversión en medios',
                    valor: Formato.soles(vm.decisiones.gastoMedios)),
              ),
              Expanded(
                child: Metrica(
                  etiqueta: 'Disponible',
                  valor: Formato.soles(vm.disponible),
                  color: vm.disponible < 0 ? Tema.critica : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...Medio.values.map((Medio m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ControlMedio(
                vm: vm,
                medio: m,
                afinidad: habitos?.valor('medio:${m.id}'),
              ),
            )),
      ],
    );
  }
}

class _ControlMedio extends StatelessWidget {
  const _ControlMedio({
    required this.vm,
    required this.medio,
    required this.afinidad,
  });

  final VmPartida vm;
  final Medio medio;
  final double? afinidad;

  @override
  Widget build(BuildContext context) {
    final double monto = vm.decisiones.gastoEn(medio);
    final double maximo = (vm.caja * 0.35).clamp(20000.0, 400000.0).toDouble();
    final bool bajoMinimo = monto > 0 && monto < medio.minimo;
    return Tarjeta(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(medio.etiqueta,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text(Formato.soles(monto),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 2),
          Text(medio.nota, style: Theme.of(context).textTheme.bodySmall),
          Slider(
            value: monto.clamp(0.0, maximo).toDouble(),
            min: 0,
            max: maximo,
            divisions: 40,
            activeColor: Tema.campanas,
            onChanged: (double v) =>
                vm.fijarMedio(medio, (v / 1000).roundToDouble() * 1000),
          ),
          Row(
            children: <Widget>[
              _Pastilla(
                texto: 'Mínimo útil ${Formato.soles(medio.minimo)}',
                color: bajoMinimo ? Tema.advertencia : Tema.textoSuave,
              ),
              const SizedBox(width: 8),
              _Pastilla(
                texto: afinidad == null
                    ? 'Afinidad sin investigar'
                    : 'Afinidad ${Formato.porcentajeCorto(afinidad!)}',
                color: afinidad == null
                    ? Tema.advertencia
                    : afinidad! < 0.15
                        ? Tema.critica
                        : Tema.confirmacion,
              ),
            ],
          ),
          if (bajoMinimo)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  'Por debajo del mínimo este medio pierde eficacia: se paga '
                  'igual pero no alcanza frecuencia suficiente.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Tema.advertencia)),
            ),
        ],
      ),
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Tema.fondo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Tema.borde),
      ),
      child: Text(texto,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _PestanaCanales extends StatelessWidget {
  const _PestanaCanales({required this.vm});

  final VmPartida vm;

  @override
  Widget build(BuildContext context) {
    final Segmento? objetivo = vm.segmentoObjetivo;
    final Hallazgo? auditoria = objetivo == null
        ? null
        : vm.partida!.mejorHallazgo('canales', objetivo.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        const NotaConcepto(
          titulo: 'La cobertura no suma, se solapa',
          texto:
              'Dos canales que llegan al mismo público no duplican la '
              'cobertura: duplican el costo fijo. Cada canal cobra por estar, '
              'se venda o no, y además retiene un margen sobre cada unidad '
              'vendida.',
        ),
        const SizedBox(height: 14),
        Tarjeta(
          hijo: Row(
            children: <Widget>[
              Expanded(
                child: Metrica(
                    etiqueta: 'Costo fijo de canales',
                    valor: Formato.soles(vm.decisiones.costoFijoCanales),
                    nota: 'por periodo'),
              ),
              Expanded(
                child: Metrica(
                  etiqueta: 'Margen promedio',
                  valor: Formato.porcentajeCorto(vm.margenCanalObjetivo),
                  nota: 'que retiene el canal',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...Canal.values.map((Canal c) {
          final bool activo = vm.decisiones.canales.contains(c);
          final double? cobertura = auditoria?.valor('canal:${c.id}');
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => vm.alternarCanal(c),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: activo ? const Color(0xFFEAF6F3) : Tema.superficie,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: activo ? Tema.campanas : Tema.borde,
                      width: activo ? 1.6 : 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      activo ? Icons.check_box : Icons.check_box_outline_blank,
                      color: activo ? Tema.campanas : Tema.textoSuave,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(c.etiqueta,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 3),
                          Text(c.nota,
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: <Widget>[
                              _Pastilla(
                                  texto:
                                      '${Formato.soles(c.costoFijo)} por periodo',
                                  color: Tema.textoSuave),
                              _Pastilla(
                                  texto:
                                      'Margen del canal ${Formato.porcentajeCorto(c.margen)}',
                                  color: Tema.textoSuave),
                              _Pastilla(
                                texto: cobertura == null
                                    ? 'Cobertura sin investigar'
                                    : 'Llega al ${Formato.porcentajeCorto(cobertura)} del objetivo',
                                color: cobertura == null
                                    ? Tema.advertencia
                                    : cobertura < 0.12
                                        ? Tema.critica
                                        : Tema.confirmacion,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
