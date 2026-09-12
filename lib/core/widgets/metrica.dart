import 'package:flutter/material.dart';

import '../tema.dart';

/// Indicador numerico con etiqueta y, si corresponde, variacion respecto al
/// periodo anterior.
class Metrica extends StatelessWidget {
  const Metrica({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.variacion,
    this.color,
    this.nota,
  });

  final String etiqueta;
  final String valor;

  /// Variacion relativa respecto al periodo anterior (0.12 = +12%).
  final double? variacion;
  final Color? color;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(etiqueta.toUpperCase(),
            style: const TextStyle(
                fontSize: 10.5,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: Tema.textoSuave)),
        const SizedBox(height: 4),
        Text(valor,
            style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: color ?? Tema.texto)),
        if (variacion != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            '${variacion! >= 0 ? '▲' : '▼'} '
            '${(variacion!.abs() * 100).toStringAsFixed(1)}%',
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: variacion! >= 0 ? Tema.confirmacion : Tema.critica),
          ),
        ],
        if (nota != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(nota!,
              style: const TextStyle(fontSize: 11, color: Tema.textoSuave)),
        ],
      ],
    );
  }
}

/// Barra horizontal para comparar proporciones (participacion, afinidad,
/// cobertura). Siempre acompanada del numero: la barra ayuda a comparar, el
/// numero es el dato.
class BarraValor extends StatelessWidget {
  const BarraValor({
    super.key,
    required this.etiqueta,
    required this.fraccion,
    required this.textoValor,
    this.color,
    this.detalle,
  });

  final String etiqueta;
  final double fraccion;
  final String textoValor;
  final Color? color;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final double f = fraccion.isNaN
        ? 0.0
        : fraccion < 0
            ? 0.0
            : fraccion > 1
                ? 1.0
                : fraccion;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(etiqueta,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              Text(textoValor,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: f,
              minHeight: 7,
              backgroundColor: Tema.borde,
              valueColor:
                  AlwaysStoppedAnimation<Color>(color ?? Tema.primarioClaro),
            ),
          ),
          if (detalle != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(detalle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
