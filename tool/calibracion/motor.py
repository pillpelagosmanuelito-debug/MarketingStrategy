"""Prototipo de calibracion del motor de Marketing Strategy Lab.

Este archivo es la especificacion ejecutable del motor que luego se escribe en
Dart. Todo parametro que aparezca aqui debe aparecer con el mismo valor en
lib/domain/engine/parametros.dart.
"""
import math
from dataclasses import dataclass, field
from typing import Dict, List

# ---------------------------------------------------------------- constantes

MEDIOS = ["tv", "radio", "digital", "influencers", "punto_venta"]
CANALES = ["retail", "bodegas", "marketplace", "propio", "mayorista"]

# eficiencia relativa de cada medio (alcance por sol invertido)
EFICIENCIA_MEDIO = {
    "tv": 0.85,
    "radio": 1.05,
    "digital": 1.20,
    "influencers": 1.10,
    "punto_venta": 0.95,
}
# costo minimo para que el medio funcione (por debajo, penalizacion)
MINIMO_MEDIO = {
    "tv": 40000.0,
    "radio": 8000.0,
    "digital": 3000.0,
    "influencers": 5000.0,
    "punto_venta": 4000.0,
}

# canal: (costo fijo por periodo, margen que se queda el canal)
CANAL_COSTO_FIJO = {
    "retail": 38000.0,
    "bodegas": 22000.0,
    "marketplace": 9000.0,
    "propio": 16000.0,
    "mayorista": 12000.0,
}
CANAL_MARGEN = {
    "retail": 0.28,
    "bodegas": 0.18,
    "marketplace": 0.20,
    "propio": 0.06,
    "mayorista": 0.32,
}

# similitud entre beneficios (que tan bien un beneficio cubre a otro)
BENEFICIOS = ["salud", "energia", "precio", "estatus", "rendimiento", "flexibilidad"]
SIMILITUD = {
    ("salud", "rendimiento"): 0.60,
    ("salud", "energia"): 0.45,
    ("energia", "rendimiento"): 0.55,
    ("estatus", "salud"): 0.30,
    ("estatus", "rendimiento"): 0.30,
    ("precio", "flexibilidad"): 0.35,
    ("flexibilidad", "rendimiento"): 0.30,
    ("energia", "flexibilidad"): 0.25,
}
PISO_SIMILITUD = 0.18

K_SATURACION_MEDIOS = 55000.0
DECAIMIENTO_AWARENESS = 0.15
TECHO_AWARENESS = 0.92
TECHO_COBERTURA = 0.95
LAMBDA_LOGIT = 3.0
UTILIDAD_NO_COMPRA = 0.95
INERCIA_BASE = 0.30
TASA_IMPUESTO = 0.295
FACTOR_EXPERIENCIA = 0.965
PISO_EXPERIENCIA = 0.80
PESO_REPUTACION = 1.30
CAIDA_REPUTACION = 0.42
SUBIDA_REPUTACION = 0.22
UMBRAL_BOCA_A_BOCA = 0.45
CASTIGO_BOCA_A_BOCA = 0.55
PREMIO_BOCA_A_BOCA = 0.30
PISO_SATISFACCION = 0.03
TECHO_SATISFACCION = 0.97
BASE_SATISFACCION = 0.62


def similitud(a: str, b: str) -> float:
    if a == b:
        return 1.0
    v = SIMILITUD.get((a, b)) or SIMILITUD.get((b, a))
    return v if v is not None else PISO_SIMILITUD


# ------------------------------------------------------------------ modelos

@dataclass
class Segmento:
    id: str
    nombre: str
    tamano: float
    precio_ref: float
    sensibilidad: float          # castigo por sol relativo por encima de la referencia
    peso_calidad: float
    peso_beneficio: float
    peso_marca: float
    peso_variedad: float
    beneficio: str
    exigencia: float             # nivel de calidad esperado 1..5
    lealtad: float
    sospecha_precio_bajo: float  # castigo si el precio es demasiado bajo
    afinidad_medio: Dict[str, float]
    afinidad_canal: Dict[str, float]


@dataclass
class Decisiones:
    segmento_objetivo: str
    beneficio_prometido: str
    nivel_promesa: float          # 1..5, que tan premium se declara
    calidad: float                # 1..5
    beneficio_real: str
    amplitud: int                 # 1..3 SKUs
    precio: float
    canales: List[str]
    medios: Dict[str, float]
    investigacion: float = 0.0

    def gasto_medios(self) -> float:
        return sum(self.medios.values())


@dataclass
class EstadoMarca:
    awareness: Dict[str, float]
    reputacion: float = 0.50
    claridad: float = 0.35
    satisfaccion_prev: float = 0.55
    participacion_prev: Dict[str, float] = field(default_factory=dict)
    acumulado: float = 0.0
    posicion_prev: str = ""


@dataclass
class Competidor:
    id: str
    nombre: str
    decisiones: Decisiones
    estado: EstadoMarca
    politica: str  # "lider_masivo", "premium", "retador"


@dataclass
class Evento:
    periodo: int
    titulo: str
    descripcion: str
    competidor: str = ""
    cambio_precio: float = 1.0
    cambio_medios: float = 1.0
    cambio_calidad: float = 0.0
    factor_costo: float = 1.0
    segmento: str = ""
    factor_tamano: float = 1.0


@dataclass
class Mercado:
    id: str
    nombre: str
    categoria: str
    segmentos: List[Segmento]
    costo_base: float
    costo_fijo: float
    caja_inicial: float
    limite_sobregiro: float
    periodos: int
    competidores_base: List[Competidor]
    eventos: List[Evento] = field(default_factory=list)


def aplicar_eventos(mercado: Mercado, comps: List[Competidor], periodo: int) -> List[Evento]:
    activos = [e for e in mercado.eventos if e.periodo == periodo]
    for e in activos:
        if e.factor_costo != 1.0:
            mercado.costo_base *= e.factor_costo
        if e.segmento:
            for s in mercado.segmentos:
                if s.id == e.segmento:
                    s.tamano *= e.factor_tamano
        if e.competidor:
            for c in comps:
                if c.id != e.competidor:
                    continue
                c.decisiones.precio *= e.cambio_precio
                c.decisiones.calidad = min(5.0, c.decisiones.calidad + e.cambio_calidad)
                for m in list(c.decisiones.medios.keys()):
                    c.decisiones.medios[m] *= e.cambio_medios
    return activos


# ------------------------------------------------------------------- motor

def costo_unitario(mercado: Mercado, d: Decisiones, acumulado: float) -> float:
    base = mercado.costo_base * (0.55 + 0.18 * d.calidad)
    base *= 1.0 + 0.05 * (d.amplitud - 1)
    if acumulado > 1000:
        pasos = math.log(acumulado / 1000.0) / math.log(2.0)
        factor = max(PISO_EXPERIENCIA, FACTOR_EXPERIENCIA ** pasos)
    else:
        factor = 1.0
    return base * factor


def cobertura(seg: Segmento, canales: List[str]) -> float:
    libre = 1.0
    for c in canales:
        libre *= 1.0 - seg.afinidad_canal.get(c, 0.0)
    return min(TECHO_COBERTURA, 1.0 - libre)


def margen_canal(seg: Segmento, canales: List[str]) -> float:
    peso = 0.0
    acum = 0.0
    for c in canales:
        a = seg.afinidad_canal.get(c, 0.0)
        peso += a
        acum += a * CANAL_MARGEN[c]
    if peso <= 0.0:
        return 0.0
    return acum / peso


def actualizar_awareness(seg: Segmento, aw: float, medios: Dict[str, float],
                         satisfaccion_prev: float = 0.55) -> float:
    efectiva = 0.0
    for m, monto in medios.items():
        if monto <= 0.0:
            continue
        penal = 1.0 if monto >= MINIMO_MEDIO[m] else 0.45 + 0.55 * (monto / MINIMO_MEDIO[m])
        efectiva += monto * EFICIENCIA_MEDIO[m] * seg.afinidad_medio.get(m, 0.0) * penal
    ganancia = (TECHO_AWARENESS - aw) * (efectiva / (efectiva + K_SATURACION_MEDIOS)) if efectiva > 0 else 0.0
    # boca a boca: la satisfaccion del periodo anterior acelera o frena el recuerdo de marca
    decaimiento = DECAIMIENTO_AWARENESS
    if satisfaccion_prev < UMBRAL_BOCA_A_BOCA:
        decaimiento += CASTIGO_BOCA_A_BOCA * (UMBRAL_BOCA_A_BOCA - satisfaccion_prev)
    elif satisfaccion_prev > 0.72:
        ganancia += (TECHO_AWARENESS - aw) * PREMIO_BOCA_A_BOCA * (satisfaccion_prev - 0.72)
    decaimiento = min(0.70, decaimiento)
    nuevo = aw * (1.0 - decaimiento) + ganancia
    return max(0.02, min(TECHO_AWARENESS, nuevo))


def atractivo(seg: Segmento, d: Decisiones, est: EstadoMarca) -> float:
    fit_promesa = similitud(d.beneficio_prometido, seg.beneficio)
    nivel = d.nivel_promesa / 5.0
    calidad_creida = nivel * (0.45 + 0.55 * est.claridad) + (d.calidad / 5.0) * (0.55 * est.claridad)
    calidad_creida = min(1.0, calidad_creida)
    v = (
        seg.peso_calidad * calidad_creida
        + seg.peso_beneficio * fit_promesa
        + seg.peso_marca * (est.claridad * fit_promesa)
        + seg.peso_variedad * (d.amplitud / 3.0)
    )
    v *= 1.0 + PESO_REPUTACION * (est.reputacion - 0.5)
    return max(0.01, v)


def utilidad(seg: Segmento, d: Decisiones, est: EstadoMarca) -> float:
    rel = d.precio / seg.precio_ref
    u = LAMBDA_LOGIT * atractivo(seg, d, est) - seg.sensibilidad * (rel - 1.0)
    if rel < 0.72:
        u -= seg.sospecha_precio_bajo * (0.72 - rel) * 3.0
    return u


def satisfaccion(seg: Segmento, d: Decisiones) -> float:
    fit_real = similitud(d.beneficio_real, seg.beneficio)
    fit_promesa = similitud(d.beneficio_prometido, seg.beneficio)
    entregado = 0.55 * (d.calidad / 5.0) + 0.45 * fit_real
    esperado = 0.55 * (d.nivel_promesa / 5.0) + 0.45 * fit_promesa
    esperado *= 1.0 + 0.15 * (d.precio / seg.precio_ref - 1.0)
    esperado *= 0.94 + 0.03 * (seg.exigencia - 3.0)
    s = BASE_SATISFACCION + 1.30 * (entregado - esperado)
    return max(PISO_SATISFACCION, min(TECHO_SATISFACCION, s))


def politica_competidor(c: Competidor, share_jugador: float, precio_jugador: float,
                        mercado: Mercado, periodo: int) -> None:
    d = c.decisiones
    if c.politica == "lider_masivo":
        if share_jugador > 0.22:
            d.precio = max(mercado.costo_base * 1.35, d.precio * 0.96)
            for m in d.medios:
                d.medios[m] *= 1.06
    elif c.politica == "premium":
        if share_jugador > 0.18:
            d.calidad = min(5.0, d.calidad + 0.15)
            d.medios["digital"] = d.medios.get("digital", 0.0) * 1.08 + 2000.0
    elif c.politica == "retador":
        if precio_jugador < d.precio:
            d.precio = max(mercado.costo_base * 1.25, d.precio * 0.97)
        else:
            d.precio *= 1.01


def simular_periodo(mercado: Mercado, d: Decisiones, est: EstadoMarca,
                    comps: List[Competidor], periodo: int) -> dict:
    marcas = [("jugador", d, est)] + [(c.id, c.decisiones, c.estado) for c in comps]

    # awareness
    for seg in mercado.segmentos:
        for mid, dec, e in marcas:
            e.awareness[seg.id] = actualizar_awareness(
                seg, e.awareness.get(seg.id, 0.05), dec.medios, e.satisfaccion_prev)

    ventas = {mid: 0.0 for mid, _, _ in marcas}
    ingresos = 0.0
    sat_pond = 0.0
    detalle_seg = []

    for seg in mercado.segmentos:
        pesos = {}
        for mid, dec, e in marcas:
            cob = cobertura(seg, dec.canales)
            aw = e.awareness[seg.id]
            if cob <= 0.0 or aw <= 0.0:
                pesos[mid] = 0.0
                continue
            pesos[mid] = cob * aw * math.exp(utilidad(seg, dec, e))
        total = sum(pesos.values()) + math.exp(UTILIDAD_NO_COMPRA)
        shares = {mid: pesos[mid] / total for mid in pesos}
        # inercia: parte de la participacion previa se sostiene
        inercia = INERCIA_BASE * seg.lealtad
        for mid in shares:
            prev = None
            for m2, _, e2 in marcas:
                if m2 == mid:
                    prev = e2.participacion_prev.get(seg.id)
            if prev is not None:
                shares[mid] = (1.0 - inercia) * shares[mid] + inercia * prev
        for mid, _, e in marcas:
            e.participacion_prev[seg.id] = shares[mid]

        for mid, dec, e in marcas:
            u = seg.tamano * shares[mid]
            ventas[mid] += u
            if mid == "jugador":
                ingresos += u * dec.precio * (1.0 - margen_canal(seg, dec.canales))
                s = satisfaccion(seg, dec)
                sat_pond += s * u
                detalle_seg.append({
                    "segmento": seg.id, "unidades": u, "share": shares[mid], "satisfaccion": s,
                })

    unidades = ventas["jugador"]
    sat_global = (sat_pond / unidades) if unidades > 0 else 0.5

    cu = costo_unitario(mercado, d, est.acumulado)
    costo_var = unidades * cu
    costo_canales = sum(CANAL_COSTO_FIJO[c] for c in d.canales)
    gasto_medios = d.gasto_medios()
    costos = costo_var + mercado.costo_fijo + costo_canales + gasto_medios + d.investigacion
    utilidad_bruta = ingresos - costos
    impuesto = utilidad_bruta * TASA_IMPUESTO if utilidad_bruta > 0 else 0.0
    utilidad_neta = utilidad_bruta - impuesto

    # reputacion e imagen
    velocidad = CAIDA_REPUTACION if sat_global < est.reputacion else SUBIDA_REPUTACION
    est.reputacion = max(0.05, min(0.95, est.reputacion * (1.0 - velocidad)
                                   + velocidad * sat_global))
    est.satisfaccion_prev = sat_global
    pos = f"{d.segmento_objetivo}|{d.beneficio_prometido}|{d.nivel_promesa:.0f}"
    if est.posicion_prev and est.posicion_prev != pos:
        est.claridad *= 0.55
    else:
        inv_rel = min(1.0, gasto_medios / 60000.0)
        est.claridad = min(0.95, est.claridad + (0.95 - est.claridad) * 0.30 * inv_rel)
    est.posicion_prev = pos
    est.acumulado += unidades

    total_mercado = sum(ventas.values())
    participacion = unidades / total_mercado if total_mercado > 0 else 0.0

    for c in comps:
        politica_competidor(c, participacion, d.precio, mercado, periodo)
        c.estado.acumulado += ventas[c.id]
        c.estado.reputacion = max(0.05, min(0.95, c.estado.reputacion * 0.9 + 0.1 * 0.55))
        c.estado.claridad = min(0.9, c.estado.claridad + 0.05)

    return {
        "unidades": unidades,
        "ingresos": ingresos,
        "costo_unitario": cu,
        "costos": costos,
        "utilidad": utilidad_neta,
        "satisfaccion": sat_global,
        "participacion": participacion,
        "segmentos": detalle_seg,
        "ventas_todas": dict(ventas),
    }
