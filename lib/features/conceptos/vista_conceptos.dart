import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../../core/widgets/tarjeta.dart';

/// Glosario de los conceptos que el simulador pone en juego.
///
/// No es un manual de marketing: son los seis conceptos que el motor modela y
/// que el estudiante necesita para interpretar lo que le pasa. Todo lo demás
/// se aprende jugando, que es el punto de la aplicación.
class VistaConceptos extends StatelessWidget {
  const VistaConceptos({super.key});

  static const List<_Concepto> _conceptos = <_Concepto>[
    _Concepto(
      titulo: 'Segmentación',
      resumen:
          'Dividir el mercado en grupos que deciden de forma distinta y elegir '
          'uno.',
      cuerpo:
          'Un segmento no es un grupo demográfico: es un grupo que decide con '
          'los mismos criterios. En el simulador cada segmento tiene un '
          'beneficio que busca, un precio que considera normal, medios que '
          'consume y canales donde compra.\n\n'
          'Segmentar obliga a renunciar. Si la mezcla comercial intenta '
          'satisfacer a los cuatro segmentos a la vez, termina en un promedio '
          'que no le resulta atractivo a ninguno y que además cuesta más, '
          'porque exige estar en todos los canales y en todos los medios.',
    ),
    _Concepto(
      titulo: 'Investigación de mercado',
      resumen: 'Comprar información cuando reduce la incertidumbre que importa.',
      cuerpo:
          'Los estudios no producen ventas: evitan errores de puntería. Cada '
          'estudio devuelve una estimación con error de muestreo, nunca el '
          'valor exacto, y repetirlo reduce el error a la mitad al mismo '
          'costo.\n\n'
          'De ahí salen las dos formas de equivocarse: decidir sin datos, y '
          'gastar en precisión que ya no cambia ninguna decisión. La pregunta '
          'correcta antes de contratar un estudio es "¿qué haría distinto si '
          'el resultado fuera otro?". Si la respuesta es "nada", el estudio no '
          'se paga.',
    ),
    _Concepto(
      titulo: 'Posicionamiento',
      resumen:
          'El lugar reconocible que la marca ocupa en la mente de un segmento.',
      cuerpo:
          'El posicionamiento se compone de tres decisiones: a quién le hablas '
          '(segmento objetivo), qué le prometes (beneficio) y con cuánta '
          'ambición (nivel de promesa).\n\n'
          'La promesa atrae; el producto retiene. La distancia entre ambos es '
          'la satisfacción. Por eso prometer más de lo que se entrega no es '
          'una exageración inofensiva: sube la expectativa, baja la '
          'satisfacción, hunde la reputación y acelera el olvido de la marca.\n\n'
          'La claridad se construye repitiendo: cada periodo sosteniendo el '
          'mismo posicionamiento la aumenta, y un cambio de posicionamiento la '
          'reduce a poco más de la mitad.',
    ),
    _Concepto(
      titulo: 'Mezcla comercial',
      resumen: 'Producto, precio, canales y comunicación como un solo sistema.',
      cuerpo:
          'Las cuatro decisiones no se evalúan por separado. El precio se lee '
          'contra el costo, contra la estructura de costos fijos y contra la '
          'referencia del segmento. El canal aporta cobertura pero retiene '
          'margen y cobra por estar. El medio solo alcanza al segmento si '
          'existe afinidad.\n\n'
          'Una mezcla es coherente cuando las cuatro decisiones apuntan al '
          'mismo segmento y a la misma promesa. Cuando no lo hacen, cada '
          'decisión desarma a la anterior.',
    ),
    _Concepto(
      titulo: 'Participación de mercado',
      resumen: 'Cuánto del total vendido corresponde a tu marca.',
      cuerpo:
          'La participación mide posición competitiva, no salud del negocio. '
          'Se puede comprar participación bajando el precio por debajo del '
          'costo, y eso no es una victoria: es financiar al cliente.\n\n'
          'Por eso el simulador evalúa la participación junto con el margen y '
          'la sostenibilidad: crecer perdiendo plata en cada unidad solo '
          'adelanta la quiebra.',
    ),
    _Concepto(
      titulo: 'Recuerdo de marca y boca a boca',
      resumen: 'Un activo que se deprecia todos los periodos.',
      cuerpo:
          'El recuerdo de marca cae 15% por periodo aunque no se haga nada '
          'mal: sostenerlo cuesta todos los periodos, no solo el del '
          'lanzamiento. La inversión en medios lo repone, pero con '
          'rendimientos decrecientes: duplicar la inversión no duplica el '
          'alcance.\n\n'
          'La satisfacción lo modifica en las dos direcciones. Por encima de '
          '72%, el boca a boca positivo instala marca sin pagarla; por debajo '
          'de 45%, la marca se olvida más rápido de lo que la publicidad la '
          'repone, y es el único caso en el que invertir más en medios puede '
          'empeorar el resultado.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conceptos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          const NotaConcepto(
            texto:
                'Estos son los seis conceptos que el motor de simulación '
                'modela explícitamente. Si entiendes cómo funcionan, puedes '
                'anticipar lo que va a pasar con tus decisiones.',
          ),
          const SizedBox(height: 14),
          ..._conceptos.map((_Concepto c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Tema.superficie,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Tema.borde),
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      title: Text(c.titulo,
                          style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(c.resumen,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      children: <Widget>[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(c.cuerpo,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _Concepto {
  const _Concepto({
    required this.titulo,
    required this.resumen,
    required this.cuerpo,
  });

  final String titulo;
  final String resumen;
  final String cuerpo;
}
