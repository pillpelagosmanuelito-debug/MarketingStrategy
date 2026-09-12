# -*- coding: utf-8 -*-
"""Corre la calibracion sobre la transliteracion del motor Dart entregado y la
compara con el prototipo. Cualquier diferencia es un defecto de transcripcion.
"""
import copy

import port_dart
from mercados import MERCADOS
from run import POLITICAS, jugar


def estado_nuevo(mercado, valor=0.04, reputacion=0.50, claridad=0.35):
    return {
        'awareness': {s.id: valor for s in mercado.segmentos},
        'reputacion': reputacion,
        'claridad': claridad,
        'satisfaccionPrevia': 0.55,
        'participacionPrevia': {},
        'acumulado': 0.0,
        'posicionPrevia': '',
    }


def jugar_dart(mercado, politica, periodos=None):
    m = copy.deepcopy(mercado)
    periodos = periodos or m.periodos
    comps = copy.deepcopy(m.competidores_base)
    for c in comps:
        c.estado = {
            'awareness': dict(c.estado.awareness),
            'reputacion': c.estado.reputacion,
            'claridad': c.estado.claridad,
            'satisfaccionPrevia': 0.55,
            'participacionPrevia': {},
            'acumulado': 0.0,
            'posicionPrevia': '',
        }
    estado = estado_nuevo(m)
    estado_mercado = {'factorCosto': 1.0, 'factorTamano': {}}
    caja = m.caja_inicial
    acumulada = 0.0
    sats, parts = [], []
    quiebra = False
    hist = []
    for p in range(periodos):
        port_dart.aplicar_eventos(m, estado_mercado, comps, p)
        d = politica(p, estado, caja)
        r = port_dart.simular_periodo(
            m, estado_mercado, d, estado, comps, p, caja)
        caja = r['cajaFinal']
        acumulada += r['utilidad']
        sats.append(r['satisfaccion'])
        parts.append(r['participacion'])
        hist.append(r)
        if caja < -m.limite_sobregiro:
            quiebra = True
            break
    return {
        'caja': caja,
        'utilidad_acumulada': acumulada,
        'satisfaccion': sum(sats) / len(sats),
        'participacion_final': parts[-1] if parts else 0.0,
        'quiebra': quiebra,
        'periodos': len(hist),
        'hist': hist,
    }


if __name__ == '__main__':
    fallos = 0
    for mid, mercado in MERCADOS.items():
        print('=' * 88)
        print(f'MERCADO {mercado.nombre}')
        print(f"{'politica':<24}{'prototipo':>16}{'dart entregado':>18}{'dif':>12}")
        for nombre, politica in POLITICAS[mid].items():
            a = jugar(mercado, politica)
            b = jugar_dart(mercado, politica)
            dif = b['utilidad_acumulada'] - a['utilidad_acumulada']
            marca = '' if abs(dif) < 1.0 else '   <-- DIFERENCIA'
            if abs(dif) >= 1.0:
                fallos += 1
            print(f"{nombre:<24}{a['utilidad_acumulada']:>16,.0f}"
                  f"{b['utilidad_acumulada']:>18,.0f}{dif:>12,.2f}{marca}")
        print()
    print('IDENTICOS' if fallos == 0 else f'{fallos} POLITICAS CON DIFERENCIA')
