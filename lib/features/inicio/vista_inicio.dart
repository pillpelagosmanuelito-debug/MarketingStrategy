import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../core/widgets/tarjeta.dart';
import '../../data/catalogo_mercados.dart';
import '../../data/repositorio_partida.dart';
import '../../domain/models/mercado.dart';
import '../conceptos/vista_conceptos.dart';
import '../panel/vm_partida.dart';

/// Pantalla de entrada: elegir mercado y nombrar la marca.
class VistaInicio extends StatelessWidget {
  const VistaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final VmPartida vm = AlcancePartida.de(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 40),
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Tema.primario,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('MSL',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Marketing Strategy Lab',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const Text(
                          'Simulador de decisiones comerciales',
                          style: TextStyle(color: Tema.textoSuave, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const NotaConcepto(
              titulo: 'Cómo funciona',
              texto:
                  'Diriges una marca durante ocho periodos. En cada uno decides '
                  'a qué segmento te diriges, qué prometes, qué producto '
                  'entregas, a qué precio, en qué canales y con qué medios. '
                  'Nadie te dice qué quiere cada segmento: esa información se '
                  'compra, cuesta dinero y viene con error de muestreo. Al '
                  'final se evalúan cuatro competencias: segmentación, '
                  'investigación de mercado, estrategia comercial y '
                  'posicionamiento.',
            ),
            const SizedBox(height: 22),
            Text('Elige un mercado',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
                'Los tres escenarios premian estrategias distintas. Ninguno se '
                'gana con la misma receta.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            ...CatalogoMercados.todos.map(
              (Mercado m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TarjetaMercado(mercado: m),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                    builder: (_) => const VistaConceptos()),
              ),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Conceptos de marketing usados en el simulador'),
            ),
            const SizedBox(height: 18),
            FutureBuilder<List<ResumenPartida>>(
              future: vm.historialPartidas(),
              builder: (BuildContext contexto,
                  AsyncSnapshot<List<ResumenPartida>> snap) {
                final List<ResumenPartida> lista =
                    snap.data ?? <ResumenPartida>[];
                if (lista.isEmpty) return const SizedBox.shrink();
                return Tarjeta(
                  titulo: 'Partidas anteriores',
                  hijo: Column(
                    children: lista
                        .take(5)
                        .map((ResumenPartida r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text('${r.marca} · ${r.mercadoNombre}',
                                            style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600)),
                                        Text(
                                            '${Formato.soles(r.utilidad)} de '
                                            'utilidad acumulada'
                                            '${r.quiebra ? ' · quiebra' : ''}',
                                            style: Theme.of(contexto)
                                                .textTheme
                                                .bodySmall),
                                      ],
                                    ),
                                  ),
                                  Text('${r.puntaje.round()}',
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Tema.primario)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaMercado extends StatelessWidget {
  const _TarjetaMercado({required this.mercado});

  final Mercado mercado;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _preguntarMarca(context),
      child: Tarjeta(
        hijo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(mercado.nombre,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Tema.fondo,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Tema.borde),
                  ),
                  child: Text(mercado.categoria,
                      style: const TextStyle(
                          fontSize: 11, color: Tema.textoSuave)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(mercado.contexto,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _Dato(
                    etiqueta: 'Segmentos',
                    valor: '${mercado.segmentos.length}'),
                _Dato(etiqueta: 'Periodos', valor: '${mercado.periodos}'),
                _Dato(
                    etiqueta: 'Caja inicial',
                    valor: Formato.compacto(mercado.cajaInicial)),
                _Dato(
                    etiqueta: 'Competidores',
                    valor: '${mercado.competidoresBase.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _preguntarMarca(BuildContext context) {
    final TextEditingController controlador =
        TextEditingController(text: 'Mi marca');
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogo) => AlertDialog(
        title: const Text('Nombre de tu marca'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
                'Vas a competir en ${mercado.nombre} durante '
                '${mercado.periodos} periodos.',
                style: Theme.of(dialogo).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: controlador,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final VmPartida vm = AlcancePartida.de(context);
              Navigator.of(dialogo).pop();
              await vm.nuevaPartida(mercado, controlador.text);
            },
            child: const Text('Empezar'),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(valor,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text(etiqueta,
              style: const TextStyle(fontSize: 11, color: Tema.textoSuave)),
        ],
      ),
    );
  }
}
