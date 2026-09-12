import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../core/widgets/metrica.dart';
import '../../core/widgets/tarjeta.dart';
import '../../domain/engine/evaluador.dart';
import '../historial/vista_historial.dart';
import '../panel/vm_partida.dart';

/// Cierre de la partida: evaluación por las cuatro competencias y, recién
/// ahora, la lección del escenario.
///
/// La lección se revela al final a propósito: si se mostrara antes, el
/// estudiante resolvería el ejercicio leyendo en vez de decidiendo.
class VistaCierre extends StatelessWidget {
  const VistaCierre({super.key});

  @override
  Widget build(BuildContext context) {
    final VmPartida vm = AlcancePartida.de(context);
    final Evaluacion evaluacion = vm.evaluacion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informe de cierre'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Tarjeta(
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(vm.partida!.marca,
                              style:
                                  Theme.of(context).textTheme.headlineSmall),
                          Text(vm.mercado!.nombre,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text('${evaluacion.puntajeGlobal.round()}',
                            style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Tema.primario,
                                height: 1)),
                        const Text('de 100',
                            style: TextStyle(
                                fontSize: 11, color: Tema.textoSuave)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(evaluacion.resumen,
                    style: Theme.of(context).textTheme.bodyMedium),
                if (vm.partida!.quiebra) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBEAEA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'La partida terminó por quiebra técnica: la deuda superó '
                      'el límite de sobregiro del mercado.',
                      style: TextStyle(fontSize: 13, color: Tema.critica),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Tarjeta(
            titulo: 'Resultado económico',
            hijo: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Metrica(
                    etiqueta: 'Utilidad acumulada',
                    valor:
                        Formato.compacto(vm.partida!.utilidadAcumulada),
                    color: vm.partida!.utilidadAcumulada < 0
                        ? Tema.critica
                        : Tema.confirmacion,
                  ),
                ),
                Expanded(
                  child: Metrica(
                      etiqueta: 'Caja final',
                      valor: Formato.compacto(vm.caja)),
                ),
                Expanded(
                  child: Metrica(
                    etiqueta: 'Referencia',
                    valor:
                        Formato.compacto(vm.mercado!.utilidadReferencia),
                    nota: 'mejor estrategia verificada',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Competencias', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
              'Cada competencia vale 25% de la nota. Se evalúa el proceso '
              'comercial, no solo el resultado.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          ...evaluacion.competencias.map((NotaCompetencia c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TarjetaCompetencia(nota: c),
              )),
          const SizedBox(height: 6),
          Tarjeta(
            titulo: 'Lo que este escenario quería enseñar',
            color: Tema.acento,
            hijo: Text(evaluacion.leccion,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const VistaHistorial()),
            ),
            icon: const Icon(Icons.show_chart),
            label: const Text('Ver la evolución periodo a periodo'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => vm.abandonar(),
              icon: const Icon(Icons.refresh),
              label: const Text('Jugar otro escenario'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaCompetencia extends StatelessWidget {
  const _TarjetaCompetencia({required this.nota});

  final NotaCompetencia nota;

  Color get _color {
    if (nota.puntaje >= 85) return Tema.confirmacion;
    if (nota.puntaje >= 70) return Tema.primarioClaro;
    if (nota.puntaje >= 50) return Tema.advertencia;
    return Tema.critica;
  }

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(nota.nombre,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(nota.descripcion,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('${nota.puntaje.round()}',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _color,
                          height: 1.1)),
                  Text(nota.nivel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _color)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...nota.componentes.map((Componente c) => BarraValor(
                etiqueta:
                    '${c.etiqueta}  (${(c.peso * 100).round()}%)',
                fraccion: c.puntaje / 100,
                textoValor: '${c.puntaje.round()}',
                color: _color,
                detalle: c.detalle,
              )),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Tema.fondo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(nota.comentario,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
