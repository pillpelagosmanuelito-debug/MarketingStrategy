import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../core/widgets/metrica.dart';
import '../../core/widgets/tarjeta.dart';
import '../../domain/engine/analista.dart';
import '../panel/vm_partida.dart';

/// Panel del analista de marketing.
///
/// Muestra tres cosas y en este orden: la proyección con los datos que el
/// estudiante conoce, los supuestos que hubo que hacer por falta de estudios,
/// y las observaciones ordenadas por gravedad. Cada observación lleva su
/// fundamento y la evidencia de la que sale.
class PanelAnalista extends StatelessWidget {
  const PanelAnalista({super.key}) : controlador = null;

  const PanelAnalista._conControlador(this.controlador);

  final ScrollController? controlador;

  static Future<void> mostrar(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Tema.fondo,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext contexto) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (BuildContext c, ScrollController control) =>
            PanelAnalista._conControlador(control),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final VmPartida vm = AlcancePartida.de(context);
    final Proyeccion proyeccion = vm.proyeccion;
    final List<Consejo> consejos = vm.consejos;

    return ListView(
      controller: controlador,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
      children: <Widget>[
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Tema.borde,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            const Icon(Icons.insights_outlined, color: Tema.acento),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Analista de marketing',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
            'Trabaja únicamente con los estudios que contrataste y con los '
            'resultados que ya viste. No conoce los datos ocultos del mercado, '
            'así que no puede adelantártelos.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        Tarjeta(
          titulo: 'Proyección del periodo',
          subtitulo:
              'Qué pasaría si tus estimaciones fueran correctas. No es una '
              'predicción del resultado real.',
          hijo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Metrica(
                        etiqueta: 'Ventas',
                        valor: Formato.compacto(
                            proyeccion.resultado.unidades)),
                  ),
                  Expanded(
                    child: Metrica(
                        etiqueta: 'Participación',
                        valor: Formato.porcentaje(
                            proyeccion.resultado.participacion)),
                  ),
                  Expanded(
                    child: Metrica(
                      etiqueta: 'Utilidad',
                      valor:
                          Formato.compacto(proyeccion.resultado.utilidad),
                      color: proyeccion.resultado.utilidad < 0
                          ? Tema.critica
                          : Tema.confirmacion,
                    ),
                  ),
                ],
              ),
              if (proyeccion.supuestos.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF6EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                          'Esta proyección descansa en '
                          '${proyeccion.supuestos.length} supuesto(s) sin '
                          'verificar:',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Tema.advertencia)),
                      const SizedBox(height: 6),
                      ...proyeccion.supuestos.map((String s) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('· $s',
                                style: Theme.of(context).textTheme.bodySmall),
                          )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: Text('Observaciones (${consejos.length})',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (consejos.isEmpty)
          Tarjeta(
            hijo: Text(
                'No tengo observaciones con la información disponible. Eso no '
                'quiere decir que todo esté bien: quiere decir que no hay '
                'evidencia para decir lo contrario.',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ...consejos.map((Consejo c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TarjetaConsejo(consejo: c),
            )),
      ],
    );
  }
}

class _TarjetaConsejo extends StatelessWidget {
  const _TarjetaConsejo({required this.consejo});

  final Consejo consejo;

  static Color _color(Severidad s) {
    switch (s) {
      case Severidad.critica:
        return Tema.critica;
      case Severidad.advertencia:
        return Tema.advertencia;
      case Severidad.observacion:
        return Tema.observacion;
      case Severidad.confirmacion:
        return Tema.confirmacion;
    }
  }

  static String _etiqueta(Severidad s) {
    switch (s) {
      case Severidad.critica:
        return 'CRÍTICO';
      case Severidad.advertencia:
        return 'ADVERTENCIA';
      case Severidad.observacion:
        return 'OBSERVACIÓN';
      case Severidad.confirmacion:
        return 'BIEN RESUELTO';
    }
  }

  static IconData _icono(Severidad s) {
    switch (s) {
      case Severidad.critica:
        return Icons.error_outline;
      case Severidad.advertencia:
        return Icons.warning_amber_outlined;
      case Severidad.observacion:
        return Icons.info_outline;
      case Severidad.confirmacion:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _color(consejo.severidad);
    return Container(
      decoration: BoxDecoration(
        color: Tema.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Tema.borde),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Icon(_icono(consejo.severidad), color: color, size: 22),
          title: Text(consejo.titulo,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, height: 1.3)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('${_etiqueta(consejo.severidad)} · ${consejo.regla}',
                style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(consejo.mensaje,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Tema.fondo,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('POR QUÉ IMPORTA',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                          color: Tema.textoSuave)),
                  const SizedBox(height: 4),
                  Text(consejo.fundamento,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 9),
                  const Text('EVIDENCIA',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                          color: Tema.textoSuave)),
                  const SizedBox(height: 4),
                  Text(consejo.evidencia,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
