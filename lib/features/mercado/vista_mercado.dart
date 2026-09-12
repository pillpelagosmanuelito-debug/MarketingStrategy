import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../core/widgets/metrica.dart';
import '../../core/widgets/tarjeta.dart';
import '../../domain/models/beneficio.dart';
import '../../domain/models/canal.dart';
import '../../domain/models/estudio.dart';
import '../../domain/models/medio.dart';
import '../../domain/models/segmento.dart';
import '../panel/vm_partida.dart';

/// Módulo 1 · Mercado.
///
/// Aquí se compra información. Es el único módulo que no cambia el resultado
/// del periodo por sí mismo: solo cambia lo que el estudiante sabe cuando
/// decide en los otros cuatro.
class VistaMercado extends StatelessWidget {
  const VistaMercado({super.key});

  @override
  Widget build(BuildContext context) {
    final VmPartida vm = AlcancePartida.de(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('1 · Mercado'),
        backgroundColor: Tema.mercado,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          const NotaConcepto(
            titulo: 'Investigación de mercado',
            texto:
                'Un estudio no vende: evita errores de puntería. Cada estudio '
                'entrega una estimación con error de muestreo, nunca el valor '
                'exacto. Repetir el mismo estudio reduce el error a la mitad, '
                'pero cuesta lo mismo cada vez: la tercera medición casi nunca '
                'se paga.',
          ),
          const SizedBox(height: 14),
          Tarjeta(
            titulo: 'Presupuesto',
            hijo: Row(
              children: <Widget>[
                Expanded(
                  child: Metrica(
                      etiqueta: 'Caja',
                      valor: Formato.soles(vm.caja)),
                ),
                Expanded(
                  child: Metrica(
                      etiqueta: 'Gastado en estudios',
                      valor: Formato.soles(vm.decisiones.investigacion),
                      nota: 'este periodo'),
                ),
                Expanded(
                  child: Metrica(
                      etiqueta: 'Disponible',
                      valor: Formato.soles(vm.disponible),
                      color: vm.disponible < 0 ? Tema.critica : null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Segmentos de la categoría',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
              'Los nombres y la descripción son información pública. Todo lo '
              'demás se investiga.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          ...vm.mercado!.segmentos.map((Segmento s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FichaSegmento(segmento: s, vm: vm),
              )),
          const SizedBox(height: 8),
          Text('Estudios generales',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...vm.estudiosDisponibles
              .where((Estudio e) => !e.porSegmento)
              .map((Estudio e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TarjetaEstudio(estudio: e, segmentoId: '', vm: vm),
                  )),
        ],
      ),
    );
  }
}

class _FichaSegmento extends StatelessWidget {
  const _FichaSegmento({required this.segmento, required this.vm});

  final Segmento segmento;
  final VmPartida vm;

  @override
  Widget build(BuildContext context) {
    final bool esObjetivo =
        vm.decisiones.segmentoObjetivo == segmento.id;
    return Tarjeta(
      titulo: segmento.nombre,
      subtitulo: segmento.descripcion,
      color: esObjetivo ? Tema.cliente : null,
      accion: esObjetivo
          ? const Chip(
              label: Text('Objetivo', style: TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
              backgroundColor: Color(0xFFF1E7FB),
              side: BorderSide(color: Color(0xFFD9C2F0)),
            )
          : null,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DatosConocidos(segmento: segmento, vm: vm),
          const SizedBox(height: 10),
          ...vm.estudiosDisponibles
              .where((Estudio e) => e.porSegmento)
              .map((Estudio e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TarjetaEstudio(
                        estudio: e, segmentoId: segmento.id, vm: vm),
                  )),
        ],
      ),
    );
  }
}

/// Muestra únicamente lo que los estudios ya revelaron. Sin estudios, no hay
/// números: esa es la mecánica central del módulo.
class _DatosConocidos extends StatelessWidget {
  const _DatosConocidos({required this.segmento, required this.vm});

  final Segmento segmento;
  final VmPartida vm;

  @override
  Widget build(BuildContext context) {
    final Hallazgo? tamano = vm.partida!.mejorHallazgo('tamano', '');
    final Hallazgo? perfil = vm.partida!.mejorHallazgo('perfil', segmento.id);
    final Hallazgo? precio = vm.partida!.mejorHallazgo('precio', segmento.id);
    final Hallazgo? canales = vm.partida!.mejorHallazgo('canales', segmento.id);
    final Hallazgo? medios = vm.partida!.mejorHallazgo('medios', segmento.id);

    final List<Widget> filas = <Widget>[];

    if (tamano != null) {
      final double? v = tamano.valor('tamano:${segmento.id}');
      if (v != null) {
        filas.add(_Dato(
            'Tamaño estimado',
            '${Formato.compacto(v)} ${vm.mercado!.unidad}s por periodo',
            tamano.error));
      }
    }
    if (perfil != null) {
      final double? indice = perfil.valor('beneficio');
      if (indice != null) {
        filas.add(_Dato('Beneficio que busca',
            Beneficio.values[indice.round()].etiqueta, 0));
      }
      filas.add(_Dato(
          'Pesos de decisión',
          'Calidad ${Formato.porcentajeCorto(perfil.valor('pesoCalidad') ?? 0)} · '
              'Beneficio ${Formato.porcentajeCorto(perfil.valor('pesoBeneficio') ?? 0)} · '
              'Marca ${Formato.porcentajeCorto(perfil.valor('pesoMarca') ?? 0)} · '
              'Variedad ${Formato.porcentajeCorto(perfil.valor('pesoVariedad') ?? 0)}',
          perfil.error));
      filas.add(_Dato(
          'Exigencia de calidad',
          '${(perfil.valor('exigencia') ?? 0).toStringAsFixed(1)} de 5 · '
              'lealtad ${Formato.porcentajeCorto(perfil.valor('lealtad') ?? 0)}',
          perfil.error));
    }
    if (precio != null) {
      filas.add(_Dato(
          'Precio de referencia',
          '${Formato.solesExactos(precio.valor('precioReferencia') ?? 0)} · '
              'sensibilidad ${(precio.valor('sensibilidad') ?? 0).toStringAsFixed(1)}',
          precio.error));
    }
    if (canales != null) {
      final List<String> partes = <String>[];
      for (final Canal c in Canal.values) {
        final double v = canales.valor('canal:${c.id}') ?? 0;
        if (v >= 0.20) {
          partes.add('${c.etiqueta} ${Formato.porcentajeCorto(v)}');
        }
      }
      filas.add(_Dato('Dónde compra',
          partes.isEmpty ? 'Sin canal relevante' : partes.join(' · '),
          canales.error));
    }
    if (medios != null) {
      final List<String> partes = <String>[];
      for (final Medio m in Medio.values) {
        final double v = medios.valor('medio:${m.id}') ?? 0;
        if (v >= 0.25) {
          partes.add('${m.etiqueta} ${Formato.porcentajeCorto(v)}');
        }
      }
      filas.add(_Dato('Qué medios consume',
          partes.isEmpty ? 'Sin medio destacado' : partes.join(' · '),
          medios.error));
    }

    if (filas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Tema.fondo,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Tema.borde),
        ),
        child: Text(
            'No tienes ningún dato numérico de este segmento. Todo lo que '
            'decidas sobre él será una suposición.',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return Column(children: filas);
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor, this.error);

  final String etiqueta;
  final String valor;
  final double error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(etiqueta,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Tema.textoSuave)),
              if (error > 0) ...<Widget>[
                const SizedBox(width: 6),
                Text('±${(error * 100).round()}%',
                    style: const TextStyle(
                        fontSize: 10.5, color: Tema.advertencia)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(valor, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _TarjetaEstudio extends StatelessWidget {
  const _TarjetaEstudio({
    required this.estudio,
    required this.segmentoId,
    required this.vm,
  });

  final Estudio estudio;
  final String segmentoId;
  final VmPartida vm;

  @override
  Widget build(BuildContext context) {
    final int veces = vm.partida!.repeticionesDe(estudio.id, segmentoId);
    final bool puede = vm.puedeContratar(estudio);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Tema.fondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Tema.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(estudio.nombre,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(estudio.descripcion,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 5),
                Text(
                  veces == 0
                      ? 'Error de la primera medición: ±'
                          '${(estudio.errorBase * 100).round()}%'
                      : 'Contratado $veces vez/veces · próxima medición ±'
                          '${(_errorSiguiente(estudio, veces) * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11.5, color: Tema.mercado),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: <Widget>[
              Text(Formato.soles(estudio.costo),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Tema.mercado,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12.5),
                ),
                onPressed: puede ? () => _contratar(context) : null,
                child: Text(veces == 0 ? 'Contratar' : 'Repetir'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static double _errorSiguiente(Estudio e, int veces) {
    double error = e.errorBase;
    for (int i = 0; i < veces; i++) {
      error = error / 2.0;
    }
    return error;
  }

  void _contratar(BuildContext context) {
    final Hallazgo hallazgo = vm.contratar(estudio, segmentoId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext contexto) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(estudio.nombre,
                style: Theme.of(contexto).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
                'Medición ${hallazgo.repeticion} · error de muestreo ±'
                '${(hallazgo.error * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12, color: Tema.advertencia)),
            const SizedBox(height: 14),
            ...hallazgo.notas.map((String n) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(n,
                      style: Theme.of(contexto).textTheme.bodyMedium),
                )),
            const SizedBox(height: 8),
            Text(
                'Los resultados quedan registrados en la ficha del segmento y '
                'el analista ya puede usarlos.',
                style: Theme.of(contexto).textTheme.bodySmall),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(contexto).pop(),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
