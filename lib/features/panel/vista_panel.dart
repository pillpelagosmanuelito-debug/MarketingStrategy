import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../core/widgets/metrica.dart';
import '../../core/widgets/tarjeta.dart';
import '../../domain/models/canal.dart';
import '../../domain/models/evento.dart';
import '../../domain/models/resultado_periodo.dart';
import '../../domain/models/segmento.dart';
import '../analista/panel_analista.dart';
import '../campanas/vista_campanas.dart';
import '../cliente/vista_cliente.dart';
import '../conceptos/vista_conceptos.dart';
import '../historial/vista_historial.dart';
import '../mercado/vista_mercado.dart';
import '../precio/vista_precio.dart';
import '../producto/vista_producto.dart';
import '../resultados/vista_resultados.dart';
import 'vm_partida.dart';

/// Tablero del periodo: lo que pasó, lo que decidiste y lo que falta decidir.
class VistaPanel extends StatelessWidget {
  const VistaPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final VmPartida vm = AlcancePartida.de(context);
    final ResultadoPeriodo? ultimo = vm.ultimoResultado;
    final Segmento? objetivo = vm.segmentoObjetivo;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(vm.partida!.marca,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              '${vm.mercado!.nombre} · ${Formato.periodo(vm.periodo, vm.totalPeriodos)}',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFFBFD5DB)),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Evolución',
            icon: const Icon(Icons.show_chart),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const VistaHistorial()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (String opcion) async {
              if (opcion == 'conceptos') {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const VistaConceptos()),
                );
              } else if (opcion == 'abandonar') {
                final bool confirmado = await _confirmarAbandono(context);
                if (confirmado) await vm.abandonar();
              }
            },
            itemBuilder: (BuildContext contexto) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                  value: 'conceptos', child: Text('Conceptos')),
              const PopupMenuItem<String>(
                  value: 'abandonar', child: Text('Abandonar partida')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Tema.acento,
        foregroundColor: Colors.white,
        onPressed: () => PanelAnalista.mostrar(context),
        icon: const Icon(Icons.insights_outlined),
        label: const Text('Analista'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: <Widget>[
          _Indicadores(ultimo: ultimo, vm: vm),
          const SizedBox(height: 12),
          if (vm.eventosDelPeriodo.isNotEmpty) ...<Widget>[
            ...vm.eventosDelPeriodo.map((Evento e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TarjetaEvento(evento: e),
                )),
          ],
          if (ultimo != null) ...<Widget>[
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => VistaResultados(resultado: ultimo),
                ),
              ),
              icon: const Icon(Icons.assessment_outlined),
              label: Text('Ver el detalle del periodo ${ultimo.periodo + 1}'),
            ),
            const SizedBox(height: 12),
          ],
          Tarjeta(
            titulo: 'Tu decisión de este periodo',
            subtitulo: objetivo == null
                ? 'Sin segmento objetivo'
                : 'Objetivo: ${objetivo.nombre}',
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _LineaResumen(
                  etiqueta: 'Promesa',
                  valor:
                      '${vm.decisiones.beneficioPrometido.etiqueta} · nivel '
                      '${vm.decisiones.nivelPromesa.toStringAsFixed(1)}/5',
                ),
                _LineaResumen(
                  etiqueta: 'Producto',
                  valor: 'Calidad ${vm.decisiones.calidad.toStringAsFixed(1)}/5 · '
                      '${vm.decisiones.beneficioReal.etiqueta} · '
                      '${vm.decisiones.amplitud} presentación(es)',
                ),
                _LineaResumen(
                  etiqueta: 'Precio',
                  valor: Formato.solesExactos(vm.decisiones.precio),
                ),
                _LineaResumen(
                  etiqueta: 'Canales',
                  valor: vm.decisiones.canales.isEmpty
                      ? 'Ninguno'
                      : vm.decisiones.canales
                          .map((Canal c) => c.etiqueta)
                          .join(', '),
                ),
                _LineaResumen(
                  etiqueta: 'Medios',
                  valor: Formato.soles(vm.decisiones.gastoMedios),
                ),
                _LineaResumen(
                  etiqueta: 'Investigación',
                  valor: Formato.soles(vm.decisiones.investigacion),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Módulos de decisión',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _Modulo(
            numero: '1',
            nombre: 'Mercado',
            descripcion: 'Contrata estudios y descubre cómo está partida la '
                'demanda.',
            estado: '${vm.partida!.hallazgos.length} estudio(s) contratado(s)',
            color: Tema.mercado,
            destino: const VistaMercado(),
          ),
          _Modulo(
            numero: '2',
            nombre: 'Cliente',
            descripcion:
                'Elige el segmento objetivo y define qué le vas a prometer.',
            estado: objetivo?.nombre ?? 'Sin definir',
            color: Tema.cliente,
            destino: const VistaCliente(),
          ),
          _Modulo(
            numero: '3',
            nombre: 'Producto',
            descripcion:
                'Calidad, beneficio real y amplitud de línea. Define tu costo.',
            estado:
                'Costo unitario ${Formato.solesExactos(vm.costoUnitario)}',
            color: Tema.producto,
            destino: const VistaProducto(),
          ),
          _Modulo(
            numero: '4',
            nombre: 'Precio',
            descripcion: 'Fija el precio y revisa margen y punto de equilibrio.',
            estado: vm.contribucionUnitaria > 0
                ? 'Contribución ${Formato.solesExactos(vm.contribucionUnitaria)} por unidad'
                : 'Contribución negativa',
            color: Tema.precio,
            destino: const VistaPrecio(),
          ),
          _Modulo(
            numero: '5',
            nombre: 'Campañas',
            descripcion: 'Reparte la inversión en medios y elige tus canales.',
            estado:
                '${Formato.soles(vm.decisiones.gastoMedios)} en medios · '
                '${vm.decisiones.canales.length} canal(es)',
            color: Tema.campanas,
            destino: const VistaCampanas(),
          ),
          const SizedBox(height: 18),
          _CierrePeriodo(vm: vm),
        ],
      ),
    );
  }

  Future<bool> _confirmarAbandono(BuildContext context) async {
    final bool? respuesta = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogo) => AlertDialog(
        title: const Text('¿Abandonar la partida?'),
        content: const Text(
            'Se borrará el avance actual. Las partidas ya terminadas se '
            'conservan en el historial.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(dialogo).pop(false),
              child: const Text('Seguir jugando')),
          FilledButton(
              onPressed: () => Navigator.of(dialogo).pop(true),
              child: const Text('Abandonar')),
        ],
      ),
    );
    return respuesta ?? false;
  }
}

class _Indicadores extends StatelessWidget {
  const _Indicadores({required this.ultimo, required this.vm});

  final ResultadoPeriodo? ultimo;
  final VmPartida vm;

  @override
  Widget build(BuildContext context) {
    final ResultadoPeriodo? previo = vm.partida!.historial.length >= 2
        ? vm.partida!.historial[vm.partida!.historial.length - 2]
        : null;
    double? variacion(double? actual, double? anterior) {
      if (actual == null || anterior == null || anterior == 0) return null;
      return (actual - anterior) / anterior.abs();
    }

    return Tarjeta(
      titulo: 'Resultado del periodo anterior',
      subtitulo: ultimo == null
          ? 'Todavía no has cerrado ningún periodo.'
          : 'Periodo ${ultimo.periodo + 1}',
      hijo: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Metrica(
                  etiqueta: 'Ventas',
                  valor: ultimo == null
                      ? '—'
                      : Formato.compacto(ultimo.unidades),
                  nota: '${vm.mercado!.unidad}s',
                  variacion: variacion(ultimo?.unidades, previo?.unidades),
                ),
              ),
              Expanded(
                child: Metrica(
                  etiqueta: 'Participación',
                  valor: ultimo == null
                      ? '—'
                      : Formato.porcentaje(ultimo.participacion),
                  variacion:
                      variacion(ultimo?.participacion, previo?.participacion),
                ),
              ),
              Expanded(
                child: Metrica(
                  etiqueta: 'Satisfacción',
                  valor: ultimo == null
                      ? '—'
                      : Formato.porcentajeCorto(ultimo.satisfaccion),
                  color: ultimo == null
                      ? null
                      : ultimo.satisfaccion < 0.45
                          ? Tema.critica
                          : ultimo.satisfaccion > 0.65
                              ? Tema.confirmacion
                              : null,
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
                  etiqueta: 'Caja',
                  valor: Formato.compacto(vm.caja),
                  color: vm.caja < 0 ? Tema.critica : null,
                  nota: 'soles disponibles',
                ),
              ),
              Expanded(
                child: Metrica(
                  etiqueta: 'Utilidad acumulada',
                  valor: Formato.compacto(vm.partida!.utilidadAcumulada),
                  color: vm.partida!.utilidadAcumulada < 0 ? Tema.critica : null,
                ),
              ),
              Expanded(
                child: Metrica(
                  etiqueta: 'Reputación',
                  valor: Formato.porcentajeCorto(
                      vm.partida!.estadoMarca.reputacion),
                  nota:
                      'claridad ${Formato.porcentajeCorto(vm.partida!.estadoMarca.claridad)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaEvento extends StatelessWidget {
  const _TarjetaEvento({required this.evento});

  final Evento evento;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0D6AE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.campaign_outlined,
                  size: 18, color: Tema.advertencia),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Hecho del mercado: ${evento.titulo}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(evento.descripcion,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LineaResumen extends StatelessWidget {
  const _LineaResumen({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 108,
            child: Text(etiqueta,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: Tema.textoSuave,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

class _Modulo extends StatelessWidget {
  const _Modulo({
    required this.numero,
    required this.nombre,
    required this.descripcion,
    required this.estado,
    required this.color,
    required this.destino,
  });

  final String numero;
  final String nombre;
  final String descripcion;
  final String estado;
  final Color color;
  final Widget destino;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => destino),
        ),
        child: Tarjeta(
          padding: const EdgeInsets.all(14),
          hijo: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(numero,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(nombre,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(descripcion,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 5),
                    Text(estado,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Tema.textoSuave),
            ],
          ),
        ),
      ),
    );
  }
}

class _CierrePeriodo extends StatelessWidget {
  const _CierrePeriodo({required this.vm});

  final VmPartida vm;

  @override
  Widget build(BuildContext context) {
    final double comprometido = vm.gastoComprometido;
    return Tarjeta(
      titulo: 'Cerrar el periodo',
      subtitulo:
          'Una vez cerrado no se puede volver atrás: el mercado responde y los '
          'competidores también.',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          BarraValor(
            etiqueta: 'Gasto comprometido sobre la caja',
            fraccion: vm.caja > 0 ? comprometido / vm.caja : 1.0,
            textoValor: Formato.soles(comprometido),
            color: comprometido > vm.caja ? Tema.critica : Tema.primarioClaro,
            detalle:
                'Medios, canales e investigación de este periodo. Los costos '
                'fijos y el costo de producción se cargan al cerrar.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _cerrar(context),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Cerrar periodo ${vm.periodo + 1} y ver resultados'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrar(BuildContext context) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogo) => AlertDialog(
        title: Text('Cerrar periodo ${vm.periodo + 1}'),
        content: Text(
            'Se ejecutará la simulación con tus decisiones actuales. '
            'Comprometiste ${Formato.soles(vm.gastoComprometido)} en medios, '
            'canales e investigación.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(dialogo).pop(false),
              child: const Text('Revisar')),
          FilledButton(
              onPressed: () => Navigator.of(dialogo).pop(true),
              child: const Text('Cerrar periodo')),
        ],
      ),
    );
    if (confirmado != true) return;
    final ResultadoPeriodo resultado = await vm.cerrarPeriodo();
    if (!context.mounted) return;
    if (!vm.partida!.terminada) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => VistaResultados(resultado: resultado),
        ),
      );
    }
  }
}
