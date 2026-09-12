# -*- coding: utf-8 -*-
"""Genera lib/data/catalogo_mercados.dart a partir del prototipo calibrado.

Se genera en vez de transcribirse para que no exista ninguna posibilidad de
que los numeros del simulador se separen de los numeros con los que se calibro.
"""
from mercados import MERCADOS

MEDIO_DART = {
    "tv": "Medio.tv", "radio": "Medio.radio", "digital": "Medio.digital",
    "influencers": "Medio.influencers", "punto_venta": "Medio.puntoVenta",
}
CANAL_DART = {
    "retail": "Canal.retail", "bodegas": "Canal.bodegas",
    "marketplace": "Canal.marketplace", "propio": "Canal.propio",
    "mayorista": "Canal.mayorista",
}
BEN_DART = {
    "salud": "Beneficio.salud", "energia": "Beneficio.energia",
    "precio": "Beneficio.precio", "estatus": "Beneficio.estatus",
    "rendimiento": "Beneficio.rendimiento",
    "flexibilidad": "Beneficio.flexibilidad",
}
POL_DART = {
    "lider_masivo": "PoliticaCompetidor.liderMasivo",
    "premium": "PoliticaCompetidor.premium",
    "retador": "PoliticaCompetidor.retador",
}

TEXTOS = {
    "bebida": {
        "unidad": "botella",
        "declarado": "2000000.0",
        "contexto":
            "Vas a dirigir una marca nueva de bebida funcional embotellada en "
            "el mercado peruano. La categoría mueve alrededor de dos millones "
            "de botellas por trimestre y ya tiene dos marcas instaladas: Selva "
            "Pura, líder en volumen, con precio bajo y presencia en bodegas de "
            "todo el país, y VitalPlus, una marca intermedia. Tienes ocho "
            "trimestres y una caja inicial de S/ 600,000. Nadie te va a decir "
            "quién compra qué: eso lo averiguas tú.",
        "leccion":
            "En una categoría donde el líder ya domina el segmento masivo con "
            "una estructura de costos que no puedes igualar, pelear por volumen "
            "es jugar su partido. Los segmentos de alto valor (deportistas y "
            "jóvenes que compran imagen) son pequeños, pero pagan más del doble "
            "por botella y no le interesan al líder. La estrategia que más "
            "utilidad genera aquí es enfocarse en uno de ellos y ser "
            "reconocible; la que menos, tratar de gustarle a todos.",
        "segmentos": {
            "fitness":
                "Entrena de tres a seis veces por semana, lee etiquetas y "
                "compara fórmulas. Compra en tienda especializada, retail "
                "moderno y en línea. Paga más si cree que el producto "
                "funciona.",
            "oficina":
                "Compra rápido y cerca del trabajo. Busca algo que lo mantenga "
                "despierto en la tarde. Decide frente a la refrigeradora, no "
                "en casa.",
            "familia":
                "Compra para varios, en cantidad, en bodega o mayorista. Mira "
                "el precio por unidad y el tamaño del envase antes que "
                "cualquier otra cosa.",
            "joven":
                "Entre 18 y 26 años. La marca importa tanto como el producto: "
                "es algo que se muestra. Descubre marcas en redes y por "
                "recomendación de la gente que sigue.",
        },
    },
    "mochilas": {
        "unidad": "mochila",
        "declarado": "170000.0",
        "contexto":
            "Tomas la dirección comercial de una fábrica nacional de mochilas. "
            "El mercado se concentra en la campaña escolar y está partido en "
            "dos mundos que casi no se tocan: familias que compran por precio "
            "en mercados y mayoristas, y compradores urbanos que pagan tres "
            "veces más por diseño o durabilidad. Andes Gear ya es fuerte en la "
            "parte alta. Tienes ocho periodos y S/ 700,000 de caja.",
        "leccion":
            "Aquí la aritmética manda: los dos segmentos de precio suman más de "
            "cuatro veces el volumen de los dos segmentos premium, y el costo "
            "unitario baja con el volumen. Una estrategia de penetración "
            "(precio bajo, línea amplia, mayoristas y radio) genera varias "
            "veces la utilidad de una estrategia premium bien ejecutada. El "
            "error caro es copiar el manual de la marca premium en un mercado "
            "cuyo peso está abajo.",
        "segmentos": {
            "publico":
                "Compra una mochila al año, en campaña, con presupuesto "
                "cerrado. Decide en el mercado o en la bodega del barrio, "
                "comparando precio y tamaño.",
            "provincia":
                "Compra a través de comercios abastecidos por mayoristas. "
                "Escucha radio local. El precio manda y la marca casi no "
                "existe.",
            "privado":
                "Le preocupa la espalda de su hijo y la duración del producto. "
                "Busca información antes de comprar y no le molesta pagar más "
                "si el argumento es creíble.",
            "universitario":
                "Compra para sí mismo. El diseño y lo que la mochila dice de "
                "él pesan más que la durabilidad. Descubre y compra en línea.",
        },
    },
    "academia": {
        "unidad": "matrícula",
        "declarado": "50000.0",
        "contexto":
            "Lanzas una academia preuniversitaria en línea. Academia Alfa lleva "
            "años siendo la referencia entre los postulantes a tiempo completo "
            "y tiene el recuerdo de marca más alto del mercado. Éxito Online "
            "compite por precio. Quedan segmentos que nadie atiende bien. Ocho "
            "periodos, S/ 550,000 de caja inicial.",
        "leccion":
            "El segmento obvio, el postulante a tiempo completo, ya tiene "
            "dueño: Alfa llega con más recuerdo de marca, más reputación y un "
            "posicionamiento nítido, y defiende su territorio apenas le quitas "
            "participación. El segmento que estudia mientras trabaja es más "
            "grande, está desatendido y valora algo que Alfa no ofrece. Además, "
            "esta partida muestra algo incómodo: reposicionar a mitad de camino "
            "cuesta credibilidad y casi nunca recupera la ventaja de haber "
            "elegido bien desde el principio.",
        "segmentos": {
            "postulante":
                "Estudia todo el día para ingresar a una universidad "
                "específica. Compara resultados de ingreso antes de "
                "matricularse. Es el segmento más visible y el más disputado.",
            "trabajador":
                "Trabaja y estudia. Necesita clases grabadas, horarios "
                "flexibles y poder avanzar a su ritmo. No puede asistir a una "
                "hora fija.",
            "escolar":
                "Todavía está en el colegio; los padres deciden y pagan. Pesa "
                "el prestigio de la institución y el acompañamiento.",
            "repitente":
                "Ya postuló antes. Presupuesto ajustado, decide por precio y "
                "por la posibilidad de pagar en partes.",
        },
    },
}

REFERENCIAS = {
    "bebida": "5300000.0",
    "mochilas": "8100000.0",
    "academia": "3100000.0",
}

EVENTOS = {
    ("bebida", 2): (
        "Sube el precio del insumo importado",
        "El concentrado de fruta sube 12%. El costo unitario aumenta para "
        "todas las marcas de la categoría."),
    ("bebida", 3): (
        "VitalPlus contraataca",
        "VitalPlus baja su precio 8% y sube su inversión en medios 25%."),
    ("bebida", 5): (
        "Ola de consumo saludable",
        "El segmento Deportista urbano crece 15% por la tendencia de "
        "bienestar."),
    ("mochilas", 1): (
        "Campaña escolar",
        "La demanda de Padres de colegio público crece 25% por el inicio de "
        "clases."),
    ("mochilas", 4): (
        "Kuma entra en guerra de precios",
        "Kuma baja su precio 10% y sube 30% su presencia en radio y "
        "televisión."),
    ("mochilas", 6): (
        "Alza del flete internacional",
        "El costo de importación sube 10% y golpea el costo unitario."),
    ("academia", 3): (
        "Academia Alfa lanza una ofensiva",
        "Alfa baja su precio 20%, mejora su servicio y triplica su inversión "
        "digital sobre el segmento de postulantes a tiempo completo."),
    ("academia", 5): (
        "Crece el estudio en paralelo al trabajo",
        "El segmento Trabajador que estudia crece 20%."),
    ("academia", 6): (
        "Sube el costo de la plataforma",
        "El proveedor de video en vivo sube su tarifa 8%."),
}


def d(v):
    return f"{float(v)}"


NOMBRES = {
    "publico": "Padres de colegio público",
    "academia": "Academia preuniversitaria en línea",
    "exito": "Éxito Online",
}


def nom(clave, defecto):
    return NOMBRES.get(clave, defecto)


def emitir_segmento(m, s):
    txt = TEXTOS[m.id]["segmentos"][s.id]
    medios = ", ".join(
        f"{MEDIO_DART[k]}: {d(v)}" for k, v in s.afinidad_medio.items())
    canales = ", ".join(
        f"{CANAL_DART[k]}: {d(v)}" for k, v in s.afinidad_canal.items())
    return f"""      Segmento(
        id: '{s.id}',
        nombre: '{nom(s.id, s.nombre)}',
        descripcion:
            '{txt}',
        tamano: {d(s.tamano)},
        precioReferencia: {d(s.precio_ref)},
        sensibilidad: {d(s.sensibilidad)},
        pesoCalidad: {d(s.peso_calidad)},
        pesoBeneficio: {d(s.peso_beneficio)},
        pesoMarca: {d(s.peso_marca)},
        pesoVariedad: {d(s.peso_variedad)},
        beneficio: {BEN_DART[s.beneficio]},
        exigencia: {d(s.exigencia)},
        lealtad: {d(s.lealtad)},
        sospechaPrecioBajo: {d(s.sospecha_precio_bajo)},
        afinidadMedio: <Medio, double>{{{medios}}},
        afinidadCanal: <Canal, double>{{{canales}}},
      ),
"""


def emitir_decisiones(dec, indent="          "):
    medios = ", ".join(
        f"{MEDIO_DART[k]}: {d(v)}" for k, v in dec.medios.items() if v > 0)
    canales = ", ".join(CANAL_DART[c] for c in dec.canales)
    i = indent
    return (
        f"{i}segmentoObjetivo: '{dec.segmento_objetivo}',\n"
        f"{i}beneficioPrometido: {BEN_DART[dec.beneficio_prometido]},\n"
        f"{i}nivelPromesa: {d(dec.nivel_promesa)},\n"
        f"{i}calidad: {d(dec.calidad)},\n"
        f"{i}beneficioReal: {BEN_DART[dec.beneficio_real]},\n"
        f"{i}amplitud: {dec.amplitud},\n"
        f"{i}precio: {d(dec.precio)},\n"
        f"{i}canales: <Canal>{{{canales}}},\n"
        f"{i}medios: <Medio, double>{{{medios}}},\n"
    )


def emitir_competidor(m, c):
    aw = ", ".join(
        f"'{s.id}': {d(c.estado.awareness[s.id])}" for s in m.segmentos)
    return f"""      Competidor(
        id: '{c.id}',
        nombre: '{nom(c.id, c.nombre)}',
        politica: {POL_DART[c.politica]},
        decisiones: Decisiones(
{emitir_decisiones(c.decisiones)}        ),
        estado: EstadoMarca(
          awareness: <String, double>{{{aw}}},
          reputacion: {d(c.estado.reputacion)},
          claridad: {d(c.estado.claridad)},
        ),
      ),
"""


def emitir_evento(m, e):
    return f"""      Evento(
        periodo: {e.periodo},
        titulo: '{EVENTOS[(m.id, e.periodo)][0]}',
        descripcion:
            '{EVENTOS[(m.id, e.periodo)][1]}',
        competidor: '{e.competidor}',
        cambioPrecio: {d(e.cambio_precio)},
        cambioMedios: {d(e.cambio_medios)},
        cambioCalidad: {d(e.cambio_calidad)},
        factorCosto: {d(e.factor_costo)},
        segmento: '{e.segmento}',
        factorTamano: {d(e.factor_tamano)},
      ),
"""


def emitir_mercado(m):
    t = TEXTOS[m.id]
    segs = "".join(emitir_segmento(m, s) for s in m.segmentos)
    comps = "".join(emitir_competidor(m, c) for c in m.competidores_base)
    evs = "".join(emitir_evento(m, e) for e in m.eventos)
    return f"""  static final Mercado {m.id} = Mercado(
    id: '{m.id}',
    nombre: '{nom(m.id, m.nombre)}',
    categoria: '{m.categoria}',
    unidad: '{t["unidad"]}',
    tamanoDeclarado: {t["declarado"]},
    contexto:
        '{t["contexto"]}',
    leccion:
        '{t["leccion"]}',
    costoBase: {d(m.costo_base)},
    costoFijo: {d(m.costo_fijo)},
    cajaInicial: {d(m.caja_inicial)},
    limiteSobregiro: {d(m.limite_sobregiro)},
    periodos: {m.periodos},
    utilidadReferencia: {REFERENCIAS[m.id]},
    segmentos: <Segmento>[
{segs}    ],
    competidoresBase: <Competidor>[
{comps}    ],
    eventos: <Evento>[
{evs}    ],
  );

"""


CABECERA = """import '../domain/models/beneficio.dart';
import '../domain/models/canal.dart';
import '../domain/models/competidor.dart';
import '../domain/models/decisiones.dart';
import '../domain/models/estado_marca.dart';
import '../domain/models/evento.dart';
import '../domain/models/medio.dart';
import '../domain/models/mercado.dart';
import '../domain/models/segmento.dart';

/// Los tres escenarios del simulador.
///
/// ARCHIVO GENERADO por `tool/generar_catalogo.py` a partir del prototipo de
/// calibracion. No editar a mano: cualquier cambio en estos numeros invalida
/// las pruebas de `test/calibracion_test.dart`, que son las que garantizan que
/// cada escenario ensena lo que dice ensenar.
class CatalogoMercados {
  const CatalogoMercados._();

"""

PIE = """  static List<Mercado> get todos => <Mercado>[bebida, mochilas, academia];

  static Mercado? porId(String id) {
    for (final Mercado m in todos) {
      if (m.id == id) return m;
    }
    return null;
  }
}
"""

if __name__ == "__main__":
    cuerpo = "".join(emitir_mercado(m) for m in MERCADOS.values())
    import os
    raiz = os.path.dirname(os.path.dirname(os.path.dirname(
        os.path.abspath(__file__))))
    destino = os.path.join(raiz, "lib", "data", "catalogo_mercados.dart")
    with open(destino, "w", encoding="utf-8") as f:
        f.write(CABECERA + cuerpo + PIE)
    print("catalogo_mercados.dart generado")
