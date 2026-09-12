# -*- coding: utf-8 -*-
"""Transliteracion a Python del motor Dart REALMENTE ENTREGADO.

No es el prototipo: se escribio leyendo linea por linea
`lib/domain/engine/motor_simulacion.dart` y `parametros.dart`. Correr la
calibracion sobre esta transliteracion es la unica forma de verificar el codigo
que se entrega, y no el prototipo del que salio.

Leccion aprendida en Project Management Simulator (#33): la verificacion tiene
que correr sobre el codigo entregado.
"""
import math

# ---------------------------------------------- parametros.dart (Dart)
LAMBDA_LOGIT = 3.0
UTILIDAD_NO_COMPRA = 0.95
K_SATURACION_MEDIOS = 55000.0
DECAIMIENTO_AWARENESS = 0.15
TECHO_AWARENESS = 0.92
PISO_AWARENESS = 0.02
TECHO_COBERTURA = 0.95
INERCIA_BASE = 0.30
TASA_IMPUESTO = 0.295
FACTOR_EXPERIENCIA = 0.965
PISO_EXPERIENCIA = 0.80
VOLUMEN_INICIAL_EXPERIENCIA = 1000.0
PESO_REPUTACION = 1.30
CAIDA_REPUTACION = 0.42
SUBIDA_REPUTACION = 0.22
UMBRAL_BOCA_A_BOCA = 0.45
CASTIGO_BOCA_A_BOCA = 0.55
PREMIO_BOCA_A_BOCA = 0.30
UMBRAL_BOCA_A_BOCA_ALTO = 0.72
DECAIMIENTO_MAXIMO = 0.70
PISO_SATISFACCION = 0.03
TECHO_SATISFACCION = 0.97
BASE_SATISFACCION = 0.62
PENDIENTE_SATISFACCION = 1.30
PISO_REPUTACION = 0.05
TECHO_REPUTACION = 0.95
RECUPERACION_CLARIDAD = 0.30
CASTIGO_CAMBIO_POSICION = 0.55
TECHO_CLARIDAD = 0.95
INVERSION_CLARIDAD_PLENA = 60000.0
UMBRAL_SOSPECHA = 0.72
PESO_SOSPECHA = 3.0
COSTO_BASE_CALIDAD = 0.55
COSTO_POR_CALIDAD = 0.18
COSTO_POR_AMPLITUD = 0.05
PESO_CALIDAD_ENTREGA = 0.55
PESO_BENEFICIO_ENTREGA = 0.45
PESO_PRECIO_EXPECTATIVA = 0.15
PESO_EXIGENCIA = 0.03
PISO_SIMILITUD = 0.18

SIMILITUDES = {
    'salud|rendimiento': 0.60,
    'salud|energia': 0.45,
    'energia|rendimiento': 0.55,
    'estatus|salud': 0.30,
    'estatus|rendimiento': 0.30,
    'precio|flexibilidad': 0.35,
    'flexibilidad|rendimiento': 0.30,
    'energia|flexibilidad': 0.25,
}

# medio -> (eficiencia, minimo)
MEDIOS_DART = {
    'tv': (0.85, 40000.0),
    'radio': (1.05, 8000.0),
    'digital': (1.20, 3000.0),
    'influencers': (1.10, 5000.0),
    'punto_venta': (0.95, 4000.0),
}
# canal -> (costoFijo, margen)
CANALES_DART = {
    'retail': (38000.0, 0.28),
    'bodegas': (22000.0, 0.18),
    'marketplace': (9000.0, 0.20),
    'propio': (16000.0, 0.06),
    'mayorista': (12000.0, 0.32),
}


def similitud(a, b):
    if a == b:
        return 1.0
    d = SIMILITUDES.get(f'{a}|{b}')
    if d is not None:
        return d
    i = SIMILITUDES.get(f'{b}|{a}')
    if i is not None:
        return i
    return PISO_SIMILITUD


# ---------------------------------------------- motor_simulacion.dart (Dart)

def aplicar_eventos(mercado, estado_mercado, competidores, periodo):
    activos = [e for e in mercado.eventos if e.periodo == periodo]
    for e in activos:
        if e.factor_costo != 1.0:
            estado_mercado['factorCosto'] *= e.factor_costo
        if e.segmento:
            previo = estado_mercado['factorTamano'].get(e.segmento, 1.0)
            estado_mercado['factorTamano'][e.segmento] = previo * e.factor_tamano
        if e.competidor:
            for c in competidores:
                if c.id != e.competidor:
                    continue
                for m in list(c.decisiones.medios.keys()):
                    c.decisiones.medios[m] *= e.cambio_medios
                c.decisiones.precio *= e.cambio_precio
                c.decisiones.calidad = min(5.0, c.decisiones.calidad + e.cambio_calidad)
    return activos


def costo_base(mercado, estado_mercado):
    return mercado.costo_base * estado_mercado['factorCosto']


def tamano(seg, estado_mercado):
    return seg.tamano * estado_mercado['factorTamano'].get(seg.id, 1.0)


def costo_unitario(mercado, estado_mercado, d, acumulado):
    base = costo_base(mercado, estado_mercado) * (
        COSTO_BASE_CALIDAD + COSTO_POR_CALIDAD * d.calidad)
    base = base * (1.0 + COSTO_POR_AMPLITUD * (d.amplitud - 1))
    factor = 1.0
    if acumulado > VOLUMEN_INICIAL_EXPERIENCIA:
        pasos = math.log(acumulado / VOLUMEN_INICIAL_EXPERIENCIA) / math.log(2.0)
        factor = max(PISO_EXPERIENCIA, FACTOR_EXPERIENCIA ** pasos)
    return base * factor


def cobertura(seg, canales):
    libre = 1.0
    for c in canales:
        libre = libre * (1.0 - seg.afinidad_canal.get(c, 0.0))
    return min(TECHO_COBERTURA, 1.0 - libre)


def margen_canal(seg, canales):
    peso = 0.0
    acumulado = 0.0
    for c in canales:
        a = seg.afinidad_canal.get(c, 0.0)
        peso += a
        acumulado += a * CANALES_DART[c][1]
    if peso <= 0.0:
        return 0.0
    return acumulado / peso


def actualizar_awareness(seg, awareness, medios, satisfaccion_previa):
    efectiva = 0.0
    for m, monto in medios.items():
        if monto <= 0.0:
            continue
        eficiencia, minimo = MEDIOS_DART[m]
        penalizacion = 1.0 if monto >= minimo else 0.45 + 0.55 * (monto / minimo)
        efectiva += monto * eficiencia * seg.afinidad_medio.get(m, 0.0) * penalizacion
    ganancia = 0.0
    if efectiva > 0.0:
        ganancia = (TECHO_AWARENESS - awareness) * (
            efectiva / (efectiva + K_SATURACION_MEDIOS))
    decaimiento = DECAIMIENTO_AWARENESS
    if satisfaccion_previa < UMBRAL_BOCA_A_BOCA:
        decaimiento += CASTIGO_BOCA_A_BOCA * (UMBRAL_BOCA_A_BOCA - satisfaccion_previa)
    elif satisfaccion_previa > UMBRAL_BOCA_A_BOCA_ALTO:
        ganancia += (TECHO_AWARENESS - awareness) * PREMIO_BOCA_A_BOCA * (
            satisfaccion_previa - UMBRAL_BOCA_A_BOCA_ALTO)
    decaimiento = min(DECAIMIENTO_MAXIMO, decaimiento)
    nuevo = awareness * (1.0 - decaimiento) + ganancia
    return max(PISO_AWARENESS, min(TECHO_AWARENESS, nuevo))


def atractivo(seg, d, est):
    fit_promesa = similitud(d.beneficio_prometido, seg.beneficio)
    nivel = d.nivel_promesa / 5.0
    calidad_creida = nivel * (0.45 + 0.55 * est['claridad']) + (
        d.calidad / 5.0) * (0.55 * est['claridad'])
    calidad_creida = min(1.0, calidad_creida)
    v = (seg.peso_calidad * calidad_creida
         + seg.peso_beneficio * fit_promesa
         + seg.peso_marca * (est['claridad'] * fit_promesa)
         + seg.peso_variedad * (d.amplitud / 3.0))
    v = v * (1.0 + PESO_REPUTACION * (est['reputacion'] - 0.5))
    return max(0.01, v)


def utilidad(seg, d, est):
    relativo = d.precio / seg.precio_ref
    u = LAMBDA_LOGIT * atractivo(seg, d, est) - seg.sensibilidad * (relativo - 1.0)
    if relativo < UMBRAL_SOSPECHA:
        u = u - seg.sospecha_precio_bajo * (UMBRAL_SOSPECHA - relativo) * PESO_SOSPECHA
    return u


def satisfaccion(seg, d):
    fit_real = similitud(d.beneficio_real, seg.beneficio)
    fit_promesa = similitud(d.beneficio_prometido, seg.beneficio)
    entregado = PESO_CALIDAD_ENTREGA * (d.calidad / 5.0) + \
        PESO_BENEFICIO_ENTREGA * fit_real
    esperado = PESO_CALIDAD_ENTREGA * (d.nivel_promesa / 5.0) + \
        PESO_BENEFICIO_ENTREGA * fit_promesa
    esperado = esperado * (1.0 + PESO_PRECIO_EXPECTATIVA * (
        d.precio / seg.precio_ref - 1.0))
    esperado = esperado * (0.94 + PESO_EXIGENCIA * (seg.exigencia - 3.0))
    s = BASE_SATISFACCION + PENDIENTE_SATISFACCION * (entregado - esperado)
    return max(PISO_SATISFACCION, min(TECHO_SATISFACCION, s))


def reaccionar(c, participacion_jugador, precio_jugador, mercado, estado_mercado):
    d = c.decisiones
    if c.politica == 'lider_masivo':
        if participacion_jugador > 0.22:
            for m in d.medios:
                d.medios[m] *= 1.06
            d.precio = max(costo_base(mercado, estado_mercado) * 1.35, d.precio * 0.96)
    elif c.politica == 'premium':
        if participacion_jugador > 0.18:
            d.medios['digital'] = d.medios.get('digital', 0.0) * 1.08 + 2000.0
            d.calidad = min(5.0, d.calidad + 0.15)
    elif c.politica == 'retador':
        if precio_jugador < d.precio:
            d.precio = max(costo_base(mercado, estado_mercado) * 1.25, d.precio * 0.97)
        else:
            d.precio = d.precio * 1.01


def simular_periodo(mercado, estado_mercado, decisiones, estado, competidores,
                    periodo, caja_previa):
    marcas = [('jugador', decisiones, estado)] + \
        [(c.id, c.decisiones, c.estado) for c in competidores]

    for seg in mercado.segmentos:
        for mid, dec, est in marcas:
            est['awareness'][seg.id] = actualizar_awareness(
                seg, est['awareness'].get(seg.id, 0.05), dec.medios,
                est['satisfaccionPrevia'])

    ventas = {mid: 0.0 for mid, _, _ in marcas}
    ingresos = 0.0
    satisfaccion_ponderada = 0.0
    detalle = []

    for seg in mercado.segmentos:
        pesos = {}
        for mid, dec, est in marcas:
            cob = cobertura(seg, dec.canales)
            aw = est['awareness'].get(seg.id, 0.0)
            if cob <= 0.0 or aw <= 0.0:
                pesos[mid] = 0.0
                continue
            pesos[mid] = cob * aw * math.exp(utilidad(seg, dec, est))
        total = math.exp(UTILIDAD_NO_COMPRA)
        for v in pesos.values():
            total += v

        participaciones = {}
        inercia = INERCIA_BASE * seg.lealtad
        for mid, dec, est in marcas:
            share = pesos[mid] / total
            previa = est['participacionPrevia'].get(seg.id)
            if previa is not None:
                share = (1.0 - inercia) * share + inercia * previa
            participaciones[mid] = share
        for mid, dec, est in marcas:
            est['participacionPrevia'][seg.id] = participaciones[mid]

        tam = tamano(seg, estado_mercado)
        for mid, dec, est in marcas:
            unidades = tam * participaciones[mid]
            ventas[mid] += unidades
            if mid != 'jugador':
                continue
            margen = margen_canal(seg, dec.canales)
            ingreso = unidades * dec.precio * (1.0 - margen)
            ingresos += ingreso
            sat = satisfaccion(seg, dec)
            satisfaccion_ponderada += sat * unidades
            detalle.append({'segmento': seg.id, 'unidades': unidades,
                            'satisfaccion': sat})

    unidades = ventas['jugador']
    satisfaccion_global = satisfaccion_ponderada / unidades if unidades > 0 else 0.5

    cu = costo_unitario(mercado, estado_mercado, decisiones, estado['acumulado'])
    costo_variable = unidades * cu
    costo_canales = sum(CANALES_DART[c][0] for c in decisiones.canales)
    gasto_medios = sum(decisiones.medios.values())
    costos = costo_variable + mercado.costo_fijo + costo_canales + \
        gasto_medios + decisiones.investigacion
    utilidad_bruta = ingresos - costos
    impuesto = utilidad_bruta * TASA_IMPUESTO if utilidad_bruta > 0 else 0.0
    utilidad_neta = utilidad_bruta - impuesto

    velocidad = CAIDA_REPUTACION if satisfaccion_global < estado['reputacion'] \
        else SUBIDA_REPUTACION
    estado['reputacion'] = max(PISO_REPUTACION, min(
        TECHO_REPUTACION,
        estado['reputacion'] * (1.0 - velocidad) + velocidad * satisfaccion_global))
    estado['satisfaccionPrevia'] = satisfaccion_global

    firma = (f"{decisiones.segmento_objetivo}|{decisiones.beneficio_prometido}|"
             f"{round(decisiones.nivel_promesa)}")
    if estado['posicionPrevia'] and estado['posicionPrevia'] != firma:
        estado['claridad'] = estado['claridad'] * CASTIGO_CAMBIO_POSICION
    else:
        inversion_relativa = min(1.0, gasto_medios / INVERSION_CLARIDAD_PLENA)
        estado['claridad'] = min(
            TECHO_CLARIDAD,
            estado['claridad'] + (TECHO_CLARIDAD - estado['claridad'])
            * RECUPERACION_CLARIDAD * inversion_relativa)
    estado['posicionPrevia'] = firma
    estado['acumulado'] += unidades

    total_mercado = sum(ventas.values())
    participacion = unidades / total_mercado if total_mercado > 0 else 0.0

    for c in competidores:
        reaccionar(c, participacion, decisiones.precio, mercado, estado_mercado)
        c.estado['acumulado'] += ventas.get(c.id, 0.0)
        c.estado['reputacion'] = max(PISO_REPUTACION, min(
            TECHO_REPUTACION, c.estado['reputacion'] * 0.9 + 0.1 * 0.55))
        c.estado['claridad'] = min(0.90, c.estado['claridad'] + 0.05)

    return {
        'unidades': unidades,
        'ingresos': ingresos,
        'costoUnitario': cu,
        'utilidad': utilidad_neta,
        'satisfaccion': satisfaccion_global,
        'participacion': participacion,
        'cajaFinal': caja_previa + utilidad_neta,
        'segmentos': detalle,
        'ventas': dict(ventas),
    }
