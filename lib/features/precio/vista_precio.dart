import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../core/widgets/metrica.dart';
import '../../core/widgets/tarjeta.dart';
import '../../domain/models/estudio.dart';
import '../../domain/models/segmento.dart';
import '../panel/vm_partida.dart';

/// Módulo 4 · Precio.
///
/// El precio se muestra siempre en tres lecturas simultáneas: contra el costo
/// (margen), contra la estructura (punto de equilibrio) y contra la referencia
/// del segmento (posición relativa). Las tres tienen que cerrar.
class VistaPrecio extends StatefulWidget {
  const VistaPrecio({super.key});

  @override
  State<VistaPrecio> createState() => _VistaPrecioState();
}

class _VistaPrecioState extends State<VistaPrecio> {
  @override
  Widget build(BuildContext context) {
    final VmPartida vm = AlcancePartida.de(context);
    final Segmento? objetivo = vm.segmentoObjetivo;
    final Hallazgo? pruebaPrecio = objetivo == null
        ? null
        : vm.partida!.mejorHallazgo('precio', objetivo.id);
    final double? referencia = pruebaPrecio?.valor('precioReferencia');
    // `clamp` sobre `num` devuelve `num` en Dart: hay que volver a `double`
    // explicitamente o el analizador rechaza la asignacion.
    final double maximo =
        (vm.costoUnitario * 8).clamp(1.0, 1000000.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('4 · Precio'),
        backgroundColor: Tema.precio,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          const NotaConcepto(
            titulo: 'El precio es un mensaje, no solo un número',
            texto:
                'El precio se juzga contra la referencia del segmento, no en '
                'soles absolutos. En segmentos que asocian precio con calidad, '
                'bajarlo demasiado no atrae: contradice la promesa y despierta '
                'desconfianza.',
          ),
          const SizedBox(height: 16),
          Tarjeta(
            titulo: 'Precio de venta al público',
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(Formato.solesExactos(vm.decisiones.precio),
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Tema.precio)),
                Slider(
                  value: vm.decisiones.precio.clamp(0.0, maximo).toDouble(),
                  min: 0,
                  max: maximo,
                  divisions: 200,
                  activeColor: Tema.precio,
                  onChanged: (double v) => vm.fijarPrecio(
                      double.parse(v.toStringAsFixed(2))),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('S/ 0', style: Theme.of(context).textTheme.bodySmall),
                    Text(Formato.solesExactos(maximo),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Tarjeta(
            titulo: 'Lectura 1 · Contra el costo',
            hijo: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Metrica(
                          etiqueta: 'Costo unitario',
                          valor: Formato.solesExactos(vm.costoUnitario)),
                    ),
                    Expanded(
                      child: Metrica(
                        etiqueta: 'Margen del canal',
                        valor:
                            Formato.porcentajeCorto(vm.margenCanalObjetivo),
                        nota: 'promedio ponderado',
                      ),
                    ),
                    Expanded(
                      child: Metrica(
                        etiqueta: 'Contribución',
                        valor:
                            Formato.solesExactos(vm.contribucionUnitaria),
                        color: vm.contribucionUnitaria <= 0
                            ? Tema.critica
                            : Tema.confirmacion,
                        nota: 'por unidad',
                      ),
                    ),
                  ],
                ),
                if (vm.contribucionUnitaria <= 0) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                      'Con contribución negativa, cada unidad vendida aumenta '
                      'la pérdida. No hay volumen que lo arregle.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Tema.critica)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Tarjeta(
            titulo: 'Lectura 2 · Contra tu estructura',
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Metrica(
                  etiqueta: 'Punto de equilibrio',
                  valor: vm.puntoEquilibrio.isFinite
                      ? '${Formato.compacto(vm.puntoEquilibrio)} ${vm.mercado!.unidad}s'
                      : 'Inalcanzable',
                  color: vm.puntoEquilibrio.isFinite ? null : Tema.critica,
                ),
                const SizedBox(height: 8),
                Text(
                    'Unidades que necesitas vender este periodo para cubrir '
                    'costo fijo (${Formato.soles(vm.mercado!.costoFijo)}), '
                    'canales (${Formato.soles(vm.decisiones.costoFijoCanales)}), '
                    'medios (${Formato.soles(vm.decisiones.gastoMedios)}) e '
                    'investigación (${Formato.soles(vm.decisiones.investigacion)}).',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Tarjeta(
            titulo: 'Lectura 3 · Contra el segmento objetivo',
            hijo: referencia == null
                ? Text(
                    objetivo == null
                        ? 'No has elegido segmento objetivo.'
                        : 'No has contratado la prueba de precio de '
                            '${objetivo.nombre}, así que no sabes contra qué '
                            'referencia te está comparando.',
                    style: Theme.of(context).textTheme.bodySmall)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      BarraValor(
                        etiqueta: 'Tu precio sobre la referencia estimada',
                        fraccion: (vm.decisiones.precio / referencia) / 2,
                        textoValor: Formato.porcentaje(
                            vm.decisiones.precio / referencia),
                        color: _colorRelativo(
                            vm.decisiones.precio / referencia),
                        detalle:
                            'Referencia estimada: ${Formato.solesExactos(referencia)} '
                            '(±${(pruebaPrecio!.error * 100).round()}%). '
                            'Sensibilidad al precio: '
                            '${(pruebaPrecio.valor('sensibilidad') ?? 0).toStringAsFixed(1)}.',
                      ),
                      const SizedBox(height: 8),
                      Text(_lecturaRelativa(vm.decisiones.precio / referencia,
                          pruebaPrecio.valor('sospechaPrecioBajo') ?? 0),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static Color _colorRelativo(double relativo) {
    if (relativo > 1.25) return Tema.advertencia;
    if (relativo < 0.72) return Tema.advertencia;
    return Tema.confirmacion;
  }

  static String _lecturaRelativa(double relativo, double sospecha) {
    if (relativo > 1.25) {
      return 'Estás más de 25% por encima de la referencia. Solo se sostiene '
          'si la promesa y la marca justifican la diferencia.';
    }
    if (relativo < 0.72 && sospecha > 1.2) {
      return 'Estás muy por debajo de la referencia en un segmento que asocia '
          'precio con calidad: el precio bajo va a jugar en contra de tu '
          'promesa.';
    }
    if (relativo < 0.85) {
      return 'Precio de penetración: ganas atractivo, pero revisa que el '
          'margen aguante el volumen que necesitas.';
    }
    return 'Estás dentro del rango que el segmento considera normal.';
  }
}
