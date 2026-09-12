import 'package:flutter/material.dart';

import '../tema.dart';

/// Contenedor estandar de la aplicacion: un bloque con titulo opcional.
class Tarjeta extends StatelessWidget {
  const Tarjeta({
    super.key,
    required this.hijo,
    this.titulo,
    this.subtitulo,
    this.color,
    this.accion,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget hijo;
  final String? titulo;
  final String? subtitulo;
  final Color? color;
  final Widget? accion;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Tema.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Tema.borde),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (titulo != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        titulo!,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: color ?? Tema.texto),
                      ),
                      if (subtitulo != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(subtitulo!,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                if (accion != null) accion!,
              ],
            ),
          if (titulo != null) const SizedBox(height: 12),
          hijo,
        ],
      ),
    );
  }
}

/// Bloque de texto explicativo. Se usa para el "por que" de cada modulo: la
/// aplicacion ensena marketing, no solo lo simula.
class NotaConcepto extends StatelessWidget {
  const NotaConcepto({super.key, required this.texto, this.titulo});

  final String texto;
  final String? titulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4F5),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Tema.primarioClaro, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (titulo != null) ...<Widget>[
            Text(titulo!,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Tema.primario)),
            const SizedBox(height: 6),
          ],
          Text(texto, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
