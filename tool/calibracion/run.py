import copy
from motor import Decisiones, EstadoMarca, MEDIOS, simular_periodo, aplicar_eventos
from mercados import MERCADOS, medios


def jugar(mercado, politica, periodos=None, verbose=False):
    m = copy.deepcopy(mercado)
    periodos = periodos or m.periodos
    comps = copy.deepcopy(m.competidores_base)
    est = EstadoMarca(awareness={s.id: 0.04 for s in m.segmentos}, reputacion=0.50, claridad=0.35)
    caja = m.caja_inicial
    acum_util = 0.0
    sats = []
    parts = []
    quiebra = False
    hist = []
    for p in range(periodos):
        aplicar_eventos(m, comps, p)
        d = politica(p, est, caja)
        r = simular_periodo(m, d, est, comps, p)
        caja += r["utilidad"]
        acum_util += r["utilidad"]
        sats.append(r["satisfaccion"])
        parts.append(r["participacion"])
        hist.append(r)
        if verbose:
            print(f"  p{p+1}: u={r['unidades']:>9.0f} part={r['participacion']*100:5.1f}% "
                  f"sat={r['satisfaccion']*100:4.1f}% util={r['utilidad']:>12,.0f} caja={caja:>12,.0f}")
        if caja < -m.limite_sobregiro:
            quiebra = True
            break
    return {
        "caja": caja, "utilidad_acumulada": acum_util,
        "satisfaccion": sum(sats) / len(sats),
        "participacion_final": parts[-1] if parts else 0.0,
        "participacion_prom": sum(parts) / len(parts) if parts else 0.0,
        "quiebra": quiebra, "periodos": len(hist), "hist": hist,
    }


def pol(seg, ben, nivel, calidad, ben_real, amplitud, precio, canales, med):
    def f(periodo, est, caja):
        return Decisiones(
            segmento_objetivo=seg, beneficio_prometido=ben, nivel_promesa=nivel,
            calidad=calidad, beneficio_real=ben_real, amplitud=amplitud, precio=precio,
            canales=list(canales), medios=dict(med), investigacion=0.0,
        )
    return f


POLITICAS = {
    "bebida": {
        "nicho_premium": pol("fitness", "rendimiento", 4.5, 4.4, "rendimiento", 1, 7.4,
                             ["retail", "propio", "marketplace"],
                             medios(digital=34000, influencers=30000, punto_venta=6000)),
        "imagen_joven": pol("joven", "estatus", 4.2, 3.8, "estatus", 1, 7.6,
                            ["retail", "marketplace", "propio"],
                            medios(influencers=40000, digital=28000)),
        "masivo_barato": pol("familia", "precio", 2.0, 2.2, "precio", 3, 3.1,
                             ["bodegas", "mayorista", "retail"],
                             medios(tv=45000, radio=25000, punto_venta=14000)),
        "promedio_para_todos": pol("oficina", "energia", 3.0, 3.0, "energia", 2, 5.0,
                                   ["retail", "bodegas", "marketplace", "propio", "mayorista"],
                                   medios(tv=18000, radio=18000, digital=18000,
                                          influencers=18000, punto_venta=18000)),
        "promesa_incumplida": pol("fitness", "rendimiento", 5.0, 2.0, "precio", 1, 7.4,
                                  ["retail", "propio", "marketplace"],
                                  medios(digital=34000, influencers=30000, punto_venta=6000)),
        "regalado": pol("familia", "precio", 2.0, 2.2, "precio", 3, 1.9,
                        ["bodegas", "mayorista", "retail"],
                        medios(tv=45000, radio=25000, punto_venta=14000)),
        "sin_medios": pol("fitness", "rendimiento", 4.5, 4.4, "rendimiento", 1, 7.4,
                          ["retail", "propio", "marketplace"], medios()),
    },
    "mochilas": {
        "nicho_premium": pol("privado", "salud", 4.5, 4.4, "salud", 1, 132.0,
                             ["retail", "marketplace", "propio"],
                             medios(digital=40000, influencers=24000, punto_venta=8000)),
        "imagen_joven": pol("universitario", "estatus", 4.2, 3.8, "estatus", 1, 158.0,
                            ["marketplace", "propio", "retail"],
                            medios(influencers=44000, digital=30000)),
        "masivo_barato": pol("publico", "precio", 2.2, 2.4, "precio", 3, 43.0,
                             ["mayorista", "bodegas", "retail"],
                             medios(radio=40000, tv=42000, punto_venta=16000)),
        "promedio_para_todos": pol("publico", "precio", 3.0, 3.0, "precio", 2, 78.0,
                                   ["retail", "bodegas", "marketplace", "propio", "mayorista"],
                                   medios(tv=20000, radio=20000, digital=20000,
                                          influencers=20000, punto_venta=20000)),
        "promesa_incumplida": pol("privado", "salud", 5.0, 2.0, "precio", 1, 132.0,
                                  ["retail", "marketplace", "propio"],
                                  medios(digital=40000, influencers=24000, punto_venta=8000)),
        "regalado": pol("publico", "precio", 2.2, 2.4, "precio", 3, 20.0,
                        ["mayorista", "bodegas", "retail"],
                        medios(radio=40000, tv=42000, punto_venta=16000)),
        "sin_medios": pol("publico", "precio", 2.2, 2.4, "precio", 3, 43.0,
                          ["mayorista", "bodegas", "retail"], medios()),
    },
    "academia": {
        "nicho_premium": pol("postulante", "rendimiento", 4.6, 4.5, "rendimiento", 1, 195.0,
                             ["propio", "marketplace"],
                             medios(digital=46000, influencers=18000, punto_venta=6000)),
        "flexible": pol("trabajador", "flexibilidad", 3.8, 3.8, "flexibilidad", 2, 128.0,
                        ["propio", "marketplace"],
                        medios(digital=44000, radio=18000, influencers=8000)),
        "masivo_barato": pol("repitente", "precio", 2.2, 2.4, "precio", 3, 74.0,
                             ["propio", "marketplace", "bodegas"],
                             medios(radio=30000, digital=26000, tv=14000)),
        "promedio_para_todos": pol("trabajador", "flexibilidad", 3.0, 3.0, "flexibilidad", 2, 140.0,
                                   ["retail", "bodegas", "marketplace", "propio", "mayorista"],
                                   medios(tv=16000, radio=16000, digital=16000,
                                          influencers=16000, punto_venta=16000)),
        "promesa_incumplida": pol("postulante", "rendimiento", 5.0, 2.0, "precio", 1, 195.0,
                                  ["propio", "marketplace"],
                                  medios(digital=46000, influencers=18000, punto_venta=6000)),
        "regalado": pol("repitente", "precio", 2.2, 2.4, "precio", 3, 34.0,
                        ["propio", "marketplace", "bodegas"],
                        medios(radio=30000, digital=26000, tv=14000)),
        "sin_medios": pol("postulante", "rendimiento", 4.6, 4.5, "rendimiento", 1, 195.0,
                          ["propio", "marketplace"], medios()),
    },
}


def mixta(p1, p2, corte):
    """Politica que cambia de posicionamiento en el periodo `corte`."""
    def f(periodo, est, caja):
        return p1(periodo, est, caja) if periodo < corte else p2(periodo, est, caja)
    return f


POLITICAS["academia"]["reposiciona"] = mixta(
    POLITICAS["academia"]["nicho_premium"], POLITICAS["academia"]["flexible"], 3)
POLITICAS["bebida"]["a_ciegas"] = pol(
    "familia", "precio", 2.0, 2.2, "precio", 3, 6.9,
    ["retail", "propio", "marketplace"],
    medios(digital=34000, influencers=30000, punto_venta=6000))
POLITICAS["mochilas"]["a_ciegas"] = pol(
    "privado", "salud", 4.5, 4.4, "salud", 1, 132.0,
    ["mayorista", "bodegas"], medios(radio=40000, tv=42000, punto_venta=16000))
POLITICAS["academia"]["a_ciegas"] = pol(
    "escolar", "estatus", 4.2, 4.5, "rendimiento", 1, 195.0,
    ["propio", "marketplace"], medios(radio=46000, tv=18000, punto_venta=6000))


if __name__ == "__main__":
    for mid, mercado in MERCADOS.items():
        print("=" * 92)
        print(f"MERCADO: {mercado.nombre}")
        print("=" * 92)
        filas = []
        for nombre, p in POLITICAS[mid].items():
            r = jugar(mercado, p)
            filas.append((nombre, r))
        filas.sort(key=lambda x: -x[1]["utilidad_acumulada"])
        print(f"{'politica':<24}{'utilidad acum':>16}{'caja':>14}{'part.fin':>10}"
              f"{'sat':>8}{'quiebra':>9}")
        for nombre, r in filas:
            print(f"{nombre:<24}{r['utilidad_acumulada']:>16,.0f}{r['caja']:>14,.0f}"
                  f"{r['participacion_final']*100:>9.1f}%{r['satisfaccion']*100:>7.1f}%"
                  f"{('SI' if r['quiebra'] else 'no'):>9}")
        print()
