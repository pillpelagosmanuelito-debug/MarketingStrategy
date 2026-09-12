from motor import (Segmento, Decisiones, EstadoMarca, Competidor, Mercado, Evento,
                   MEDIOS, CANALES)


def aw0(mercado_segs, v=0.05):
    return {s.id: v for s in mercado_segs}


def medios(**kw):
    d = {m: 0.0 for m in MEDIOS}
    d.update(kw)
    return d


# ------------------------------------------------------ M1 bebida funcional

S1 = [
    Segmento(
        id="fitness", nombre="Deportista urbano", tamano=260000, precio_ref=6.8,
        sensibilidad=1.5, peso_calidad=0.40, peso_beneficio=0.34, peso_marca=0.18,
        peso_variedad=0.08, beneficio="rendimiento", exigencia=4.3, lealtad=0.55,
        sospecha_precio_bajo=1.6,
        afinidad_medio=medios(digital=0.55, influencers=0.60, punto_venta=0.25, tv=0.10, radio=0.08),
        afinidad_canal={"retail": 0.55, "propio": 0.45, "marketplace": 0.40, "bodegas": 0.12, "mayorista": 0.05},
    ),
    Segmento(
        id="oficina", nombre="Oficinista apurado", tamano=520000, precio_ref=5.0,
        sensibilidad=2.6, peso_calidad=0.26, peso_beneficio=0.34, peso_marca=0.22,
        peso_variedad=0.18, beneficio="energia", exigencia=3.2, lealtad=0.40,
        sospecha_precio_bajo=0.5,
        afinidad_medio=medios(digital=0.40, radio=0.35, punto_venta=0.45, tv=0.25, influencers=0.15),
        afinidad_canal={"retail": 0.50, "bodegas": 0.55, "marketplace": 0.15, "propio": 0.10, "mayorista": 0.20},
    ),
    Segmento(
        id="familia", nombre="Familia ahorradora", tamano=900000, precio_ref=3.3,
        sensibilidad=4.6, peso_calidad=0.18, peso_beneficio=0.24, peso_marca=0.20,
        peso_variedad=0.38, beneficio="precio", exigencia=2.4, lealtad=0.35,
        sospecha_precio_bajo=0.0,
        afinidad_medio=medios(tv=0.50, radio=0.45, punto_venta=0.35, digital=0.15, influencers=0.05),
        afinidad_canal={"bodegas": 0.62, "mayorista": 0.50, "retail": 0.30, "marketplace": 0.05, "propio": 0.03},
    ),
    Segmento(
        id="joven", nombre="Joven que busca imagen", tamano=280000, precio_ref=7.2,
        sensibilidad=1.2, peso_calidad=0.22, peso_beneficio=0.26, peso_marca=0.44,
        peso_variedad=0.08, beneficio="estatus", exigencia=3.6, lealtad=0.45,
        sospecha_precio_bajo=2.2,
        afinidad_medio=medios(influencers=0.70, digital=0.55, punto_venta=0.15, tv=0.12, radio=0.05),
        afinidad_canal={"retail": 0.45, "marketplace": 0.45, "propio": 0.40, "bodegas": 0.20, "mayorista": 0.03},
    ),
]

C1 = [
    Competidor(
        id="selva", nombre="Selva Pura", politica="lider_masivo",
        decisiones=Decisiones(
            segmento_objetivo="familia", beneficio_prometido="precio", nivel_promesa=2.0,
            calidad=2.2, beneficio_real="precio", amplitud=3, precio=3.0,
            canales=["bodegas", "mayorista", "retail"],
            medios=medios(tv=55000, radio=30000, punto_venta=20000),
        ),
        estado=EstadoMarca(awareness=aw0(S1, 0.42), reputacion=0.55, claridad=0.70),
    ),
    Competidor(
        id="vital", nombre="VitalPlus", politica="retador",
        decisiones=Decisiones(
            segmento_objetivo="oficina", beneficio_prometido="energia", nivel_promesa=3.0,
            calidad=3.2, beneficio_real="energia", amplitud=2, precio=5.2,
            canales=["retail", "bodegas"],
            medios=medios(digital=22000, radio=14000, punto_venta=12000),
        ),
        estado=EstadoMarca(awareness=aw0(S1, 0.30), reputacion=0.52, claridad=0.55),
    ),
]

M1 = Mercado(
    id="bebida", nombre="Bebida funcional embotellada", categoria="Consumo masivo",
    segmentos=S1, costo_base=1.55, costo_fijo=90000.0, caja_inicial=600000.0,
    limite_sobregiro=350000.0, periodos=8, competidores_base=C1,
)

# --------------------------------------------------------- M2 mochilas

S2 = [
    Segmento(
        id="publico", nombre="Padres de colegio publico", tamano=75000, precio_ref=46.0,
        sensibilidad=5.2, peso_calidad=0.20, peso_beneficio=0.26, peso_marca=0.14,
        peso_variedad=0.40, beneficio="precio", exigencia=2.3, lealtad=0.25,
        sospecha_precio_bajo=0.0,
        afinidad_medio=medios(radio=0.50, tv=0.40, punto_venta=0.40, digital=0.15, influencers=0.05),
        afinidad_canal={"bodegas": 0.55, "mayorista": 0.62, "retail": 0.28, "marketplace": 0.10, "propio": 0.03},
    ),
    Segmento(
        id="provincia", nombre="Familia de provincia", tamano=60000, precio_ref=39.0,
        sensibilidad=5.6, peso_calidad=0.22, peso_beneficio=0.28, peso_marca=0.12,
        peso_variedad=0.38, beneficio="precio", exigencia=2.2, lealtad=0.30,
        sospecha_precio_bajo=0.0,
        afinidad_medio=medios(radio=0.60, tv=0.30, punto_venta=0.30, digital=0.10, influencers=0.03),
        afinidad_canal={"mayorista": 0.68, "bodegas": 0.45, "retail": 0.15, "marketplace": 0.08, "propio": 0.02},
    ),
    Segmento(
        id="privado", nombre="Padres de colegio privado", tamano=17600, precio_ref=125.0,
        sensibilidad=1.6, peso_calidad=0.46, peso_beneficio=0.28, peso_marca=0.18,
        peso_variedad=0.08, beneficio="salud", exigencia=4.2, lealtad=0.50,
        sospecha_precio_bajo=1.8,
        afinidad_medio=medios(digital=0.50, punto_venta=0.30, influencers=0.30, tv=0.15, radio=0.10),
        afinidad_canal={"retail": 0.55, "marketplace": 0.45, "propio": 0.35, "bodegas": 0.10, "mayorista": 0.05},
    ),
    Segmento(
        id="universitario", nombre="Universitario urbano", tamano=14400, precio_ref=150.0,
        sensibilidad=1.4, peso_calidad=0.24, peso_beneficio=0.24, peso_marca=0.44,
        peso_variedad=0.08, beneficio="estatus", exigencia=3.8, lealtad=0.42,
        sospecha_precio_bajo=2.4,
        afinidad_medio=medios(influencers=0.68, digital=0.58, punto_venta=0.10, tv=0.08, radio=0.04),
        afinidad_canal={"marketplace": 0.55, "propio": 0.45, "retail": 0.40, "bodegas": 0.12, "mayorista": 0.03},
    ),
]

C2 = [
    Competidor(
        id="andes", nombre="Andes Gear", politica="premium",
        decisiones=Decisiones(
            segmento_objetivo="privado", beneficio_prometido="salud", nivel_promesa=4.5,
            calidad=4.3, beneficio_real="salud", amplitud=2, precio=138.0,
            canales=["retail", "marketplace", "propio"],
            medios=medios(digital=38000, influencers=26000, punto_venta=10000),
        ),
        estado=EstadoMarca(awareness=aw0(S2, 0.38), reputacion=0.62, claridad=0.75),
    ),
    Competidor(
        id="kuma", nombre="Kuma", politica="retador",
        decisiones=Decisiones(
            segmento_objetivo="publico", beneficio_prometido="precio", nivel_promesa=2.5,
            calidad=2.6, beneficio_real="precio", amplitud=2, precio=52.0,
            canales=["bodegas", "retail"],
            medios=medios(radio=16000, tv=18000, punto_venta=10000),
        ),
        estado=EstadoMarca(awareness=aw0(S2, 0.24), reputacion=0.50, claridad=0.45),
    ),
]

M2 = Mercado(
    id="mochilas", nombre="Mochilas escolares y urbanas", categoria="Retail estacional",
    segmentos=S2, costo_base=16.0, costo_fijo=150000.0, caja_inicial=700000.0,
    limite_sobregiro=350000.0, periodos=8, competidores_base=C2,
)

# ------------------------------------------------------ M3 academia online

S3 = [
    Segmento(
        id="postulante", nombre="Postulante a tiempo completo", tamano=10500, precio_ref=185.0,
        sensibilidad=2.2, peso_calidad=0.44, peso_beneficio=0.30, peso_marca=0.20,
        peso_variedad=0.06, beneficio="rendimiento", exigencia=4.4, lealtad=0.60,
        sospecha_precio_bajo=2.0,
        afinidad_medio=medios(digital=0.60, influencers=0.35, punto_venta=0.20, tv=0.12, radio=0.10),
        afinidad_canal={"propio": 0.60, "marketplace": 0.35, "retail": 0.20, "bodegas": 0.05, "mayorista": 0.02},
    ),
    Segmento(
        id="trabajador", nombre="Trabajador que estudia", tamano=14500, precio_ref=125.0,
        sensibilidad=3.0, peso_calidad=0.28, peso_beneficio=0.42, peso_marca=0.18,
        peso_variedad=0.12, beneficio="flexibilidad", exigencia=3.3, lealtad=0.48,
        sospecha_precio_bajo=0.6,
        afinidad_medio=medios(digital=0.55, radio=0.35, influencers=0.20, punto_venta=0.15, tv=0.15),
        afinidad_canal={"propio": 0.55, "marketplace": 0.40, "retail": 0.12, "bodegas": 0.05, "mayorista": 0.02},
    ),
    Segmento(
        id="escolar", nombre="Escolar con padres que pagan", tamano=7800, precio_ref=225.0,
        sensibilidad=1.5, peso_calidad=0.34, peso_beneficio=0.24, peso_marca=0.36,
        peso_variedad=0.06, beneficio="estatus", exigencia=4.0, lealtad=0.58,
        sospecha_precio_bajo=2.6,
        afinidad_medio=medios(digital=0.45, tv=0.30, punto_venta=0.25, influencers=0.25, radio=0.15),
        afinidad_canal={"propio": 0.55, "retail": 0.30, "marketplace": 0.25, "bodegas": 0.05, "mayorista": 0.02},
    ),
    Segmento(
        id="repitente", nombre="Repitente con presupuesto corto", tamano=19000, precio_ref=72.0,
        sensibilidad=5.0, peso_calidad=0.22, peso_beneficio=0.30, peso_marca=0.14,
        peso_variedad=0.34, beneficio="precio", exigencia=2.4, lealtad=0.28,
        sospecha_precio_bajo=0.0,
        afinidad_medio=medios(radio=0.45, digital=0.40, tv=0.25, punto_venta=0.20, influencers=0.10),
        afinidad_canal={"propio": 0.45, "marketplace": 0.45, "bodegas": 0.20, "retail": 0.15, "mayorista": 0.05},
    ),
]

C3 = [
    Competidor(
        id="alfa", nombre="Academia Alfa", politica="premium",
        decisiones=Decisiones(
            segmento_objetivo="postulante", beneficio_prometido="rendimiento", nivel_promesa=4.4,
            calidad=4.2, beneficio_real="rendimiento", amplitud=2, precio=205.0,
            canales=["propio", "marketplace"],
            medios=medios(digital=42000, influencers=16000, tv=14000),
        ),
        estado=EstadoMarca(awareness=aw0(S3, 0.45), reputacion=0.65, claridad=0.78),
    ),
    Competidor(
        id="exito", nombre="Exito Online", politica="retador",
        decisiones=Decisiones(
            segmento_objetivo="repitente", beneficio_prometido="precio", nivel_promesa=2.2,
            calidad=2.5, beneficio_real="precio", amplitud=3, precio=79.0,
            canales=["propio", "marketplace"],
            medios=medios(digital=20000, radio=12000),
        ),
        estado=EstadoMarca(awareness=aw0(S3, 0.28), reputacion=0.48, claridad=0.50),
    ),
]

M3 = Mercado(
    id="academia", nombre="Academia preuniversitaria en linea", categoria="Servicios educativos",
    segmentos=S3, costo_base=38.0, costo_fijo=160000.0, caja_inicial=550000.0,
    limite_sobregiro=300000.0, periodos=8, competidores_base=C3,
)

MERCADOS = {"bebida": M1, "mochilas": M2, "academia": M3}

# ----------------------------------------------------------------- eventos

M1.eventos = [
    Evento(periodo=2, titulo="Sube el precio del insumo importado",
           descripcion="El concentrado de fruta sube 12%. El costo unitario aumenta para todos.",
           factor_costo=1.12),
    Evento(periodo=3, titulo="VitalPlus contraataca",
           descripcion="VitalPlus baja su precio 8% y sube su inversion en medios 25%.",
           competidor="vital", cambio_precio=0.92, cambio_medios=1.25),
    Evento(periodo=5, titulo="Ola de consumo saludable",
           descripcion="El segmento Deportista urbano crece 15% por la tendencia de bienestar.",
           segmento="fitness", factor_tamano=1.15),
]

M2.eventos = [
    Evento(periodo=1, titulo="Campana escolar",
           descripcion="La demanda de Padres de colegio publico crece 25% por inicio de clases.",
           segmento="publico", factor_tamano=1.25),
    Evento(periodo=4, titulo="Kuma entra a guerra de precios",
           descripcion="Kuma baja su precio 10% y sube 30% su presencia en radio y television.",
           competidor="kuma", cambio_precio=0.90, cambio_medios=1.30),
    Evento(periodo=6, titulo="Alza del flete internacional",
           descripcion="El costo de importacion sube 10% y golpea el costo unitario.",
           factor_costo=1.10),
]

M3.eventos = [
    Evento(periodo=3, titulo="Academia Alfa lanza una ofensiva",
           descripcion="Alfa baja su precio 20%, sube su calidad y triplica su inversion "
                       "digital sobre el segmento de postulantes a tiempo completo.",
           competidor="alfa", cambio_precio=0.80, cambio_medios=3.00, cambio_calidad=0.3),
    Evento(periodo=5, titulo="Crece el estudio en paralelo al trabajo",
           descripcion="El segmento Trabajador que estudia crece 20%.",
           segmento="trabajador", factor_tamano=1.20),
    Evento(periodo=6, titulo="Sube el costo de la plataforma",
           descripcion="El proveedor de video en vivo sube su tarifa 8%.",
           factor_costo=1.08),
]
