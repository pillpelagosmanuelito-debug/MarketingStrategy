# Modelo de simulación

Este documento define el motor completo. Todo parámetro que aparece aquí existe
con el mismo valor en `lib/domain/engine/parametros.dart` y en
`tool/calibracion/motor.py`.

---

## 1. Estructura general de un periodo

```
1. Eventos del periodo          (costo de insumos, movimientos de competidores,
                                 cambios de tamaño de segmento)
2. El estudiante decide         (5 módulos)
3. Recuerdo de marca            (medios × afinidad × eficiencia, con boca a boca)
4. Cobertura                    (unión probabilística de canales)
5. Atractivo                    (promesa, claridad, reputación, variedad)
6. Utilidad y participación     (logit por segmento, con opción de no comprar)
7. Inercia                      (parte de la participación previa se sostiene)
8. Ventas e ingresos            (netos del margen de canal)
9. Satisfacción                 (entrega − expectativa, por segmento)
10. Estado de resultados        (costos, impuesto, caja)
11. Memoria de marca            (reputación, claridad, volumen acumulado)
12. Reacción de los competidores
```

---

## 2. Demanda: elección discreta por segmento

Cada segmento elige entre las marcas disponibles y la opción de no comprar.

**Atractivo de la marca *b* para el segmento *s*** (antes del precio):

```
calidadCreída = min(1, (promesa/5) · (0.45 + 0.55·claridad)
                       + (calidad/5) · (0.55·claridad))

V = pesoCalidad·calidadCreída
  + pesoBeneficio·similitud(beneficioPrometido, beneficioBuscado)
  + pesoMarca·(claridad · similitud(beneficioPrometido, beneficioBuscado))
  + pesoVariedad·(amplitud/3)

atractivo = max(0.01,  V · (1 + 1.30·(reputación − 0.5)))
```

Nótese que **el producto real no entra aquí**: la calidad influye solo a través
de la claridad (lo que el mercado ya conoce de la marca). Lo que atrae es lo
que se promete.

**Utilidad**, ya con el precio:

```
relativo = precio / precioReferencia(s)
u = 3.0 · atractivo − sensibilidad(s) · (relativo − 1)
si relativo < 0.72:  u −= sospechaPrecioBajo(s) · (0.72 − relativo) · 3.0
```

El último término es el efecto "demasiado barato para ser bueno": solo existe
en segmentos que asocian precio con calidad, y hace que bajar el precio pueda
reducir las ventas.

**Participación dentro del segmento** (logit con disponibilidad y recuerdo como
multiplicadores):

```
peso(b) = cobertura(s,b) · recuerdo(s,b) · e^u(b)
participación(b) = peso(b) / ( Σ peso(j) + e^0.95 )
```

El término `e^0.95` es la utilidad de **no comprar**. Sin él, el mercado
compraría el 100% de su tamaño sin importar lo malo que fuera lo ofrecido.

**Inercia**:

```
participación = (1 − 0.30·lealtad)·participación + 0.30·lealtad·participaciónPrevia
```

---

## 3. Recuerdo de marca

```
inversiónEfectiva = Σ_medio  monto · eficiencia(medio) · afinidad(s, medio) · penalización

penalización = 1                        si monto ≥ mínimo(medio)
             = 0.45 + 0.55·(monto/mínimo)  si monto < mínimo(medio)

ganancia = (0.92 − recuerdo) · inversiónEfectiva / (inversiónEfectiva + 55,000)
```

**Boca a boca**, según la satisfacción del periodo anterior:

```
si satisfacción < 0.45:  decaimiento = 0.15 + 0.55·(0.45 − satisfacción)
si satisfacción > 0.72:  ganancia   += (0.92 − recuerdo)·0.30·(satisfacción − 0.72)

recuerdo = clamp(0.02,  recuerdo·(1 − decaimiento) + ganancia,  0.92)
```

Tres propiedades intencionales:

1. El recuerdo **se deprecia 15% por periodo** aunque no se haga nada mal:
   sostenerlo cuesta todos los periodos.
2. **Se satura**: duplicar la inversión aumenta las unidades menos de 8%, y
   cuadruplicarla reduce la utilidad.
3. Con satisfacción baja, **más publicidad empeora el resultado**: se paga la
   campaña y el boca a boca negativo borra el recuerdo más rápido de lo que la
   campaña lo repone.

| Medio | Eficiencia | Mínimo útil |
|---|---|---|
| Televisión | 0.85 | S/ 40,000 |
| Radio | 1.05 | S/ 8,000 |
| Digital y redes | 1.20 | S/ 3,000 |
| Influencers | 1.10 | S/ 5,000 |
| Punto de venta | 0.95 | S/ 4,000 |

---

## 4. Distribución

La cobertura de varios canales **no se suma**: se combina como eventos
independientes.

```
cobertura(s) = min(0.95,  1 − Π_canal (1 − afinidadCanal(s, canal)))
margenCanal(s) = Σ afinidad·margen / Σ afinidad
```

| Canal | Costo fijo por periodo | Margen que retiene |
|---|---|---|
| Retail moderno | S/ 38,000 | 28% |
| Bodegas y tradicional | S/ 22,000 | 18% |
| Marketplace | S/ 9,000 | 20% |
| Canal propio | S/ 16,000 | 6% |
| Distribuidor mayorista | S/ 12,000 | 32% |

Estar en los cinco canales cuesta S/ 97,000 por periodo antes de vender una
sola unidad. Es la forma más común de perder plata en el simulador.

---

## 5. Satisfacción

```
entregado = 0.55·(calidad/5) + 0.45·similitud(beneficioReal, beneficioBuscado)

esperado  = 0.55·(promesa/5) + 0.45·similitud(beneficioPrometido, beneficioBuscado)
esperado ·= 1 + 0.15·(precio/precioReferencia − 1)
esperado ·= 0.94 + 0.03·(exigencia − 3)

satisfacción = clamp(0.03,  0.62 + 1.30·(entregado − esperado),  0.97)
```

El precio **sube la expectativa**: cobrar más y entregar lo mismo reduce la
satisfacción. Es lo que hace que "subir el precio" no sea nunca una decisión
gratuita.

**Reputación**, asimétrica a propósito:

```
velocidad = 0.42 si satisfacción < reputación   (cae rápido)
          = 0.22 en caso contrario              (sube lento)
reputación = clamp(0.05, reputación·(1−velocidad) + velocidad·satisfacción, 0.95)
```

---

## 6. Claridad del posicionamiento

La firma del posicionamiento es `segmento | beneficio prometido | nivel`.

```
si la firma cambió:  claridad ·= 0.55
si no:               claridad += (0.95 − claridad) · 0.30 · min(1, medios/60,000)
```

Sostener el mismo posicionamiento ocho periodos con inversión plena lleva la
claridad de 0.35 a ~0.91. Cambiarlo una vez devuelve casi la mitad del camino
recorrido. Es el costo de reposicionar, y explica el resultado del escenario de
la academia.

---

## 7. Costos y resultado

```
costoUnitario = costoBase · (0.55 + 0.18·calidad) · (1 + 0.05·(amplitud−1)) · experiencia
experiencia   = max(0.80,  0.965 ^ log₂(acumulado/1000))

ingreso  = Σ_s  unidades(s) · precio · (1 − margenCanal(s))
costos   = unidades·costoUnitario + costoFijo + canales + medios + investigación
utilidad = (ingreso − costos) − impuesto        impuesto = 29.5% si hay ganancia
caja     = caja + utilidad
quiebra  = caja < −límiteSobregiro
```

La curva de experiencia tiene **piso en 0.80**: el volumen abarata, pero no
indefinidamente.

---

## 8. Investigación de mercado

Ningún estudio devuelve el valor exacto.

```
valorEntregado = valorReal · (1 + ruido · error)
ruido ~ promedio de tres uniformes en [−1,1]  (aproximación a una normal)
error(repetición n) = errorBase / 2^(n−1)
```

El ruido es **determinista** por `(mercado, estudio, segmento, repetición)`:
dos estudiantes con la misma partida obtienen el mismo dato, de modo que el
aula compare decisiones y no suerte.

| Estudio | Costo | Error inicial | Qué entrega |
|---|---|---|---|
| Tamaño de mercado | S/ 12,000 | ±20% | Compradores potenciales por segmento |
| Perfil del segmento | S/ 18,000 | ±16% | Beneficio buscado, pesos de decisión, exigencia, lealtad |
| Prueba de precio | S/ 15,000 | ±14% | Precio de referencia, sensibilidad, desconfianza al precio bajo |
| Auditoría de canales | S/ 14,000 | ±18% | Dónde compra el segmento |
| Hábitos de medios | S/ 10,000 | ±18% | Qué medios consume |
| Mystery shopper | S/ 16,000 | ±12% | Precio, calidad, promesa, canales y presión de medios de cada rival |
| Marca y satisfacción | S/ 11,000 | ±15% | Recuerdo por segmento, reputación y claridad propias |

El beneficio buscado se identifica **sin error**: es una lectura cualitativa,
no una medición.

---

## 9. Competidores

Reaccionan al desempeño del estudiante, no siguen un guion:

| Política | Condición | Respuesta |
|---|---|---|
| Líder masivo | El estudiante supera 22% de participación | Baja precio 4% y sube medios 6%, con piso de precio en 1.35× el costo base |
| Premium | El estudiante supera 18% | Sube calidad 0.15 y refuerza digital |
| Retador | El estudiante cobra menos que él | Se alinea 3% por debajo, con piso en 1.25× el costo base |

Los eventos del mercado sí son deterministas por escenario: toda el aula
enfrenta lo mismo en el mismo periodo. Lo que cambia entre partidas es la
respuesta, no el escenario.

---

## 10. Calibración y verificación

El modelo se ajustó **antes de escribir Dart**, en un prototipo Python
(`tool/calibracion/motor.py`), corriendo políticas completas hasta que ninguna
estrategia dominara los tres mercados.

Luego se hizo lo que la experiencia del catálogo indica: **el código Dart
entregado se transcribió de vuelta a Python** (`tool/calibracion/port_dart.py`)
y se corrió la misma batería. Resultado de `comparar.py` sobre las 25 políticas
de los tres escenarios:

```
IDENTICOS   (diferencia máxima: 0.00 soles)
```

Esa comparación corre en CI en cada push. Si alguien toca un parámetro del
motor Dart sin actualizar la calibración, el trabajo falla.

Las pruebas de `test/calibracion_test.dart` verifican propiedades educativas,
no funciones:

- En cada mercado gana la estrategia que el escenario dice premiar.
- Ninguna estrategia gana en los tres.
- El producto promedio para todos nunca gana y queda al menos 20% por debajo.
- Prometer de más deja la satisfacción bajo 20% y cuesta más de la mitad de la
  utilidad.
- Vender bajo el costo lleva a la quiebra en los tres mercados.
- Duplicar los medios no duplica las ventas; cuadruplicarlos reduce la utilidad.
- La caja de cierre es siempre la caja previa más la utilidad.

---

## 11. Por qué el analista es un sistema experto y no un modelo generativo

| Criterio | 30 reglas + proyección | Modelo de lenguaje |
|---|---|---|
| Exactitud | Corre el mismo motor sobre el mercado **estimado por el estudiante** | Aproximada, puede inventar cifras |
| Trazabilidad | Cada consejo cita regla, fundamento y evidencia | Difusa |
| Honestidad | **Estructuralmente incapaz de filtrar datos ocultos**: recibe `MercadoEstimado`, no el mercado real | Depende del prompt |
| Sin conexión | Sí | No |
| Costo por estudiante | Cero | Por consulta |
| Redacción | Buena (plantillas con datos reales) | Superior |

La propiedad crítica es la tercera. El analista no recibe el mercado: recibe un
`MercadoEstimado` construido únicamente con los estudios que el estudiante pagó,
y con supuestos neutrales declarados donde falta evidencia. No puede filtrar un
parámetro oculto **porque no lo tiene en la mano**. Eso está verificado en
`test/analista_test.dart`, que además revisa que ningún texto generado contenga
los valores reales del mercado.

La proyección responde a "¿qué pasaría si mis estimaciones fueran correctas?",
no a "¿qué va a pasar?". Con pocos estudios, la proyección se equivoca — y eso
también enseña.

**Dónde sí aportaría un modelo generativo** (evolución, no MVP): redactar el
briefing de escenarios nuevos, interpretar preguntas abiertas del estudiante
sobre su propio tablero, y actuar como gerente general en una negociación de
presupuesto. En los tres casos las reglas siguen siendo la fuente de verdad y
el modelo solo redacta.

---

## 12. Limitaciones declaradas

Un modelo que oculta sus supuestos es propaganda. Estas son las suyas:

1. **Los segmentos no se solapan.** Una persona pertenece a uno solo. En la
   realidad los segmentos se cruzan y compiten por el mismo comprador.
2. **La creatividad no existe.** Dos campañas con el mismo monto en el mismo
   medio rinden igual. Es una simplificación fuerte: en la práctica la
   diferencia entre una buena y una mala pieza es de varias veces.
3. **El canal no negocia.** Los márgenes son fijos; no hay descuentos por
   volumen ni conflicto de canal.
4. **La competencia no investiga.** Los rivales reaccionan a participación y
   precio, no a la estrategia del estudiante.
5. **No hay inventario ni capacidad.** Todo lo demandado se produce y se
   entrega. La restricción del simulador es comercial, no operativa; para eso
   está la aplicación #30 del catálogo.
6. **La satisfacción es un solo número por segmento.** En la práctica hay
   satisfacción con el producto, con el precio, con el canal y con el servicio,
   y se comportan distinto.
7. **Los montos están en soles con valores plausibles, no auditados.** Sirven
   para razonar sobre órdenes de magnitud y estructura de costos, no para
   cotizar un lanzamiento real.
8. **El error de muestreo no modela sesgo.** Un estudio real puede estar
   sistemáticamente equivocado; aquí el error es siempre centrado.
