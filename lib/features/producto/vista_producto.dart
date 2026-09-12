import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../core/widgets/metrica.dart';
import '../../core/widgets/tarjeta.dart';
import '../../domain/models/beneficio.dart';
import '../panel/vm_partida.dart';

/// Módulo 3 · Producto.
///
/// Aquí se decide lo que el cliente recibe. La diferencia con el módulo
/// Cliente es deliberada: allí se decide lo que se promete, aquí lo que se
/// entrega, y la distancia entre ambos es lo que el simulador llama
/// satisfacción.
class VistaProducto extends StatelessWidget {
  const VistaProducto({super.key});

  @override
  Widget build(BuildContext context) {
    final VmPartida vm = AlcancePartida.de(context);
    final double brecha = vm.decisiones.nivelPromesa - vm.decisiones.calidad;
    return Scaffold(
      appBar: AppBar(
        title: const Text('3 · Producto'),
        backgroundColor: Tema.producto,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          const NotaConcepto(
            titulo: 'Satisfacción = entrega − expectativa',
            texto:
                'La satisfacción no mide calidad absoluta. Un producto modesto '
                'con una promesa modesta deja al cliente satisfecho; un '
                'producto bueno con una promesa exagerada, no. Y la '
                'insatisfacción no solo pierde al cliente: acelera el olvido '
                'de la marca por boca a boca.',
          ),
          const SizedBox(height: 16),
          Tarjeta(
            titulo: 'Calidad del producto',
            subtitulo:
                'Sube el costo unitario: cada punto de calidad agrega 18% del '
                'costo base.',
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Slider(
                        value: vm.decisiones.calidad,
                        min: 1,
                        max: 5,
                        divisions: 8,
                        activeColor: Tema.producto,
                        onChanged: (double v) => vm.fijarProducto(
                            v,
                            vm.decisiones.beneficioReal,
                            vm.decisiones.amplitud),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                          '${vm.decisiones.calidad.toStringAsFixed(1)}/5',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Metrica(
                        etiqueta: 'Costo unitario',
                        valor: Formato.solesExactos(vm.costoUnitario),
                        nota: 'con la calidad y línea actuales',
                      ),
                    ),
                    Expanded(
                      child: Metrica(
                        etiqueta: 'Brecha con la promesa',
                        valor: brecha > 0
                            ? '+${brecha.toStringAsFixed(1)}'
                            : brecha.toStringAsFixed(1),
                        color: brecha >= 1.0
                            ? Tema.critica
                            : brecha <= -1.2
                                ? Tema.advertencia
                                : Tema.confirmacion,
                        nota: brecha >= 1.0
                            ? 'prometes de más'
                            : brecha <= -1.2
                                ? 'entregas de más'
                                : 'coherente',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Tarjeta(
            titulo: 'Beneficio que el producto entrega',
            subtitulo:
                'Si no coincide con lo que prometes, el cliente llega y se va '
                'decepcionado.',
            hijo: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Beneficio.values.map((Beneficio b) {
                final bool elegido = vm.decisiones.beneficioReal == b;
                final bool esPromesa = vm.decisiones.beneficioPrometido == b;
                return ChoiceChip(
                  label: Text(
                    '${b.etiqueta}${esPromesa ? ' ·  prometido' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: elegido,
                  onSelected: (_) => vm.fijarProducto(
                      vm.decisiones.calidad, b, vm.decisiones.amplitud),
                  selectedColor: const Color(0xFFE0EDF0),
                  side: BorderSide(
                      color: elegido ? Tema.producto : Tema.borde),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Tarjeta(
            titulo: 'Amplitud de línea',
            subtitulo:
                'Más presentaciones atraen a segmentos que valoran variedad, '
                'pero cada una agrega 5% al costo unitario.',
            hijo: Column(
              children: <Widget>[
                SegmentedButton<int>(
                  segments: const <ButtonSegment<int>>[
                    ButtonSegment<int>(value: 1, label: Text('1 presentación')),
                    ButtonSegment<int>(value: 2, label: Text('2')),
                    ButtonSegment<int>(value: 3, label: Text('3')),
                  ],
                  selected: <int>{vm.decisiones.amplitud},
                  onSelectionChanged: (Set<int> seleccion) => vm.fijarProducto(
                      vm.decisiones.calidad,
                      vm.decisiones.beneficioReal,
                      seleccion.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (vm.decisiones.beneficioReal != vm.decisiones.beneficioPrometido)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBEAEA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFC0C0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.error_outline,
                      size: 18, color: Tema.critica),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Tu campaña promete '
                        '${vm.decisiones.beneficioPrometido.etiqueta.toLowerCase()} '
                        'y el producto entrega '
                        '${vm.decisiones.beneficioReal.etiqueta.toLowerCase()}. '
                        'La promesa atrae una vez; el producto es el que '
                        'retiene.',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
