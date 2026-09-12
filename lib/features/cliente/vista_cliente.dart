import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../core/widgets/tarjeta.dart';
import '../../domain/models/beneficio.dart';
import '../../domain/models/estudio.dart';
import '../../domain/models/segmento.dart';
import '../panel/vm_partida.dart';

/// Módulo 2 · Cliente.
///
/// Dos decisiones y una renuncia: a quién le hablas y qué le prometes. Todo lo
/// demás del simulador se juzga contra esta elección.
class VistaCliente extends StatelessWidget {
  const VistaCliente({super.key});

  @override
  Widget build(BuildContext context) {
    final VmPartida vm = AlcancePartida.de(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('2 · Cliente'),
        backgroundColor: Tema.cliente,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          const NotaConcepto(
            titulo: 'Segmentar es renunciar',
            texto:
                'Elegir un segmento objetivo no significa que los demás no te '
                'compren: significa que tu producto, tu precio, tus canales y '
                'tu campaña se optimizan para uno solo. Un producto promedio '
                'para el cliente promedio no le gusta del todo a nadie.',
          ),
          const SizedBox(height: 16),
          Text('Segmento objetivo',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...vm.mercado!.segmentos.map((Segmento s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OpcionSegmento(segmento: s, vm: vm),
              )),
          const SizedBox(height: 8),
          Text('Promesa de marca',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
              'Lo que tu comunicación declara. Es lo que atrae al cliente; el '
              'producto, en el módulo 3, es lo que lo retiene.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          _SelectorPromesa(vm: vm),
          const SizedBox(height: 12),
          _AvisoCoherencia(vm: vm),
        ],
      ),
    );
  }
}

class _OpcionSegmento extends StatelessWidget {
  const _OpcionSegmento({required this.segmento, required this.vm});

  final Segmento segmento;
  final VmPartida vm;

  @override
  Widget build(BuildContext context) {
    final bool elegido = vm.decisiones.segmentoObjetivo == segmento.id;
    final Hallazgo? perfil = vm.partida!.mejorHallazgo('perfil', segmento.id);
    final Hallazgo? tamano = vm.partida!.mejorHallazgo('tamano', '');
    final double? unidades = tamano?.valor('tamano:${segmento.id}');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => vm.fijarObjetivo(segmento.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elegido ? const Color(0xFFF7F1FE) : Tema.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: elegido ? Tema.cliente : Tema.borde,
              width: elegido ? 1.6 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              elegido
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: elegido ? Tema.cliente : Tema.textoSuave,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(segmento.nombre,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(segmento.descripcion,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: <Widget>[
                      _Etiqueta(
                        texto: unidades == null
                            ? 'Tamaño desconocido'
                            : '${Formato.compacto(unidades)} ${vm.mercado!.unidad}s',
                        alerta: unidades == null,
                      ),
                      _Etiqueta(
                        texto: perfil == null
                            ? 'Perfil sin investigar'
                            : 'Busca: ${Beneficio.values[(perfil.valor('beneficio') ?? 0).round()].etiqueta}',
                        alerta: perfil == null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.alerta});

  final String texto;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: alerta ? const Color(0xFFFDF3E7) : const Color(0xFFEFF4F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto,
          style: TextStyle(
              fontSize: 11,
              color: alerta ? Tema.advertencia : Tema.observacion,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _SelectorPromesa extends StatelessWidget {
  const _SelectorPromesa({required this.vm});

  final VmPartida vm;

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Beneficio que prometes',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Beneficio.values.map((Beneficio b) {
              final bool elegido = vm.decisiones.beneficioPrometido == b;
              return ChoiceChip(
                label: Text(b.etiqueta, style: const TextStyle(fontSize: 12)),
                selected: elegido,
                onSelected: (_) =>
                    vm.fijarPromesa(b, vm.decisiones.nivelPromesa),
                selectedColor: const Color(0xFFEDE0FA),
                side: BorderSide(color: elegido ? Tema.cliente : Tema.borde),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text('Nivel de la promesa',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Text('${vm.decisiones.nivelPromesa.toStringAsFixed(1)} / 5',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
            value: vm.decisiones.nivelPromesa,
            min: 1,
            max: 5,
            divisions: 8,
            activeColor: Tema.cliente,
            onChanged: (double v) =>
                vm.fijarPromesa(vm.decisiones.beneficioPrometido, v),
          ),
          Text(
              _descripcionNivel(vm.decisiones.nivelPromesa),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  static String _descripcionNivel(double nivel) {
    if (nivel <= 2) {
      return 'Comunicación de marca básica: funcional, sin pretensiones. Baja '
          'la expectativa, y por lo tanto es fácil de satisfacer.';
    }
    if (nivel <= 3.5) {
      return 'Promesa intermedia: una marca correcta, sin un argumento fuerte '
          'que la distinga.';
    }
    return 'Promesa premium: genera mucha expectativa. Si el producto no la '
        'sostiene, la satisfacción cae y la reputación se hunde.';
  }
}

class _AvisoCoherencia extends StatelessWidget {
  const _AvisoCoherencia({required this.vm});

  final VmPartida vm;

  @override
  Widget build(BuildContext context) {
    final Segmento? objetivo = vm.segmentoObjetivo;
    if (objetivo == null) return const SizedBox.shrink();
    final Hallazgo? perfil = vm.partida!.mejorHallazgo('perfil', objetivo.id);
    if (perfil == null) {
      return const NotaConcepto(
        texto:
            'No has investigado el perfil de este segmento, así que no hay '
            'forma de saber si la promesa que elegiste es la que busca. El '
            'módulo Mercado resuelve eso.',
      );
    }
    final Beneficio buscado =
        Beneficio.values[(perfil.valor('beneficio') ?? 0).round()];
    final bool coincide = buscado == vm.decisiones.beneficioPrometido;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: coincide ? const Color(0xFFEAF6F3) : const Color(0xFFFBEAEA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: coincide
                ? const Color(0xFFB6E0D6)
                : const Color(0xFFEFC0C0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(coincide ? Icons.check_circle_outline : Icons.error_outline,
              size: 18,
              color: coincide ? Tema.confirmacion : Tema.critica),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              coincide
                  ? 'Tu promesa coincide con lo que ${objetivo.nombre} busca. '
                      'Ese es el punto de partida de un buen posicionamiento.'
                  : '${objetivo.nombre} busca ${buscado.etiqueta.toLowerCase()} '
                      'y tú estás prometiendo '
                      '${vm.decisiones.beneficioPrometido.etiqueta.toLowerCase()}. '
                      'Fuera de esa intersección, la inversión publicitaria '
                      'trabaja en contra.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
