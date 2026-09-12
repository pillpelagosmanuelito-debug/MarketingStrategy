import 'package:flutter/material.dart';

import '../tema.dart';

/// Una serie del grafico.
class Serie {
  const Serie({
    required this.nombre,
    required this.valores,
    required this.color,
  });

  final String nombre;
  final List<double> valores;
  final Color color;
}

/// Grafico de lineas dibujado a mano.
///
/// Se dibuja con `CustomPainter` en vez de usar una libreria de graficos para
/// no agregar dependencias al proyecto: el simulador solo necesita lineas,
/// ejes y una cuadricula, y eso son cuarenta lineas de codigo.
class GraficoEvolucion extends StatelessWidget {
  const GraficoEvolucion({
    super.key,
    required this.series,
    this.altura = 170,
    this.minimoForzado,
    this.formatoEje,
  });

  final List<Serie> series;
  final double altura;
  final double? minimoForzado;
  final String Function(double)? formatoEje;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: altura,
          width: double.infinity,
          child: CustomPaint(
            painter: _PintorLineas(
              series: series,
              minimoForzado: minimoForzado,
              formatoEje: formatoEje ?? (double v) => v.toStringAsFixed(0),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: series
              .map((Serie s) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(width: 10, height: 3, color: s.color),
                      const SizedBox(width: 5),
                      Text(s.nombre,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _PintorLineas extends CustomPainter {
  _PintorLineas({
    required this.series,
    required this.minimoForzado,
    required this.formatoEje,
  });

  final List<Serie> series;
  final double? minimoForzado;
  final String Function(double) formatoEje;

  @override
  void paint(Canvas lienzo, Size tamano) {
    if (series.isEmpty) return;
    double maximo = double.negativeInfinity;
    double minimo = double.infinity;
    int puntos = 0;
    for (final Serie s in series) {
      puntos = s.valores.length > puntos ? s.valores.length : puntos;
      for (final double v in s.valores) {
        if (v > maximo) maximo = v;
        if (v < minimo) minimo = v;
      }
    }
    if (puntos == 0) return;
    if (minimoForzado != null && minimoForzado! < minimo) {
      minimo = minimoForzado!;
    }
    if (maximo == minimo) maximo = minimo + 1;
    final double rango = maximo - minimo;
    maximo += rango * 0.12;
    minimo -= rango * 0.12;

    const double margenIzq = 52;
    const double margenAbajo = 18;
    final double ancho = tamano.width - margenIzq;
    final double alto = tamano.height - margenAbajo;

    final Paint cuadricula = Paint()
      ..color = Tema.borde
      ..strokeWidth = 1;
    final TextPainter texto = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    for (int i = 0; i <= 3; i++) {
      final double y = alto * i / 3;
      lienzo.drawLine(
          Offset(margenIzq, y), Offset(tamano.width, y), cuadricula);
      final double valor = maximo - (maximo - minimo) * i / 3;
      texto.text = TextSpan(
        text: formatoEje(valor),
        style: const TextStyle(fontSize: 10, color: Tema.textoSuave),
      );
      texto.layout(minWidth: 0, maxWidth: margenIzq - 6);
      texto.paint(lienzo, Offset(margenIzq - 6 - texto.width, y - 6));
    }

    for (final Serie s in series) {
      if (s.valores.isEmpty) continue;
      final Path camino = Path();
      final Paint trazo = Paint()
        ..color = s.color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      for (int i = 0; i < s.valores.length; i++) {
        final double x = puntos == 1
            ? margenIzq + ancho / 2
            : margenIzq + ancho * i / (puntos - 1);
        final double y =
            alto - alto * ((s.valores[i] - minimo) / (maximo - minimo));
        if (i == 0) {
          camino.moveTo(x, y);
        } else {
          camino.lineTo(x, y);
        }
        lienzo.drawCircle(Offset(x, y), 3, Paint()..color = s.color);
      }
      lienzo.drawPath(camino, trazo);
    }

    for (int i = 0; i < puntos; i++) {
      final double x =
          puntos == 1 ? margenIzq + ancho / 2 : margenIzq + ancho * i / (puntos - 1);
      texto.text = TextSpan(
        text: 'P${i + 1}',
        style: const TextStyle(fontSize: 10, color: Tema.textoSuave),
      );
      texto.layout();
      texto.paint(lienzo, Offset(x - texto.width / 2, alto + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _PintorLineas anterior) => true;
}
